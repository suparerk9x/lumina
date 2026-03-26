import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_provider.dart';

/// ไฟล์นี้กำหนด Widget หลักของแอป Lumina
/// ทำหน้าที่ตั้งค่า MaterialApp รวมถึงธีม ฟอนต์ และหน้าแรก

/// Widget หลักของแอป ใช้ ConsumerWidget เพื่อดึงค่าการตั้งค่าจาก Riverpod
class LuminaApp extends ConsumerWidget {
  const LuminaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ดึงค่าการตั้งค่าปัจจุบัน (ขนาดฟอนต์, ชนิดฟอนต์) แบบ reactive
    // ถ้าผู้ใช้เปลี่ยนการตั้งค่า หน้าจอจะอัปเดตอัตโนมัติ
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: AppConstants.appName,
      // ใช้ธีมสว่าง โดยปรับขนาดและชนิดฟอนต์ตามที่ผู้ใช้ตั้งไว้
      theme: AppTheme.lightTheme(
        fontScale: settings.fontScale.value,
        fontFamily: settings.appFont.family,
      ),
      // ซ่อนป้าย "DEBUG" มุมขวาบน
      debugShowCheckedModeBanner: false,
      // กำหนดหน้าแรกของแอปเป็น HomeScreen
      home: const HomeScreen(),
    );
  }
}
