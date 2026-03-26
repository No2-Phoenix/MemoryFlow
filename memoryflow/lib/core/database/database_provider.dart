import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'isar_service.dart';
import '../storage/local_story_asset_store.dart';
import '../storage/user_data_transfer_service.dart';

/// Isar 鏈嶅姟 Provider
final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});

final localStoryAssetStoreProvider = Provider<LocalStoryAssetStore>((ref) {
  return const LocalStoryAssetStore();
});

final userDataTransferServiceProvider = Provider<UserDataTransferService>((
  ref,
) {
  return UserDataTransferService(
    isarService: ref.read(isarServiceProvider),
    assetStore: ref.read(localStoryAssetStoreProvider),
  );
});

/// 鍒濆鍖栨暟鎹簱 Provider
final isarInitProvider = FutureProvider<void>((ref) async {
  final isarService = ref.read(isarServiceProvider);
  await isarService.initialize();
});
