import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memoryflow/core/database/isar_service.dart';
import 'package:memoryflow/core/database/models/story.dart';
import 'package:memoryflow/core/storage/local_story_asset_store.dart';
import 'package:memoryflow/core/storage/user_data_transfer_service.dart';

void main() {
  group('UserDataTransferService', () {
    late Directory sandbox;

    setUp(() async {
      sandbox = await Directory.systemTemp.createTemp(
        'memoryflow_transfer_service',
      );
    });

    tearDown(() async {
      final isar = IsarService();
      await isar.close();
      if (await sandbox.exists()) {
        await sandbox.delete(recursive: true);
      }
    });

    test('exports and imports stories with managed local assets', () async {
      final isar = IsarService();

      final sourceDbDirectory = Directory('${sandbox.path}/source_db')
        ..createSync(recursive: true);
      isar.setDocumentsDirectoryResolver(() => sourceDbDirectory);
      await isar.initialize();

      final sourceManagedRoot = Directory('${sandbox.path}/source_assets');
      final sourceStore = LocalStoryAssetStore(
        rootDirectory: sourceManagedRoot,
      );
      final sourceImage = File('${sandbox.path}/cover_source.jpg');
      await sourceImage.writeAsBytes(List<int>.generate(128, (index) => index));

      final managedCoverPath = await sourceStore.persistCoverImage(
        sourceImage.path,
        storyId: 42,
      );

      await isar.saveStory(
        Story(
          id: 42,
          title: 'Transfer Story',
          dateLabel: '2026.03.25',
          location: 'Shanghai',
          caption: 'For migration',
          ambientMusicPath: 'Rain',
          lines: const ['line-1'],
          palette: const [0xFF112233],
          coverImagePath: managedCoverPath,
          showDate: false,
          showLocation: true,
          showAmbient: false,
          isUserCreated: true,
        ),
      );

      final exportDir = Directory('${sandbox.path}/exports')
        ..createSync(recursive: true);
      final exporter = UserDataTransferService(
        isarService: isar,
        assetStore: sourceStore,
        temporaryDirectoryResolver: () async => exportDir,
      );

      final backupFile = await exporter.exportToFile();
      expect(await backupFile.exists(), isTrue);

      final payload =
          jsonDecode(await backupFile.readAsString()) as Map<String, dynamic>;
      expect(payload['format'], 'memoryflow.user_data_transfer');
      expect((payload['managedAssets'] as List<dynamic>).isNotEmpty, isTrue);

      await isar.close();

      final targetDbDirectory = Directory('${sandbox.path}/target_db')
        ..createSync(recursive: true);
      isar.setDocumentsDirectoryResolver(() => targetDbDirectory);
      final targetManagedRoot = Directory('${sandbox.path}/target_assets');
      final importerStore = LocalStoryAssetStore(
        rootDirectory: targetManagedRoot,
      );
      final importer = UserDataTransferService(
        isarService: isar,
        assetStore: importerStore,
        temporaryDirectoryResolver: () async => exportDir,
      );

      final result = await importer.importFromFile(backupFile.path);
      expect(result.storyCount, 1);
      expect(result.assetCount, 1);

      final importedStories = await isar.getAllStories();
      expect(importedStories, hasLength(1));

      final importedStory = importedStories.first;
      expect(importedStory.title, 'Transfer Story');
      expect(importedStory.showDate, isFalse);
      expect(importedStory.showAmbient, isFalse);
      expect(importedStory.coverImagePath, isNotNull);
      expect(await File(importedStory.coverImagePath!).exists(), isTrue);
      expect(
        await importerStore.isManagedPath(importedStory.coverImagePath),
        isTrue,
      );
    });
  });
}
