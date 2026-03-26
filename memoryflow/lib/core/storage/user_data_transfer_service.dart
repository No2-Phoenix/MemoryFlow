import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../database/isar_service.dart';
import 'local_story_asset_store.dart';

class UserDataImportResult {
  const UserDataImportResult({
    required this.storyCount,
    required this.assetCount,
  });

  final int storyCount;
  final int assetCount;
}

class UserDataTransferService {
  UserDataTransferService({
    required IsarService isarService,
    required LocalStoryAssetStore assetStore,
    Future<Directory> Function()? temporaryDirectoryResolver,
  }) : _isarService = isarService,
       _assetStore = assetStore,
       _temporaryDirectoryResolver = temporaryDirectoryResolver;

  static const String _format = 'memoryflow.user_data_transfer';
  static const int _schemaVersion = 1;

  final IsarService _isarService;
  final LocalStoryAssetStore _assetStore;
  final Future<Directory> Function()? _temporaryDirectoryResolver;

  Future<File> exportToFile() async {
    await _isarService.initialize();
    final snapshot = _isarService.exportSnapshot();
    final rootDirectory = await _assetStore.resolveRootDirectory();
    final managedAssets = await _collectManagedAssets(
      snapshot: snapshot,
      rootDirectory: rootDirectory,
    );

    final payload = <String, dynamic>{
      'format': _format,
      'schemaVersion': _schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'database': snapshot,
      'managedAssets': managedAssets,
    };

    final temporaryDirectory = await _resolveTemporaryDirectory();
    if (!await temporaryDirectory.exists()) {
      await temporaryDirectory.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${temporaryDirectory.path}${Platform.pathSeparator}memoryflow_backup_$timestamp.mfdata.json',
    );
    await file.writeAsString(jsonEncode(payload));
    return file;
  }

  Future<UserDataImportResult> importFromFile(String filePath) async {
    await _isarService.initialize();
    final incoming = File(filePath);
    if (!await incoming.exists()) {
      throw const FileSystemException('Import file does not exist');
    }

    final raw = jsonDecode(await incoming.readAsString());
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Invalid import payload');
    }

    final format = raw['format'];
    if (format != _format) {
      throw const FormatException('Unsupported transfer format');
    }

    final schemaVersion = raw['schemaVersion'];
    if (schemaVersion is! int || schemaVersion > _schemaVersion) {
      throw const FormatException('Unsupported transfer schema version');
    }

    final database = raw['database'];
    if (database is! Map<String, dynamic>) {
      throw const FormatException('Invalid database payload');
    }

    final managedAssetsRaw = raw['managedAssets'];
    if (managedAssetsRaw is! List<dynamic>) {
      throw const FormatException('Invalid managed asset payload');
    }

    final rootDirectory = await _assetStore.resolveRootDirectory();
    if (await rootDirectory.exists()) {
      await rootDirectory.delete(recursive: true);
    }
    await rootDirectory.create(recursive: true);

    final importedAssetPaths = <String, String>{};
    var importedAssetCount = 0;
    for (final item in managedAssetsRaw) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final relativePath = item['relativePath'] as String?;
      final originalPath = item['originalPath'] as String?;
      final encodedBytes = item['bytesBase64'] as String?;
      if (relativePath == null || encodedBytes == null) {
        continue;
      }

      final normalizedRelativePath = relativePath.replaceAll('\\', '/').trim();
      if (normalizedRelativePath.isEmpty ||
          normalizedRelativePath.startsWith('/') ||
          normalizedRelativePath.contains('..')) {
        continue;
      }

      final destinationPath = _joinWithRelativePath(
        rootDirectory.path,
        normalizedRelativePath,
      );
      final destinationFile = File(destinationPath);
      await destinationFile.parent.create(recursive: true);
      await destinationFile.writeAsBytes(base64Decode(encodedBytes));

