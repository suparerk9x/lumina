import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../shared/storage/hive_boxes.dart';

/// ไฟล์นี้จัดการ state ของหน้าตั้งค่า
/// เก็บข้อมูลฟอนต์, ขนาดตัวอักษร, โหมดธีม, และสีพื้นหลัง
/// ใช้ Hive บันทึกค่าลงเครื่อง

/// ระดับขนาดตัวอักษร สำหรับผู้ใช้ที่ต้องการตัวอักษรใหญ่ขึ้น
enum FontScale {
  small(0.9, 'fontscale.small'),
  normal(1.0, 'fontscale.normal'),
  large(1.2, 'fontscale.large'),
  extraLarge(1.4, 'fontscale.extraLarge');

  const FontScale(this.value, this.labelKey);

  final double value;
  final String labelKey;

  String get label => tr(labelKey);
}

/// ฟอนต์ไทยที่ใช้ได้ในแอป
enum AppFont {
  sarabun('Sarabun', 'Sarabun', 'font.sarabun.desc'),
  kanit('Kanit', 'Kanit', 'font.kanit.desc'),
  prompt('Prompt', 'Prompt', 'font.prompt.desc'),
  mitr('Mitr', 'Mitr', 'font.mitr.desc'),
  notoSansThai('NotoSansThai', 'Noto Sans Thai', 'font.noto.desc');

  const AppFont(this.family, this.displayName, this.descKey);

  final String family;
  final String displayName;
  final String descKey;

  String get description => tr(descKey);
}

/// โหมดธีม: สว่าง, มืด, หรือตามระบบ
enum AppThemeMode {
  light('theme.light', Icons.light_mode_rounded),
  dark('theme.dark', Icons.dark_mode_rounded),
  system('theme.system', Icons.settings_brightness_rounded);

  const AppThemeMode(this.labelKey, this.icon);

  final String labelKey;
  final IconData icon;

  String get label => tr(labelKey);
}

/// โมเดลเก็บสถานะการตั้งค่าทั้งหมด
class SettingsState {
  const SettingsState({
    this.fontScale = FontScale.normal,
    this.appFont = AppFont.sarabun,
    this.themeMode = AppThemeMode.light,
    this.backgroundPresetIndex = 0,
    this.localeCode = 'en',
  });

  final FontScale fontScale;
  final AppFont appFont;
  final AppThemeMode themeMode;
  final int backgroundPresetIndex; // index ใน backgroundPresets
  final String localeCode; // ภาษา ('en' | 'th') — ค่าเริ่มต้น en

  /// สีพื้นหลังที่เลือกสำหรับโหมดสว่าง
  Color get lightBgColor => backgroundPresets[backgroundPresetIndex].lightColor;

  /// สีพื้นหลังที่เลือกสำหรับโหมดมืด
  Color get darkBgColor => backgroundPresets[backgroundPresetIndex].darkColor;

  SettingsState copyWith({
    FontScale? fontScale,
    AppFont? appFont,
    AppThemeMode? themeMode,
    int? backgroundPresetIndex,
    String? localeCode,
  }) {
    return SettingsState(
      fontScale: fontScale ?? this.fontScale,
      appFont: appFont ?? this.appFont,
      themeMode: themeMode ?? this.themeMode,
      backgroundPresetIndex:
          backgroundPresetIndex ?? this.backgroundPresetIndex,
      localeCode: localeCode ?? this.localeCode,
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
    final savedLocale = box.get('localeCode', defaultValue: 'en') as String;
    // sync ภาษาให้ tr() ใช้ทันทีตั้งแต่เปิดแอป
    appLang = kSupportedLangs.contains(savedLocale) ? savedLocale : 'en';

    return SettingsState(
      fontScale: FontScale
          .values[savedScaleIndex.clamp(0, FontScale.values.length - 1)],
      appFont:
          AppFont.values[savedFontIndex.clamp(0, AppFont.values.length - 1)],
      themeMode: AppThemeMode
          .values[savedThemeIndex.clamp(0, AppThemeMode.values.length - 1)],
      backgroundPresetIndex:
          savedBgIndex.clamp(0, backgroundPresets.length - 1),
      localeCode: appLang,
    );
  }

  /// เปลี่ยนภาษา ('en' | 'th') — อัปเดต tr() ทั้งแอปทันที
  Future<void> setLocale(String code) async {
    if (!kSupportedLangs.contains(code)) return;
    final box = Hive.box(HiveBoxes.screenTimeSettings);
    await box.put('localeCode', code);
    appLang = code;
    state = state.copyWith(localeCode: code);
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
