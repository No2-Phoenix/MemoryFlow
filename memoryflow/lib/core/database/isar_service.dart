import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'models/story.dart';

class IsarService {
  IsarService._internal();

  static final IsarService _instance = IsarService._internal();

  factory IsarService() => _instance;

  String? _dbPath;
  Directory Function()? _documentsDirectoryResolver;
  final List<Story> _stories = [];
  final List<Photo> _photos = [];
  int _nextStoryId = 1;
  int _nextPhotoId = 1;

  Future<void> initialize() async {
    if (_dbPath != null) {
      return;
    }

    final directory = await _resolveDocumentsDirectory();
    _dbPath = '${directory.path}/memoryflow_db.json';

    await _loadDatabase();
    debugPrint('MemoryFlow local database ready: $_dbPath');
  }

  Future<void> _loadDatabase() async {
    try {
      final file = File(_dbPath!);
      if (!await file.exists()) {
        return;
      }

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      _stories
        ..clear()
        ..addAll(
          ((data['stories'] as List<dynamic>?) ?? const [])
              .map((storyJson) => Story.fromJson(storyJson as Map<String, dynamic>)),
        );

      _photos
        ..clear()
        ..addAll(
          ((data['photos'] as List<dynamic>?) ?? const [])
              .map((photoJson) => Photo.fromJson(photoJson as Map<String, dynamic>)),
        );

      final maxStoryId = _stories.isEmpty
          ? 0
          : _stories
              .map((story) => story.id)
              .reduce((left, right) => left > right ? left : right);
      final maxPhotoId = _photos.isEmpty
          ? 0
          : _photos
              .map((photo) => photo.id)
              .reduce((left, right) => left > right ? left : right);

      _nextStoryId = (data['nextStoryId'] as int? ?? 1) > maxStoryId
          ? (data['nextStoryId'] as int? ?? 1)
          : maxStoryId + 1;
      _nextPhotoId = (data['nextPhotoId'] as int? ?? 1) > maxPhotoId
          ? (data['nextPhotoId'] as int? ?? 1)
          : maxPhotoId + 1;
    } catch (error) {
      debugPrint('Failed to load MemoryFlow local database: $error');
    }
  }

  Future<void> _saveDatabase() async {
    try {
      final file = File(_dbPath!);
      await file.writeAsString(jsonEncode(exportSnapshot()));
    } catch (error) {
      debugPrint('Failed to save MemoryFlow local database: $error');
    }
  }

  Map<String, dynamic> exportSnapshot() {
    return {
      'stories': _stories.map((story) => story.toJson()).toList(),
      'photos': _photos.map((photo) => photo.toJson()).toList(),
      'nextStoryId': _nextStoryId,
      'nextPhotoId': _nextPhotoId,
    };
  }

  Future<void> importSnapshot(Map<String, dynamic> snapshot) async {
    if (_dbPath == null) {
      await initialize();
    }

    final rawStories = snapshot['stories'];
    final rawPhotos = snapshot['photos'];

    if (rawStories is! List<dynamic> || rawPhotos is! List<dynamic>) {
      throw const FormatException('Invalid database payload: stories/photos');
    }

    final stories = rawStories
        .map(
          (item) => Story.fromJson(
            (item as Map<Object?, Object?>).cast<String, dynamic>(),
          ),
        )
        .toList();

    final photos = rawPhotos
        .map(
          (item) => Photo.fromJson(
            (item as Map<Object?, Object?>).cast<String, dynamic>(),
          ),
        )
        .toList();

    final maxStoryId = stories.isEmpty
        ? 0
        : stories
              .map((story) => story.id)
              .reduce((left, right) => left > right ? left : right);
    final maxPhotoId = photos.isEmpty
        ? 0
        : photos
              .map((photo) => photo.id)
              .reduce((left, right) => left > right ? left : right);

    final snapshotNextStoryId = snapshot['nextStoryId'] is int
        ? snapshot['nextStoryId'] as int
        : 1;
    final snapshotNextPhotoId = snapshot['nextPhotoId'] is int
        ? snapshot['nextPhotoId'] as int
        : 1;

    _stories
      ..clear()
      ..addAll(stories);
    _photos
      ..clear()
      ..addAll(photos);
    _nextStoryId = snapshotNextStoryId > maxStoryId
        ? snapshotNextStoryId
        : maxStoryId + 1;
    _nextPhotoId = snapshotNextPhotoId > maxPhotoId
        ? snapshotNextPhotoId
        : maxPhotoId + 1;

    await _saveDatabase();
  }

  Future<List<Story>> getAllStories() async => List.unmodifiable(_stories);

  Future<Story?> getStoryById(int id) async {
    try {
      return _stories.firstWhere((story) => story.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveStory(Story story) async {
    if (story.id == 0) {
      story.id = _nextStoryId++;
    } else if (story.id >= _nextStoryId) {
      _nextStoryId = story.id + 1;
    }

    story.updatedAt = DateTime.now();

    final index = _stories.indexWhere((item) => item.id == story.id);
    if (index >= 0) {
      _stories[index] = story;
    } else {
      _stories.add(story);
    }

    await _saveDatabase();
  }

  Future<void> deleteStory(int id) async {
    _stories.removeWhere((story) => story.id == id);
    _photos.removeWhere((photo) => photo.storyId == id);
    await _saveDatabase();
  }

  Future<List<Photo>> getAllPhotos() async => List.unmodifiable(_photos);

  Future<Photo?> getPhotoById(int id) async {
    try {
      return _photos.firstWhere((photo) => photo.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePhoto(Photo photo) async {
    if (photo.id == 0) {
      photo.id = _nextPhotoId++;
    } else if (photo.id >= _nextPhotoId) {
      _nextPhotoId = photo.id + 1;
    }

    final index = _photos.indexWhere((item) => item.id == photo.id);
    if (index >= 0) {
      _photos[index] = photo;
    } else {
      _photos.add(photo);
    }

    await _saveDatabase();
  }

  Future<void> deletePhoto(int id) async {
    _photos.removeWhere((photo) => photo.id == id);
    await _saveDatabase();
  }

  Future<List<Photo>> getPhotosByStoryId(int storyId) async {
    return _photos.where((photo) => photo.storyId == storyId).toList();
  }

  Future<void> close() async {
    await _saveDatabase();
    _dbPath = null;
    _stories.clear();
    _photos.clear();
  }

  @visibleForTesting
  void setDocumentsDirectoryResolver(Directory Function()? resolver) {
    _documentsDirectoryResolver = resolver;
  }

  Future<Directory> _resolveDocumentsDirectory() async {
    final resolver = _documentsDirectoryResolver;
    if (resolver != null) {
      return resolver();
    }
    return getApplicationDocumentsDirectory();
  }
}
