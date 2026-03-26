import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoryflow/features/extensions/local_exif_map_utils.dart';
import 'package:memoryflow/features/home/story_moment_data.dart';

void main() {
  group('local EXIF map utils', () {
    test(
      'only stories with local cover copies and coordinates are included',
      () {
        final stories = [
          _story(
            id: 1,
            dateLabel: '2026.03.20',
            latitude: 31.2304,
            longitude: 121.4737,
            coverImagePath: '/managed/1.jpg',
          ),
          _story(
            id: 2,
            dateLabel: '2026.03.19',
            latitude: 0,
            longitude: 0,
            coverImagePath: '/managed/2.jpg',
          ),
          _story(
            id: 3,
            dateLabel: '2026.03.18',
            latitude: 30.2741,
            longitude: 120.1551,
            coverImagePath: null,
          ),
        ];

        final filtered = filterLocalExifStories(
          stories,
          dateFilter: MapDateFilter.all,
          now: DateTime(2026, 3, 24),
        );

        expect(filtered.map((story) => story.id), [1]);
      },
    );

    test('date filters are applied relative to the provided now value', () {
      final stories = [
        _story(
          id: 1,
          dateLabel: '2026.03.20',
          latitude: 31.2304,
          longitude: 121.4737,
          coverImagePath: '/managed/1.jpg',
        ),
        _story(
          id: 2,
          dateLabel: '2026.01.10',
          latitude: 30.2741,
          longitude: 120.1551,
          coverImagePath: '/managed/2.jpg',
        ),
        _story(
          id: 3,
          dateLabel: '2025.12.28',
          latitude: 29.5630,
          longitude: 106.5516,
          coverImagePath: '/managed/3.jpg',
        ),
      ];

      final last30Days = filterLocalExifStories(
        stories,
        dateFilter: MapDateFilter.last30Days,
        now: DateTime(2026, 3, 24),
      );
      final thisYear = filterLocalExifStories(
        stories,
        dateFilter: MapDateFilter.thisYear,
        now: DateTime(2026, 3, 24),
      );

      expect(last30Days.map((story) => story.id), [1]);
      expect(thisYear.map((story) => story.id), [1, 2]);
    });

    test('nearby coordinates cluster together', () {
      final stories = [
        _story(
          id: 1,
          dateLabel: '2026.03.20',
          latitude: 31.20,
          longitude: 121.47,
          location: '上海',
          coverImagePath: '/managed/1.jpg',
        ),
        _story(
          id: 2,
          dateLabel: '2026.03.19',
          latitude: 31.24,
          longitude: 121.52,
          location: '上海',
          coverImagePath: '/managed/2.jpg',
        ),
        _story(
          id: 3,
          dateLabel: '2026.03.10',
          latitude: 30.28,
          longitude: 120.16,
          location: '杭州',
          coverImagePath: '/managed/3.jpg',
        ),
      ];

      final clusters = buildLocalExifClusters(stories);

      expect(clusters.length, 2);
      expect(
        clusters.firstWhere((cluster) => cluster.label == '上海').storyCount,
        2,
      );
    });

    test(
      'cluster key filter only returns stories from the selected bucket',
      () {
        final shanghaiA = _story(
          id: 1,
          dateLabel: '2026.03.20',
          latitude: 31.20,
          longitude: 121.47,
          location: '上海',
          coverImagePath: '/managed/1.jpg',
        );
        final shanghaiB = _story(
          id: 2,
          dateLabel: '2026.03.19',
          latitude: 31.24,
          longitude: 121.52,
          location: '上海',
          coverImagePath: '/managed/2.jpg',
        );
        final hangzhou = _story(
          id: 3,
          dateLabel: '2026.03.10',
          latitude: 30.28,
          longitude: 120.16,
          location: '杭州',
          coverImagePath: '/managed/3.jpg',
        );

        final filtered = filterLocalExifStories(
          [shanghaiA, shanghaiB, hangzhou],
          dateFilter: MapDateFilter.all,
          clusterKey: clusterKeyFor(shanghaiA),
          now: DateTime(2026, 3, 24),
        );

        expect(filtered.map((story) => story.id), [1, 2]);
      },
    );
  });
}

StoryMoment _story({
  required int id,
  required String dateLabel,
  required double latitude,
  required double longitude,
  required String? coverImagePath,
  String location = unnamedLocationLabel,
}) {
  return StoryMomentData(
    id: id,
    title: 'Story $id',
    dateLabel: dateLabel,
    location: location,
    caption: 'caption',
    ambientLabel: 'ambient',
    latitude: latitude,
    longitude: longitude,
    palette: const [Color(0xFF101820), Color(0xFF3B82F6)],
    lines: const ['line'],
    coverImagePath: coverImagePath,
  );
}
