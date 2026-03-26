import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/utils/exif_utils.dart';
import '../../core/utils/story_palette.dart';
import '../../shared/glass_button.dart';
import '../../shared/glass_confirm_dialog.dart';
import '../../shared/gradient_background.dart';
import '../../shared/story_artwork.dart';
import '../home/experience_controller_v2.dart';
import '../home/story_library_controller.dart';
import '../home/story_moment_data.dart';

class StoryCreatorPageV2 extends ConsumerStatefulWidget {
  const StoryCreatorPageV2({super.key, this.createNew = false});

  final bool createNew;

  @override
  ConsumerState<StoryCreatorPageV2> createState() => _StoryCreatorPageV2State();
}

class _StoryCreatorPageV2State extends ConsumerState<StoryCreatorPageV2> {
  static const double _defaultCoverBlurSigma = 2.0;

  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _caption;
  late final TextEditingController _date;
  late final TextEditingController _story;
  late final String _followAmbient;
  late final String _fallbackAmbient;
  late List<Color> _palette;
  int? _editingId;
  String? _coverImagePath;
  String? _cameraModel;
  double? _latitude;
  double? _longitude;
  late double _coverBlurSigma;
  late bool _showDate;
  late bool _showLocation;
  late bool _showAmbient;
  late StoryTextMode _selectedTextMode;
  bool _isPicking = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _canDelete => _editingId != null;

  @override
  void initState() {
    super.initState();
    final selected = ref.read(currentStoryProvider);
    final presets = ref.read(ambientPresetsProvider);

    _followAmbient = presets.first;
    _fallbackAmbient = selected.ambientLabel;
    _palette = List<Color>.from(selected.palette);
    _editingId = widget.createNew ? null : selected.id;
    _coverImagePath = widget.createNew ? null : selected.coverImagePath;
    _cameraModel = widget.createNew ? null : selected.cameraModel;
    _coverBlurSigma = widget.createNew
        ? _defaultCoverBlurSigma
        : selected.coverBlurSigma;
    _latitude = widget.createNew || selected.latitude == 0
        ? null
        : selected.latitude;
    _longitude = widget.createNew || selected.longitude == 0
        ? null
        : selected.longitude;
    _showDate = widget.createNew ? true : selected.showDate;
    _showLocation = widget.createNew ? true : selected.showLocation;
    _showAmbient = widget.createNew ? true : selected.showAmbient;
    _selectedTextMode = selected.textMode;

    _title = TextEditingController(
      text: widget.createNew ? '' : selected.title,
    );
    _location = TextEditingController(
      text: widget.createNew ? '' : selected.location,
    );
    _caption = TextEditingController(
      text: widget.createNew ? '' : selected.caption,
    );
    _date = TextEditingController(
      text: widget.createNew ? _formatDate(DateTime.now()) : selected.dateLabel,
    );
    _story = TextEditingController(
      text: widget.createNew ? '' : selected.lines.join('\n\n'),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _caption.dispose();
    _date.dispose();
    _story.dispose();
    super.dispose();
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}.$month.$day';
  }

  String _effectiveAmbient(String selectedPreset) {
    return selectedPreset == _followAmbient ? _fallbackAmbient : selectedPreset;
  }

