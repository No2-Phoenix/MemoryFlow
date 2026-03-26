import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memoryflow/core/storage/local_story_asset_store.dart';

void main() {
  group('LocalStoryAssetStore', () {
    late Directory sandbox;
    late Directory managedRoot;
    late LocalStoryAssetStore store;

    setUp(() async {
      sandbox = await Directory.systemTemp.createTemp('memoryflow_local_store');
      managedRoot = Directory('${sandbox.path}/managed');
      store = LocalStoryAssetStore(rootDirectory: managedRoot);
    });

    tearDown(() async {
      if (await sandbox.exists()) {
        await sandbox.delete(recursive: true);
      }
    });

    test('copies imported cover image into managed local storage', () async {
      final sourceFile = File('${sandbox.path}/source.jpg');
      await sourceFile.writeAsBytes(List<int>.generate(32, (index) => index));

      final persistedPath = await store.persistCoverImage(
        sourceFile.path,
        storyId: 42,
      );

      expect(persistedPath, isNotNull);
      expect(await File(persistedPath!).exists(), isTrue);
      expect(await sourceFile.exists(), isTrue);
      expect(await store.isManagedPath(persistedPath), isTrue);
    });

    test(
      'deleting a story clears the managed local copy but keeps source file',
      () async {
        final sourceFile = File('${sandbox.path}/source.jpg');
        await sourceFile.writeAsBytes(List<int>.filled(16, 7));

        final persistedPath = await store.persistCoverImage(
          sourceFile.path,
          storyId: 7,
        );

        await store.deleteStoryData(storyId: 7, coverImagePath: persistedPath);

        expect(await File(persistedPath!).exists(), isFalse);
        expect(await sourceFile.exists(), isTrue);
      },
    );
  });
}
