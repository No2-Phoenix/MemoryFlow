import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/glass_button.dart';
import '../../shared/gradient_background.dart';
import '../home/experience_controller_v2.dart';

class ContactDeveloperPage extends ConsumerWidget {
  const ContactDeveloperPage({super.key});

  static const String email = 'phoenixrise0803@163.com';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);

    Future<void> copyEmail() async {
      await Clipboard.setData(const ClipboardData(text: email));
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('邮箱已复制')));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        theme: theme,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GlassIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '联系开发者',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: GlassContainer(
                    borderRadius: 36,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '开发者邮箱',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          email,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '如果你有好的想法、建议，或者遇到问题，欢迎发送邮件到这个邮箱。你的反馈会帮助 MemoryFlow 持续改进。',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        GlassButton(
                          text: '复制邮箱地址',
                          icon: Icons.copy_rounded,
                          isActive: true,
                          expand: true,
                          onPressed: copyEmail,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