  void _showFeedback(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  StoryMoment _previewStory(String ambientLabel) {
    final previewLines = _story.text
        .split(RegExp(r'\n{2,}|\r\n\r\n'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .take(4)
        .toList();

    return StoryMoment(
      id: _editingId ?? 0,
      title: _title.text.trim().isEmpty ? '未命名故事' : _title.text.trim(),
      dateLabel: _date.text.trim().isEmpty
          ? _formatDate(DateTime.now())
          : _date.text.trim(),
      location: _location.text.trim().isEmpty ? '未填写地点' : _location.text.trim(),
      caption: _caption.text.trim().isEmpty
          ? '把这一刻留在玻璃般流动的画面里。'
          : _caption.text.trim(),
      ambientLabel: ambientLabel,
      textMode: _selectedTextMode,
      latitude: _latitude ?? 0,
      longitude: _longitude ?? 0,
      palette: _palette.isEmpty ? StoryPalette.defaultPalette : _palette,
      lines: previewLines.isEmpty
          ? const ['让文字从底部缓慢升起，停在记忆最亮的地方。']
          : previewLines,
      coverImagePath: _coverImagePath,
      coverBlurSigma: _coverBlurSigma,
      cameraModel: _cameraModel,
      showDate: _showDate,
      showLocation: _showLocation,
      showAmbient: _showAmbient,
    );
  }

  Future<void> _pickCoverImage() async {
    if (_isPicking) {
      return;
    }
    setState(() => _isPicking = true);
    try {
      final picked = await ExifUtils.pickImage();
      if (picked == null) {
        _showFeedback('未选择图片或未授予相册权限');
        return;
      }
      final path = picked.path;
      DateTime? photoDate;
      String? cameraModel;
      Map<String, double>? gps;
      String? locationName;
      var extractedPalette = _palette;
      try {
        photoDate = await ExifUtils.getPhotoDate(path);
      } catch (error, stackTrace) {
        debugPrint('Read photo date failed: $error');
        debugPrint('$stackTrace');
      }
      try {
        cameraModel = await ExifUtils.getCameraModel(path);
      } catch (error, stackTrace) {
        debugPrint('Read camera model failed: $error');
        debugPrint('$stackTrace');
      }
      try {
        gps = await ExifUtils.getGpsCoordinates(path);
      } catch (error, stackTrace) {
        debugPrint('Read GPS failed: $error');
        debugPrint('$stackTrace');
      }
      try {
        locationName = await ExifUtils.getPhotoLocationName(path);
      } catch (error, stackTrace) {
        debugPrint('Read location name failed: $error');
        debugPrint('$stackTrace');
      }
      try {
        extractedPalette = await StoryPalette.fromImage(
          path,
          fallback: _palette,
        );
      } catch (error, stackTrace) {
        debugPrint('Extract palette failed: $error');
        debugPrint('$stackTrace');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _coverImagePath = path;
        _cameraModel = cameraModel;
        _latitude = gps?['latitude'];
        _longitude = gps?['longitude'];
        _palette = extractedPalette;
        if (_location.text.trim().isEmpty && locationName != null) {
          _location.text = locationName;
        }
        if (photoDate != null) {
          _date.text = _formatDate(photoDate);
        }
      });
    } catch (error, stackTrace) {
      debugPrint('Pick cover image failed: $error');
      debugPrint('$stackTrace');
      _showFeedback('读取照片失败，请检查权限后重试');
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final experience = ref.read(experienceControllerProvider);
      final lines = _story.text
          .split(RegExp(r'\n{2,}|\r\n\r\n'))
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      final saved = await ref
          .read(storyLibraryProvider.notifier)
          .saveDraft(
            StoryDraftInput(
              title: _title.text.trim().isEmpty ? '未命名故事' : _title.text.trim(),
              dateLabel: _date.text.trim().isEmpty
                  ? _formatDate(DateTime.now())
                  : _date.text.trim(),
              location: _location.text.trim().isEmpty
                  ? '未填写地点'
                  : _location.text.trim(),
              caption: _caption.text.trim().isEmpty
                  ? '把这一刻留在玻璃般流动的画面里。'
                  : _caption.text.trim(),
              ambientLabel: _effectiveAmbient(experience.ambientPreset),
              textMode: _selectedTextMode,
              lines: lines.isEmpty ? const ['让文字从底部缓慢升起，停在记忆最亮的地方。'] : lines,
              palette: _palette.isEmpty
                  ? StoryPalette.defaultPalette
                  : _palette,
              showDate: _showDate,
              showLocation: _showLocation,
              showAmbient: _showAmbient,
              latitude: _latitude,
              longitude: _longitude,
              coverImagePath: _coverImagePath,
              coverBlurSigma: _coverBlurSigma,
              cameraModel: _cameraModel,
            ),
            storyId: _editingId,
          );
      final stories = ref.read(storiesProvider);
      final index = stories.indexWhere((story) => story.id == saved.id);
      if (index >= 0) {
        ref.read(experienceControllerProvider.notifier).selectStory(index);
      }
      if (mounted) {
        context.pop();
      }
    } catch (error, stackTrace) {
      debugPrint('Save story failed: $error');
      debugPrint('$stackTrace');
      _showFeedback('创建故事失败：$error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete() async {
    if (_editingId == null || _isDeleting) {
      return;
    }
    final confirmed = await showGlassConfirmDialog(
      context,
      title: '永久删除当前故事',
      message: '这会清空当前故事的本地文本、封面副本、EXIF 元数据和关联缓存，操作后无法恢复。',
      confirmText: '永久删除',
      accentColor: const Color(0xFFFF6B6B),
      icon: Icons.delete_forever_rounded,
    );
    if (!confirmed) {
      return;
    }
    setState(() => _isDeleting = true);
    try {
      await ref.read(storyLibraryProvider.notifier).deleteStory(_editingId!);
      if (mounted) {
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final experience = ref.watch(experienceControllerProvider);
    final theme = ref.watch(currentThemeProvider);
    final ambientLabel = _effectiveAmbient(experience.ambientPreset);
    final previewStory = _previewStory(ambientLabel);
    final isCompact = MediaQuery.of(context).size.width < 980;

    final preview = _PreviewPane(
      story: previewStory,
      ambientLabel: ambientLabel,
      showDate: _showDate,
      showLocation: _showLocation,
      showAmbient: _showAmbient,
      coverBlurSigma: _coverBlurSigma,
      cameraModel: _cameraModel,
      latitude: _latitude,
      longitude: _longitude,
    );
    final form = _FormPane(
      themeName: theme.name,
      localDataEnabled: experience.localDataEnabled,
      selectedMode: _selectedTextMode,
      showDate: _showDate,
      showLocation: _showLocation,
      showAmbient: _showAmbient,
      title: _title,
      location: _location,
      caption: _caption,
      date: _date,
      story: _story,
      coverImagePath: _coverImagePath,
      cameraModel: _cameraModel,
      latitude: _latitude,
      longitude: _longitude,
      coverBlurSigma: _coverBlurSigma,
      palette: _palette,
      isPicking: _isPicking,
      canDelete: _canDelete,
      isDeleting: _isDeleting,
      onChanged: () => setState(() {}),
      onPickCoverImage: _pickCoverImage,
      onClearCoverImage: _coverImagePath == null
          ? null
          : () => setState(() {
              _coverImagePath = null;
              _cameraModel = null;
              _latitude = null;
              _longitude = null;
              _palette = StoryPalette.defaultPalette;
              _coverBlurSigma = _defaultCoverBlurSigma;
            }),
      onSelectMode: (value) => setState(() => _selectedTextMode = value),
      onCoverBlurChanged: (value) => setState(() => _coverBlurSigma = value),
      onToggleShowDate: (value) => setState(() => _showDate = value),
      onToggleShowLocation: (value) => setState(() => _showLocation = value),
      onToggleShowAmbient: (value) => setState(() => _showAmbient = value),
      onDelete: _canDelete ? _delete : null,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 16 : 24,
            18,
            isCompact ? 16 : 24,
            24,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  GlassIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.createNew ? '新建故事' : '编辑当前故事',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: isCompact
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 108),
                        child: Column(
                          children: [preview, const SizedBox(height: 18), form],
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 108),
                              child: preview,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 108),
                              child: form,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(
              child: GlassButton(
                text: '地图映射',
                icon: Icons.near_me_outlined,
                onPressed: () => context.push(AppRoutes.map),
                expand: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassButton(
                text: _isSaving
                    ? '保存中...'
                    : (widget.createNew ? '创建故事' : '保存故事'),
                icon: Icons.auto_awesome_outlined,
                highlightColor: theme.accentColor,
                isActive: true,
                expand: true,
                onPressed: _isSaving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPane extends StatelessWidget {
  const _PreviewPane({
    required this.story,
    required this.ambientLabel,
    required this.showDate,
    required this.showLocation,
    required this.showAmbient,
    required this.coverBlurSigma,
    required this.cameraModel,
    required this.latitude,
    required this.longitude,
  });

  final StoryMoment story;
  final String ambientLabel;
  final bool showDate;
  final bool showLocation;
  final bool showAmbient;
  final double coverBlurSigma;
  final String? cameraModel;
  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context) {
    final chips = <String>[
      if (showDate) story.dateLabel,
      if (showLocation) story.location,
      ?cameraModel,
    ];

    return GlassContainer(
      borderRadius: 36,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          SizedBox(
            height: 460,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  StoryArtwork(
                    palette: story.palette,
                    imagePath: story.coverImagePath,
                    imageBlurSigma: coverBlurSigma,
                    overlayColor: story.dominantColor,
                  ),
                  Positioned(
                    top: 18,
                    left: 18,
                    right: 18,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: chips
                          .map((label) => _MiniChip(label: label))
                          .toList(),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: GlassContainer(
                      borderRadius: 24,
                      tintColor: story.dominantColor,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            story.caption,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (showAmbient) ...[
                            const SizedBox(height: 14),
                            Text(
                              '氛围声场 · $ambientLabel',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniChip(
                label: latitude == null || longitude == null
                    ? '未读取到 GPS 坐标'
                    : '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}',
              ),
              _MiniChip(
                label: story.coverImagePath == null ? '使用生成画面' : '使用真实封面',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormPane extends StatelessWidget {
  const _FormPane({
    required this.themeName,
    required this.localDataEnabled,
    required this.selectedMode,
    required this.showDate,
    required this.showLocation,
    required this.showAmbient,
    required this.title,
    required this.location,
    required this.caption,
    required this.date,
    required this.story,
    required this.coverImagePath,
    required this.coverBlurSigma,
    required this.cameraModel,
    required this.latitude,
    required this.longitude,
    required this.palette,
    required this.isPicking,
    required this.canDelete,
    required this.isDeleting,
    required this.onChanged,
    required this.onPickCoverImage,
    required this.onClearCoverImage,
    required this.onSelectMode,
    required this.onCoverBlurChanged,
    required this.onToggleShowDate,
    required this.onToggleShowLocation,
    required this.onToggleShowAmbient,
    required this.onDelete,
  });

  final String themeName;
  final bool localDataEnabled;
  final StoryTextMode selectedMode;
  final bool showDate;
  final bool showLocation;
  final bool showAmbient;
  final TextEditingController title;
  final TextEditingController location;
  final TextEditingController caption;
  final TextEditingController date;
  final TextEditingController story;
  final String? coverImagePath;
  final double coverBlurSigma;
  final String? cameraModel;
  final double? latitude;
  final double? longitude;
  final List<Color> palette;
  final bool isPicking;
  final bool canDelete;
  final bool isDeleting;
  final VoidCallback onChanged;
  final VoidCallback onPickCoverImage;
  final VoidCallback? onClearCoverImage;
  final ValueChanged<StoryTextMode> onSelectMode;
  final ValueChanged<double> onCoverBlurChanged;
  final ValueChanged<bool> onToggleShowDate;
  final ValueChanged<bool> onToggleShowLocation;
  final ValueChanged<bool> onToggleShowAmbient;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 36,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('创作控制台', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '当前主题是 $themeName。这里的修改会实时反馈到左侧预览。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              GlassButton(
                text: isPicking ? '读取照片中...' : '选择封面照片',
                icon: Icons.add_photo_alternate_outlined,
                isActive: true,
                onPressed: isPicking ? null : onPickCoverImage,
              ),
              if (onClearCoverImage != null)
                GlassButton(
                  text: '移除封面',
                  icon: Icons.layers_clear_outlined,
                  onPressed: onClearCoverImage,
                ),
            ],
          ),
          const SizedBox(height: 14),
          GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '封面模糊度 · ${coverBlurSigma.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Slider(
                  value: coverBlurSigma.clamp(0.0, 18.0),
                  min: 0,
                  max: 18,
                  divisions: 36,
                  label: coverBlurSigma.toStringAsFixed(1),
                  onChanged: onCoverBlurChanged,
                ),
                Text(
                  '0 为清晰，数值越高越柔和。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (!localDataEnabled)
            GlassContainer(
              borderRadius: 24,
              padding: const EdgeInsets.all(16),
              child: Text(
                '本地数据开关已关闭，封面依然可以选择；如需完整本地映射与 EXIF 能力，请在设置中开启本地数据。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (!localDataEnabled) const SizedBox(height: 14),
          TextField(
            controller: title,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(labelText: '故事标题'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: location,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(labelText: '拍摄地点 / 场景'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: date,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(labelText: '拍摄日期'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: caption,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(labelText: '底部文案 / 旁白'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: story,
            onChanged: (_) => onChanged(),
            maxLines: 8,
            decoration: const InputDecoration(labelText: '流动文字（双换行分段）'),
          ),
          const SizedBox(height: 22),
          _SwitchTile(
            label: '显示日期',
            value: showDate,
            onChanged: onToggleShowDate,
          ),
          const SizedBox(height: 10),
          _SwitchTile(
            label: '显示位置',
            value: showLocation,
            onChanged: onToggleShowLocation,
          ),
          const SizedBox(height: 10),
          _SwitchTile(
            label: '显示全局配乐',
            value: showAmbient,
            onChanged: onToggleShowAmbient,
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: StoryTextMode.values
                .map(
                  (mode) => GlassButton(
                    text: mode.label,
                    isActive: selectedMode == mode,
                    onPressed: () => onSelectMode(mode),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniChip(
                label: coverImagePath == null ? '当前使用生成画面' : '当前已绑定真实照片',
              ),
              _MiniChip(label: cameraModel ?? '未读取到相机型号'),
              _MiniChip(
                label: latitude == null || longitude == null
                    ? '未读取到 GPS'
                    : '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PalettePreview(colors: palette),
          const SizedBox(height: 18),
          GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(16),
            child: Text(
              '用户上传的图片和元数据只保存在本地。永久删除会同步清空本地副本、EXIF 与缓存。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (canDelete && onDelete != null) ...[
            const SizedBox(height: 12),
            GlassButton(
              text: isDeleting ? '删除中...' : '永久删除当前故事',
              icon: Icons.delete_forever_rounded,
              expand: true,
              isActive: true,
              highlightColor: const Color(0xFFFF6B6B),
              onPressed: isDeleting ? null : onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleLarge),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PalettePreview extends StatelessWidget {
  const _PalettePreview({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int index = 0; index < colors.length; index++)
          Expanded(
            child: Container(
              height: 34,
              margin: EdgeInsets.only(
                right: index == colors.length - 1 ? 0 : 8,
              ),
              decoration: BoxDecoration(
                color: colors[index],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
