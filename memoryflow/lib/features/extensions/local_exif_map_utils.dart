import '../home/story_moment_data.dart';

const String unnamedLocationLabel = '未命名地点';

enum MapDateFilter { all, last30Days, last90Days, thisYear }

extension MapDateFilterX on MapDateFilter {
  String get label {
    switch (this) {
      case MapDateFilter.all:
        return '全部';
      case MapDateFilter.last30Days:
        return '近 30 天';
      case MapDateFilter.last90Days:
        return '近 90 天';
      case MapDateFilter.thisYear:
        return '今年';
    }
  }
}

class LocalExifCluster {
  const LocalExifCluster({
    required this.key,
    required this.label,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.stories,
    required this.startDate,
    required this.endDate,
  });

  final String key;
  final String label;
  final double centerLatitude;
  final double centerLongitude;
  final List<StoryMoment> stories;
  final DateTime startDate;
  final DateTime endDate;

  int get storyCount => stories.length;

  StoryMoment get leadStory => stories.first;
}

bool hasLocalExifCoordinates(StoryMoment story) {
  final hasManagedCover =
      story.coverImagePath != null && story.coverImagePath!.trim().isNotEmpty;
  final hasCoordinates =
      story.latitude.abs() > 0.00001 || story.longitude.abs() > 0.00001;
  return hasManagedCover && hasCoordinates;
}

DateTime parseStoryMomentDate(StoryMoment story) {
  final parts = story.dateLabel.split('.');
  if (parts.length == 3) {
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year != null && month != null && day != null) {
      return DateTime(year, month, day);
    }
  }

  return DateTime.fromMillisecondsSinceEpoch(story.id);
}

List<StoryMoment> filterLocalExifStories(
  List<StoryMoment> stories, {
  required MapDateFilter dateFilter,
  String? clusterKey,
  DateTime? now,
}) {
  final anchor = now ?? DateTime.now();
  final localStories = stories.where(hasLocalExifCoordinates).toList()
    ..sort(
      (left, right) =>
          parseStoryMomentDate(right).compareTo(parseStoryMomentDate(left)),
    );

  final filteredByDate = localStories.where((story) {
    final date = parseStoryMomentDate(story);
    switch (dateFilter) {
      case MapDateFilter.all:
        return true;
      case MapDateFilter.last30Days:
        return !date.isBefore(anchor.subtract(const Duration(days: 30)));
      case MapDateFilter.last90Days:
        return !date.isBefore(anchor.subtract(const Duration(days: 90)));
      case MapDateFilter.thisYear:
        return date.year == anchor.year;
    }
  }).toList();

  if (clusterKey == null || clusterKey.isEmpty) {
    return filteredByDate;
  }

  return filteredByDate
      .where((story) => clusterKeyFor(story) == clusterKey)
      .toList();
}

List<LocalExifCluster> buildLocalExifClusters(
  List<StoryMoment> stories, {
  double gridSize = 0.45,
}) {
  final localStories = stories.where(hasLocalExifCoordinates).toList();
  if (localStories.isEmpty) {
    return const [];
  }

  final buckets = <String, List<StoryMoment>>{};
  for (final story in localStories) {
    final key = clusterKeyFor(story, gridSize: gridSize);
    buckets.putIfAbsent(key, () => <StoryMoment>[]).add(story);
  }

  return buckets.entries.map((entry) {
    final clusterStories = List<StoryMoment>.from(entry.value)
      ..sort(
        (left, right) =>
            parseStoryMomentDate(left).compareTo(parseStoryMomentDate(right)),
      );

    final centerLatitude =
        clusterStories.map((story) => story.latitude).reduce((a, b) => a + b) /
        clusterStories.length;
    final centerLongitude =
        clusterStories.map((story) => story.longitude).reduce((a, b) => a + b) /
        clusterStories.length;

    return LocalExifCluster(
      key: entry.key,
      label: _clusterLabel(clusterStories, centerLatitude, centerLongitude),
      centerLatitude: centerLatitude,
      centerLongitude: centerLongitude,
      stories: clusterStories.reversed.toList(),
      startDate: parseStoryMomentDate(clusterStories.first),
      endDate: parseStoryMomentDate(clusterStories.last),
    );
  }).toList()..sort((left, right) => right.endDate.compareTo(left.endDate));
}

String clusterKeyFor(StoryMoment story, {double gridSize = 0.45}) {
  final latitudeBucket = (story.latitude / gridSize).round();
  final longitudeBucket = (story.longitude / gridSize).round();
  return '$latitudeBucket:$longitudeBucket';
}

String _clusterLabel(
  List<StoryMoment> stories,
  double centerLatitude,
  double centerLongitude,
) {
  final counts = <String, int>{};
  for (final story in stories) {
    final location = story.location.trim();
    if (location.isEmpty || location == unnamedLocationLabel) {
      continue;
    }
    counts.update(location, (value) => value + 1, ifAbsent: () => 1);
  }

  if (counts.isNotEmpty) {
    return counts.entries.reduce((left, right) {
      return left.value >= right.value ? left : right;
    }).key;
  }

  return '${centerLatitude.toStringAsFixed(2)}, '
      '${centerLongitude.toStringAsFixed(2)}';
}
