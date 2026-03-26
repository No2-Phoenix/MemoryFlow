import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../home/story_moment_data.dart';

class Mp4ExportResult {
  const Mp4ExportResult({
    required this.outputPath,
    required this.storyCount,
    required this.hasAudio,
  });

  final String outputPath;
  final int storyCount;
  final bool hasAudio;
}

class Mp4ExportService {
  const Mp4ExportService();

  Future<Mp4ExportResult> exportStoriesToAlbum({
    required List<StoryMoment> stories,
    String? globalMusicPath,
    int maxStories = 4,
  }) async {
    final candidates = stories
        .where((story) {
          final path = story.coverImagePath?.trim();
          return path != null && path.isNotEmpty;
        })
        .take(maxStories)
        .toList();

    if (candidates.isEmpty) {
      throw StateError(
        'No exportable image found. Please upload at least one photo first.',
      );
    }

    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory('${tempDir.path}/memoryflow_exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${exportDir.path}/memoryflow_$timestamp.mp4';
    final imageInputArgs = StringBuffer();
    final filterGraph = StringBuffer();
    final segmentLabels = <String>[];

    var inputIndex = 0;
    for (final story in candidates) {
      final coverPath = story.coverImagePath!.trim();
      if (!await File(coverPath).exists()) {
        continue;
      }

      imageInputArgs.write(' -loop 1 -t 6 -i ${_q(coverPath)}');
      final labelIndex = segmentLabels.length;
      segmentLabels.add('[v$labelIndex]');
      filterGraph.write(
        '[$inputIndex:v]scale=1080:1920:force_original_aspect_ratio=increase,'
        'crop=1080:1920,format=yuv420p,setsar=1,fps=30[v$labelIndex];',
      );
      inputIndex += 1;
    }

    if (segmentLabels.isEmpty) {
      throw StateError('All candidate images are missing on disk.');
    }

    filterGraph.write(
      '${segmentLabels.join()}concat=n=${segmentLabels.length}:v=1:a=0[vout]',
    );

    final customMusicPath = globalMusicPath?.trim();
    final resolvedMusicPath = customMusicPath ?? '';
    final hasCustomMusic =
        customMusicPath != null &&
        customMusicPath.isNotEmpty &&
        await File(customMusicPath).exists();

    final audioInputArg = hasCustomMusic
        ? ' -stream_loop -1 -i ${_q(resolvedMusicPath)}'
        : '';
    final audioMapArg = hasCustomMusic
        ? ' -map [vout] -map $inputIndex:a'
        : ' -map [vout]';
    final audioCodecArg = hasCustomMusic ? ' -c:a aac -b:a 192k -shortest' : '';

    final command =
        '-y'
        '${imageInputArgs.toString()}'
        '$audioInputArg'
        ' -filter_complex ${_q(filterGraph.toString())}'
        '$audioMapArg'
        ' -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p'
        '$audioCodecArg'
        ' -movflags +faststart ${_q(outputPath)}';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      throw StateError('FFmpeg failed: $logs');
    }

    final permission = await PhotoManager.requestPermissionExtend();
    final hasPermission =
        permission == PermissionState.authorized ||
        permission == PermissionState.limited;
    if (!hasPermission) {
      throw StateError('Photo permission denied.');
    }

    await PhotoManager.editor.saveVideo(
      File(outputPath),
      title: 'memoryflow_$timestamp',
    );

    return Mp4ExportResult(
      outputPath: outputPath,
      storyCount: segmentLabels.length,
      hasAudio: hasCustomMusic,
    );
  }

  String _q(String raw) {
    final escaped = raw.replaceAll('\\', '\\\\').replaceAll('"', r'\"');
    return '"$escaped"';
  }
}
