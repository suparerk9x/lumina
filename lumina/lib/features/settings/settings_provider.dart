import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/theme.dart';
import '../../shared/storage/hive_boxes.dart';

/// ไฟล์นี้จัดการ state ของหน้าตั้งค่า
/// เก็บข้อมูลฟอนต์, ขนาดตัวอักษร, โหมดธีม, และสีพื้นหลัง
/// ใช้ Hive บันทึกค่าลงเครื่อง

/// ระดับขนาดตัวอักษร สำหรับผู้ใช้ที่ต้องการตัวอักษรใหญ่ขึ้น
enum FontScale {
  small(0.9, 'เล็ก'),
  normal(1.0, 'ปกติ'),
  large(1.2, 'ใหญ่'),
  extraLarge(1.4, 'ใหญ่มาก');

  const FontScale(this.value, this.label);

  final double value;
  final String label;
}

/// ฟอนต์ไทยที่ใช้ได้ในแอป
enum AppFont {
  sarabun('Sarabun', 'Sarabun', 'อ่านง่าย เรียบ'),
  kanit('Kanit', 'Kanit', 'ทันสมัย โค้งมน'),
  prompt('Prompt', 'Prompt', 'สะอาดตา คมชัด'),
  mitr('Mitr', 'Mitr', 'เป็นมิตร น่ารัก'),
  notoSansThai('NotoSansThai', 'Noto Sans Thai', 'มาตรฐาน ครบทุกตัว');

  const AppFont(this.family, this.displayName, this.description);

  final String family;
  final String displayName;
  final String description;
}

/// โหมดธีม: สว่าง, มืด, หรือตามระบบ
enum AppThemeMode {
  light('สว่าง', Icons.light_mode_rounded),
  dark('มืด', Icons.dark_mode_rounded),
  system('ตามระบบ', Icons.settings_brightness_rounded);

  const AppThemeMode(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// โมเดลเก็บสถานะการตั้งค่าทั้งหมด
class SettingsState {
  const SettingsState({
    this.fontScale = FontScale.normal,
    this.appFont = AppFont.sarabun,
    this.themeMode = AppThemeMode.light,
    this.backgroundPresetIndex = 0,
  });

  final FontScale fontScale;
  final AppFont appFont;
  final AppThemeMode themeMode;
  final int backgroundPresetIndex; // index ใน backgroundPresets

  /// สีพื้นหลังที่เลือกสำหรับโหมดสว่าง
  Color get lightBgColor => backgroundPresets[backgroundPresetIndex].lightColor;

  /// สีพื้นหลังที่เลือกสำหรับโหมดมืด
  Color get darkBgColor => backgroundPresets[backgroundPresetIndex].darkColor;

  SettingsState copyWith({
    FontScale? fontScale,
    AppFont? appFont,
    AppThemeMode? themeMode,
    int? backgroundPresetIndex,
  }) {
    return SettingsState(
      fontScale: fontScale ?? this.fontScale,
      appFont: appFont ?? this.appFont,
      themeMode: themeMode ?? this.themeMode,
      backgroundPresetIndex:
          backgroundPresetIndex ?? this.backgroundPresetIndex,
    );
  }
}

/// ตัวจัดการ logic ของหน้าตั้งค่า
class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final box = Hive.box(HiveBoxes.screenTimeSettings);
    final savedScaleIndex = box.get('fontScaleIndex', defaultValue: 1) as int;
    final savedFontIndex = box.get('fontFamilyIndex', defaultValue: 0) as int;
    final savedThemeIndex = box.get('themeModeIndex', defaultValue: 0) as int;
    final savedBgIndex =
        box.get('backgroundPresetIndex', defaultValue: 0) as int;

    return SettingsState(
      fontScale: FontScale
          .values[savedScaleIndex.clamp(0, FontScale.values.length - 1)],
      appFont:
          AppFont.values[savedFontIndex.clamp(0, AppFont.values.length - 1)],
      themeMode: AppThemeMode
          .values[savedThemeIndex.clamp(0, AppThemeMode.values.length - 1)],
      backgroundPresetIndex:
          savedBgIndex.clamp(0, backgroundPresets.length - 1),
    );
  }

  Future<void> setFontScale(FontScale scale) async {
    final box = Hive.box(HiveBoxes.screenTimeSettings);
    await box.put('fontScaleIndex', scale.index);
    state = state.copyWith(fontScale: scale);
  }

  Future<void> setAppFont(AppFont font) async {
    final box = Hive.box(HiveBoxes.screenTimeSettings);
    await box.put('fontFamilyIndex', font.index);
    state = state.copyWith(appFont: font);
  }

  /// เปลี่ยนโหมดธีม (สว่าง/มืด/ตามระบบ)
  Future<void> setThemeMode(AppThemeMode mode) async {
    final box = Hive.box(HiveBoxes.screenTimeSettings);
    await box.put('themeModeIndex', mode.index);
    state = state.copyWith(themeMode: mode);
  }

  /// เปลี่ยนสีพื้นหลัง
  Future<void> setBackgroundPreset(int index) async {
    final box = Hive.box(HiveBoxes.screenTimeSettings);
    await box.put('backgroundPresetIndex', index);
    state = state.copyWith(backgroundPresetIndex: index);
  }
}

/// Provider หลักที่ UI ใช้เข้าถึง state ของหน้าตั้งค่า
final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