      importedAssetCount += 1;
      if (originalPath != null && originalPath.trim().isNotEmpty) {
        importedAssetPaths[_normalizePath(originalPath)] = destinationPath;
      }
    }

    final migratedDatabase = _rewriteSnapshotPaths(
      snapshot: database,
      importedAssetPaths: importedAssetPaths,
    );
    await _isarService.importSnapshot(migratedDatabase);

    final stories = migratedDatabase['stories'] as List<dynamic>? ?? const [];
    return UserDataImportResult(
      storyCount: stories.length,
      assetCount: importedAssetCount,
    );
  }

  Future<List<Map<String, String>>> _collectManagedAssets({
    required Map<String, dynamic> snapshot,
    required Directory rootDirectory,
  }) async {
    final managedPaths = <String>{};

    final stories = snapshot['stories'] as List<dynamic>? ?? const [];
    for (final item in stories) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final coverImagePath = item['coverImagePath'] as String?;
      if (coverImagePath != null && coverImagePath.trim().isNotEmpty) {
        managedPaths.add(coverImagePath);
      }
    }

    final photos = snapshot['photos'] as List<dynamic>? ?? const [];
    for (final item in photos) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final localPath = item['localPath'] as String?;
      if (localPath != null && localPath.trim().isNotEmpty) {
        managedPaths.add(localPath);
      }
    }

    final assets = <Map<String, String>>[];
    for (final absolutePath in managedPaths) {
      if (!await _assetStore.isManagedPath(absolutePath)) {
        continue;
      }

      final file = File(absolutePath);
      if (!await file.exists()) {
        continue;
      }

      final relativePath = _relativeManagedPath(
        absolutePath: absolutePath,
        rootPath: rootDirectory.path,
      );
      if (relativePath == null) {
        continue;
      }

      final bytes = await file.readAsBytes();
      assets.add({
        'originalPath': absolutePath,
        'relativePath': relativePath,
        'bytesBase64': base64Encode(bytes),
      });
    }

    return assets;
  }

  Map<String, dynamic> _rewriteSnapshotPaths({
    required Map<String, dynamic> snapshot,
    required Map<String, String> importedAssetPaths,
  }) {
    final stories = (snapshot['stories'] as List<dynamic>? ?? const [])
        .map<Map<String, dynamic>>((item) {
          final map = (item as Map).cast<String, dynamic>();
          final coverImagePath = map['coverImagePath'] as String?;
          if (coverImagePath != null) {
            final mapped = importedAssetPaths[_normalizePath(coverImagePath)];
            if (mapped != null) {
              map['coverImagePath'] = mapped;
            }
          }
          return map;
        })
        .toList();

    final photos = (snapshot['photos'] as List<dynamic>? ?? const [])
        .map<Map<String, dynamic>>((item) {
          final map = (item as Map).cast<String, dynamic>();
          final localPath = map['localPath'] as String?;
          if (localPath != null) {
            final mapped = importedAssetPaths[_normalizePath(localPath)];
            if (mapped != null) {
              map['localPath'] = mapped;
            }
          }
          return map;
        })
        .toList();

    return <String, dynamic>{...snapshot, 'stories': stories, 'photos': photos};
  }

  Future<Directory> _resolveTemporaryDirectory() async {
    final resolver = _temporaryDirectoryResolver;
    if (resolver != null) {
      return resolver();
    }
    return getTemporaryDirectory();
  }

  String? _relativeManagedPath({
    required String absolutePath,
    required String rootPath,
  }) {
    final normalizedAbsolute = _normalizePath(absolutePath);
    final normalizedRoot = _normalizePath(rootPath);
    if (!normalizedAbsolute.startsWith('$normalizedRoot/')) {
      return null;
    }
    return normalizedAbsolute.substring(normalizedRoot.length + 1);
  }

  String _joinWithRelativePath(String rootPath, String relativePath) {
    final root = rootPath.endsWith(Platform.pathSeparator)
        ? rootPath.substring(0, rootPath.length - 1)
        : rootPath;
    final relative = relativePath.replaceAll('/', Platform.pathSeparator);
    return '$root${Platform.pathSeparator}$relative';
  }

  String _normalizePath(String value) {
    return value.replaceAll('\\', '/').toLowerCase();
  }
}
