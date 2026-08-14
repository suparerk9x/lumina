import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'features/settings/settings_provider.dart';
import 'features/splash/splash_screen.dart';

/// Widget หลักของแอป ใช้ ConsumerWidget เพื่อดึงค่าการตั้งค่าจาก Riverpod
class DemenishApp extends ConsumerWidget {
  const DemenishApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // แปลง AppThemeMode เป็น Flutter ThemeMode
    final themeMode = switch (settings.themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp(
      title: AppConstants.appName,
      // ธีมสว่าง
      theme: AppTheme.lightTheme(
        fontScale: settings.fontScale.value,
        fontFamily: settings.appFont.family,
        bgColor: settings.lightBgColor,
      ),
      // ธีมมืด
      darkTheme: AppTheme.darkTheme(
        fontScale: settings.fontScale.value,
        fontFamily: settings.appFont.family,
        bgColor: settings.darkBgColor,
      ),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
