import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/home/experience_controller_v2.dart';
import 'shared/gradient_background.dart';

void appMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const ProviderScope(child: MemoryFlowApp()));
}

class MemoryFlowApp extends ConsumerWidget {
  const MemoryFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(currentThemeProvider);
    final overlayStyle = theme.isBright
        ? SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
          )
        : SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
          );

    return MaterialApp.router(
      title: 'MemoryFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(theme),
      routerConfig: router,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: GradientBackground(
            theme: theme,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
