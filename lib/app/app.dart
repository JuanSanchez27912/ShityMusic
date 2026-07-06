import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/presentation/controllers/settings_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/home_shell.dart';

class ShityMusicApp extends ConsumerWidget {
  const ShityMusicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final themeMode =
        settings.asData?.value.themePreference.toThemeMode() ??
        ThemeMode.system;

    return MaterialApp(
      title: 'Shity Music',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const HomeShell(),
    );
  }
}
