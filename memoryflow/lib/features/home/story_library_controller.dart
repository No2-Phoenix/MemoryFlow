import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import '../../core/database/models/story.dart';
import 'experience_models.dart';
import 'story_moment_data.dart';

class StoryDraftInput {
  const StoryDraftInput({
    required this.title,
    required this.dateLabel,
    required this.location,
    required this.caption,
    required this.ambientLabel,
    required this.textMode,
    required this.lines,
    required this.palette,
    required this.showDate,
    required this.showLocation,
    required this.showAmbient,
    this.latitude,
    this.longitude,
    this.coverImagePath,
    this.coverBlurSigma = 2.0,
    this.cameraModel,
  });

  final String title;
  final String dateLabel;
  final String location;
  final String caption;
  final String ambientLabel;
  final StoryTextMode textMode;
  final List<String> lines;
  final List<Color> palette;
  final bool showDate;
  final bool showLocation;
  final bool showAmbient;
  final double? latitude;
  final double? longitude;
  final String? coverImagePath;
  final double coverBlurSigma;
  final String? cameraModel;
}

class StoryLibraryController extends Notifier<List<StoryMoment>> {
  bool _initialized = false;

  @override
  List<StoryMoment> build() {
    if (!_initialized) {
      _initialized = true;
      Future.microtask(_initialize);
    }
    return const <StoryMoment>[];
  }

  Future<void> _initialize() async {
    final service = ref.read(isarServiceProvider);
    await service.initialize();

    await reload();
  }

  Future<void> reload() async {
    final service = ref.read(isarServiceProvider);
    final storedStories = await service.getAllStories();
    final moments = storedStories.map(_momentFromStoryEntity).toList()
      ..sort(
        (left, right) =>
            _parseMomentDate(right).compareTo(_parseMomentDate(left)),
      );

    state = moments;
  }

  Future<StoryMoment> saveDraft(StoryDraftInput input, {int? storyId}) async {
    final service = ref.read(isarServiceProvider);
    final assetStore = ref.read(localStoryAssetStoreProvider);
    await service.initialize();

    final existing = storyId == null
        ? null
        : await service.getStoryById(storyId);

    final story = Story(
      id: existing?.id ?? 0,
      title: input.title,
      subtitle: existing?.subtitle,
      dateLabel: input.dateLabel,
      location: input.location,
      caption: input.caption,
      ambientMusicPath: input.ambientLabel,
      dominantColor: input.palette.length > 1
          ? input.palette[1].toARGB32()
          : null,
      latitude: input.latitude,
      longitude: input.longitude,
      lines: input.lines,
      palette: input.palette.map((color) => color.toARGB32()).toList(),
      coverImagePath: existing?.coverImagePath,
      coverBlurSigma: input.coverBlurSigma,
      cameraModel: input.cameraModel,
      textMode: input.textMode.name,
      showDate: input.showDate,
      showLocation: input.showLocation,
      showAmbient: input.showAmbient,
      isUserCreated: true,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      photos: existing?.photos ?? const [],
    );

    await service.saveStory(story);

    final localCoverImagePath = await assetStore.persistCoverImage(
      input.coverImagePath,
      storyId: story.id,
      previousLocalPath: existing?.coverImagePath,
    );

    if (story.coverImagePath != localCoverImagePath) {
      story.coverImagePath = localCoverImagePath;
      await service.saveStory(story);
    }

    await reload();
    return state.firstWhere((moment) => moment.id == story.id);
  }

  Future<void> deleteStory(int storyId) async {
    final service = ref.read(isarServiceProvider);
    final assetStore = ref.read(localStoryAssetStoreProvider);
    await service.initialize();

    final story = await service.getStoryById(storyId);
    final photos = await service.getPhotosByStoryId(storyId);

    await service.deleteStory(storyId);
    await assetStore.deleteStoryData(
      storyId: storyId,
      coverImagePath: story?.coverImagePath,
      photoPaths: photos.map((photo) => photo.localPath),
    );
    await reload();
  }

  Future<void> clearAllUserData() async {
    final service = ref.read(isarServiceProvider);
    final assetStore = ref.read(localStoryAssetStoreProvider);
    await service.initialize();

    final stories = await service.getAllStories();
    final userStories = stories.where((story) => story.isUserCreated).toList();

    for (final story in userStories) {
      final photos = await service.getPhotosByStoryId(story.id);
      await service.deleteStory(story.id);
      await assetStore.deleteStoryData(
        storyId: story.id,
        coverImagePath: story.coverImagePath,
        photoPaths: photos.map((photo) => photo.localPath),
      );
    }

    await reload();
  }

  StoryMoment _momentFromStoryEntity(Story story) {
    final palette = story.palette.isNotEmpty
        ? story.palette.map(Color.new).toList()
        : StoryMomentFallback.empty.palette;

    return StoryMoment(
      id: story.id,
      title: story.title,
      dateLabel: story.dateLabel ?? _formatDate(story.createdAt),
      location: story.location ?? '',
      caption: story.caption ?? '',
      ambientLabel: story.ambientMusicPath ?? '自动匹配',
      latitude: story.latitude ?? 0,
      longitude: story.longitude ?? 0,
      palette: palette,
      lines: story.lines.isNotEmpty ? story.lines : const [''],
      textMode: _parseStoryTextMode(story.textMode),
      coverImagePath: story.coverImagePath,
      coverBlurSigma: story.coverBlurSigma,
      cameraModel: story.cameraModel,
      showDate: story.showDate,
      showLocation: story.showLocation,
      showAmbient: story.showAmbient,
      isUserCreated: story.isUserCreated,
    );
  }

  String _formatDate(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}.$month.$day';
  }

  DateTime _parseMomentDate(StoryMoment moment) {
    final parts = moment.dateLabel.split('.');
    if (parts.length == 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(moment.id);
  }

  StoryTextMode _parseStoryTextMode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return StoryTextMode.lyrics;
    }
    try {
      return StoryTextMode.values.byName(raw.trim());
    } catch (_) {
      return StoryTextMode.lyrics;
    }
  }
}

final storyLibraryProvider =
    NotifierProvider<StoryLibraryController, List<StoryMoment>>(
      StoryLibraryController.new,
    );

final storiesProvider = Provider<List<StoryMoment>>(
  (ref) => ref.watch(storyLibraryProvider),
);
