import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/database_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/gradient_themes.dart';
import '../../shared/glass_button.dart';
import '../../shared/glass_confirm_dialog.dart';
import '../../shared/gradient_background.dart';
import 'experience_controller_v2.dart';
import 'story_library_controller.dart';

class HomeSettingsDrawer extends ConsumerWidget {
  const HomeSettingsDrawer({
    super.key,
    required this.isCompact,
    required this.maxWidth,
    required this.isOpen,
    required this.state,
    required this.onClose,
  });

  final bool isCompact;
  final double maxWidth;
  final bool isOpen;
  final ExperienceState state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawerWidth = isCompact ? maxWidth * 0.94 : maxWidth * 0.42;
    final controller = ref.read(experienceControllerProvider.notifier);
    final story = ref.watch(currentStoryProvider);
    final customMusicPath = state.globalMusicPath?.trim();
    final hasCustomMusic =
        customMusicPath != null && customMusicPath.isNotEmpty;
    final currentMusicLabel = hasCustomMusic
        ? customMusicPath.split(RegExp(r'[\\/]')).last
        : 'paulyudin-piano-music-piano-485929.mp3';

    Future<void> clearAllLocalUserData() async {
      final confirmed = await showGlassConfirmDialog(
        context,
        title: '永久清空本地数据',
        message: '这会删除所有用户故事、封面本地副本与关联缓存，操作后无法恢复。',
        confirmText: '永久清空',
        accentColor: const Color(0xFFFF6B6B),
        icon: Icons.delete_sweep_rounded,
      );
      if (!confirmed) {
        return;
      }

      await ref.read(storyLibraryProvider.notifier).clearAllUserData();
      if (!context.mounted) {
        return;
      }
      controller.closeDrawer();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('本地用户数据已清空')));
    }

    Future<void> deleteCurrentStory() async {
      final confirmed = await showGlassConfirmDialog(
        context,
        title: '永久删除当前故事',
        message: '当前故事的文本、封面本地副本与关联缓存会一起删除，操作后无法恢复。',
        confirmText: '永久删除',
        accentColor: const Color(0xFFFF6B6B),
        icon: Icons.delete_forever_rounded,
      );
      if (!confirmed) {
        return;
      }

      await ref.read(storyLibraryProvider.notifier).deleteStory(story.id);
      if (!context.mounted) {
        return;
      }
      controller.closeDrawer();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前故事已删除并清理本地数据')));
    }

    Future<void> exportUserData() async {
      try {
        final transfer = ref.read(userDataTransferServiceProvider);
        final exportFile = await transfer.exportToFile();
        if (!context.mounted) {
          return;
        }

        await Share.shareXFiles(
          [XFile(exportFile.path)],
          text: 'MemoryFlow 数据备份',
          subject: 'MemoryFlow Backup',
        );
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('备份已导出，可直接分享给新设备')));
      } catch (error) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败: $error')));
      }
    }

    Future<void> importUserData() async {
      final confirmed = await showGlassConfirmDialog(
        context,
        title: '导入并覆盖本地数据',
        message: '导入后会用备份文件覆盖当前数据。建议先执行一次导出再继续。',
        confirmText: '继续导入',
        accentColor: const Color(0xFFFFC857),
        icon: Icons.cloud_upload_rounded,
      );
      if (!confirmed) {
        return;
      }

      try {
        final picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['json', 'mfdata'],
        );
        final path = picked?.files.single.path;
        if (path == null || path.trim().isEmpty) {
          return;
        }

        final transfer = ref.read(userDataTransferServiceProvider);
        final result = await transfer.importFromFile(path);
        await ref.read(storyLibraryProvider.notifier).reload();
        ref.read(experienceControllerProvider.notifier).selectStory(0);

        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '导入完成：${result.storyCount} 个故事，${result.assetCount} 个资源已恢复',
            ),
          ),
        );
      } catch (error) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入失败: $error')));
      }
    }

    Future<void> pickGlobalMusic() async {
      try {
        final picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['mp3', 'wav', 'm4a', 'aac', 'flac', 'ogg'],
        );
        final file = picked?.files.single;
        final path = file?.path;
        if (path == null || path.trim().isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('未选择配乐文件或未授予媒体权限')));
          }
          return;
        }

        controller.setGlobalMusicPath(path);
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已切换全局配乐: ${file!.name}')));
      } catch (error) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('上传配乐失败: $error')));
      }
    }

    void resetGlobalMusic() {
      controller.setGlobalMusicPath(null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已恢复默认全局配乐')));
    }

    return Stack(
      children: [
        IgnorePointer(
          ignoring: !isOpen,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 260),
            opacity: isOpen ? 1 : 0,
            child: GestureDetector(
              onTap: onClose,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: isCompact ? 8 : 18,
                  sigmaY: isCompact ? 8 : 18,
                ),
                child: Container(color: Colors.black.withValues(alpha: 0.2)),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            offset: isOpen ? Offset.zero : const Offset(-1.02, 0),
            child: SizedBox(
              width: drawerWidth,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GlassContainer(
                  borderRadius: 36,
                  padding: EdgeInsets.all(isCompact ? 18 : 24),
                  child: ListView(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '设置与自定义',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          GlassIconButton(
                            icon: Icons.close_rounded,
                            onPressed: onClose,
                            size: 44,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '创作页中的“显示日期/位置/音乐”已改为每个故事独立设置，这里仅保留全局能力。',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        '主题氛围',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(GradientThemes.all.length, (index) {
                        final theme = GradientThemes.all[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassContainer(
                            onTap: () => controller.setThemeIndex(index),
                            borderRadius: 24,
                            tintColor: theme.accentColor,
                            opacity: state.themeIndex == index ? 0.22 : 0.1,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: theme.backgroundGradient,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.24,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    theme.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                ),
                                if (state.themeIndex == index)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: theme.accentColor,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 18),
                      Text(
                        '显示项',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _DrawerSwitchTile(
                        label: '显示标题',
                        description: '控制主画面下方标题区域是否显示标题。',
                        value: state.showTitle,
                        onChanged: controller.setShowTitle,
                      ),
                      const SizedBox(height: 10),
                      _DrawerSwitchTile(
                        label: '显示摘要',
                        description: '控制主画面下方标题区域是否显示摘要文案。',
                        value: state.showCaption,
                        onChanged: controller.setShowCaption,
                      ),
                      const SizedBox(height: 10),
                      _DrawerSwitchTile(
                        label: '全局配乐',
                        description: '对所有照片统一生效的配乐开关。',
                        value: state.showAmbient,
                        onChanged: controller.setShowAmbient,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '全局配乐',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      GlassContainer(
                        borderRadius: 24,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasCustomMusic ? '已使用自定义配乐' : '已使用默认配乐',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currentMusicLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: GlassButton(
                              text: '上传配乐',
                              icon: Icons.library_music_outlined,
                              expand: true,
                              onPressed: pickGlobalMusic,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassButton(
                              text: '恢复默认',
                              icon: Icons.restart_alt_rounded,
                              expand: true,
                              onPressed: hasCustomMusic
                                  ? resetGlobalMusic
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '数据迁移',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GlassButton(
                              text: '一键导出',
                              icon: Icons.ios_share_rounded,
                              expand: true,
                              onPressed: exportUserData,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassButton(
                              text: '一键导入',
                              icon: Icons.file_open_rounded,
                              expand: true,
                              onPressed: importUserData,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '本地隐私',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _DrawerSwitchTile(
                        label: '本地数据总开关',
                        description: '关闭后不再读取新导入的照片 EXIF 信息。',
                        value: state.localDataEnabled,
                        onChanged: controller.setLocalDataEnabled,
                      ),
                      const SizedBox(height: 12),
                      GlassButton(
                        text: '永久删除当前故事',
                        icon: Icons.delete_forever_rounded,
                        expand: true,
                        isActive: true,
                        highlightColor: const Color(0xFFFF6B6B),
                        onPressed: deleteCurrentStory,
                      ),
                      const SizedBox(height: 12),
                      GlassButton(
                        text: '清空全部本地用户数据',
                        icon: Icons.delete_sweep_rounded,
                        expand: true,
                        highlightColor: const Color(0xFFFF6B6B),
                        onPressed: clearAllLocalUserData,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '扩展入口',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GlassButton(
                              text: '地图映射',
                              icon: Icons.near_me_outlined,
                              expand: true,
                              onPressed: () => context.push(AppRoutes.map),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GlassButton(
                        text: '联系开发者',
                        icon: Icons.mail_outline_rounded,
                        expand: true,
                        onPressed: () =>
                            context.push(AppRoutes.contactDeveloper),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawerSwitchTile extends StatelessWidget {
  const _DrawerSwitchTile({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
