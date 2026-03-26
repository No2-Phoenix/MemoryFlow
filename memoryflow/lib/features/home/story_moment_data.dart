import 'package:flutter/material.dart';

import 'experience_models.dart';

@immutable
class StoryMomentData {
  const StoryMomentData({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.location,
    required this.caption,
    required this.ambientLabel,
    required this.latitude,
    required this.longitude,
    required this.palette,
    required this.lines,
    this.textMode = StoryTextMode.lyrics,
    this.coverImagePath,
    this.coverBlurSigma = 2.0,
    this.cameraModel,
    this.showDate = true,
    this.showLocation = true,
    this.showAmbient = true,
    this.isUserCreated = false,
  });

  final int id;
  final String title;
  final String dateLabel;
  final String location;
  final String caption;
  final String ambientLabel;
  final double latitude;
  final double longitude;
  final List<Color> palette;
  final List<String> lines;
  final StoryTextMode textMode;
  final String? coverImagePath;
  final double coverBlurSigma;
  final String? cameraModel;
  final bool showDate;
  final bool showLocation;
  final bool showAmbient;
  final bool isUserCreated;

  Color get dominantColor => palette[palette.length > 1 ? 1 : 0];
}

typedef StoryMoment = StoryMomentData;

class StoryMomentFallback {
  static const StoryMomentData empty = StoryMomentData(
    id: 0,
    title: '未命名故事',
    dateLabel: '----.--.--',
    location: '',
    caption: '',
    ambientLabel: '自动匹配',
    latitude: 0,
    longitude: 0,
    palette: [Color(0xFF0F172A), Color(0xFF1F2937), Color(0xFF475569)],
    lines: [''],
    textMode: StoryTextMode.lyrics,
    coverBlurSigma: 2.0,
    showDate: false,
    showLocation: false,
    showAmbient: true,
    isUserCreated: true,
  );
}
