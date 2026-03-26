import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalStoryAssetStore {
  const LocalStoryAssetStore({Directory? rootDirectory})
    : _rootDirectoryOverride = rootDirectory;

  final Directory? _rootDirectoryOverride;

  Future<String?> persistCoverImage(
    String? sourcePath, {
    required int storyId,
    String? previousLocalPath,
  }) async {
    final incomingPath = _sanitizePath(sourcePath);
    final previousPath = _sanitizePath(previousLocalPath);

    if (incomingPath == null) {
      await _deleteIfManaged(previousPath);
      await _deleteStoryDirectoryIfEmpty(storyId);
      return null;
    }

    if (await isManagedPath(incomingPath)) {
      if (previousPath != null && !_samePath(previousPath, incomingPath)) {
        await _deleteIfManaged(previousPath);
      }
      return incomingPath;
    }

    final sourceFile = File(incomingPath);
    if (!await sourceFile.exists()) {
      return previousPath;
    }

    final storyDirectory = await _ensureStoryDirectory(storyId);
    final extension = _extensionOf(incomingPath);
    final targetPath =
        '${storyDirectory.path}/cover_${DateTime.now().microsecondsSinceEpoch}$extension';
    final copied = await sourceFile.copy(targetPath);

    if (previousPath != null && !_samePath(previousPath, copied.path)) {
      await _deleteIfManaged(previousPath);
    }

    return copied.path;
  }

  Future<void> deleteStoryData({
    required int storyId,
    String? coverImagePath,
    Iterable<String> photoPaths = const [],
  }) async {
    await deleteManagedFiles([coverImagePath, ...photoPaths]);

    final storyDirectory = Directory(
      '${(await _ensureRootDirectory()).path}/story_$storyId',
    );
    if (await storyDirectory.exists()) {
      await storyDirectory.delete(recursive: true);
    }
  }

  Future<void> deleteManagedFiles(Iterable<String?> paths) async {
    for (final path in paths) {
      await _deleteIfManaged(path);
    }
  }

  Future<bool> isManagedPath(String? path) async {
    final sanitized = _sanitizePath(path);
    if (sanitized == null) {
      return false;
    }

    final root = await _ensureRootDirectory();
    final normalizedRoot = _normalizePath(root.path);
    final normalizedPath = _normalizePath(sanitized);

    return normalizedPath == normalizedRoot ||
        normalizedPath.startsWith('$normalizedRoot/');
  }

  Future<Directory> resolveRootDirectory() async {
    return _ensureRootDirectory();
  }

  Future<Directory> _ensureRootDirectory() async {
    final root =
        _rootDirectoryOverride ??
        Directory(
          '${(await getApplicationDocumentsDirectory()).path}/memoryflow_local_data',
        );

    if (!await root.exists()) {
      await root.create(recursive: true);
    }

    return root;
  }

  Future<Directory> _ensureStoryDirectory(int storyId) async {
    final directory = Directory(
      '${(await _ensureRootDirectory()).path}/story_$storyId',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<void> _deleteIfManaged(String? path) async {
    if (!await isManagedPath(path)) {
      return;
    }

    final file = File(path!);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> _deleteStoryDirectoryIfEmpty(int storyId) async {
    final directory = Directory(
      '${(await _ensureRootDirectory()).path}/story_$storyId',
    );

    if (!await directory.exists()) {
      return;
    }

    final entities = directory.listSync();
    if (entities.isEmpty) {
      await directory.delete();
    }
  }

  String? _sanitizePath(String? path) {
    final trimmed = path?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String _extensionOf(String path) {
    final slashIndex = path.lastIndexOf(RegExp(r'[\\/]'));
    final fileName = slashIndex >= 0 ? path.substring(slashIndex + 1) : path;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0) {
      return '';
    }
    return fileName.substring(dotIndex);
  }

  String _normalizePath(String path) {
    return path.replaceAll('\\', '/').toLowerCase();
  }

  bool _samePath(String left, String right) {
    return _normalizePath(left) == _normalizePath(right);
  }
}
