import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/storage/hive_boxes.dart';

/// ไฟล์นี้จัดการ state ของหน้าตั้งค่า
/// เก็บข้อมูลฟอนต์ที่เลือก และขนาดตัวอักษร ใช้ Hive บันทึกค่าลงเครื่อง

/// ระดับขนาดตัวอักษร สำหรับผู้ใช้ที่ต้องการตัวอักษรใหญ่ขึ้น
/// แต่ละระดับมีค่าตัวคูณ (value) และชื่อภาษาไทย (label)
enum FontScale {
  small(0.9, 'เล็ก'),
  normal(1.0, 'ปกติ'),
  large(1.2, 'ใหญ่'),
  extraLarge(1.4, 'ใหญ่มาก');

  const FontScale(this.value, this.label);

  final double value;
  final String label;
}

/// ฟอนต์ไทยที่ใช้ได้ในแอป แต่ละตัวมีชื่อ family, ชื่อแสดง, และคำอธิบาย
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

/// โมเดลเก็บสถานะการตั้งค่า: ขนาดตัวอักษร และแบบตัวอักษร
class SettingsState {
  const SettingsState({
    this.fontScale = FontScale.normal,
    this.appFont = AppFont.sarabun,
  });

  final FontScale fontScale; // ขนาดตัวอักษรที่เลือก
  final AppFont appFont; // แบบตัวอักษรที่เลือก

  /// สร้างสำเนาของ state พร้อมเปลี่ยนค่าบางตัว
  SettingsState copyWith({FontScale? fontScale, AppFont? appFont}) {
    return SettingsState(
      fontScale: fontScale ?? this.fontScale,
      appFont: appFont ?? this.appFont,
    );
  }
}

/// ตัวจัดการ logic ของหน้าตั้งค่า: โหลดและบันทึกค่าฟอนต์ลง Hive
class SettingsNotifier extends Notifier<SettingsState> {
  /// โหลดค่าที่บันทึกไว้จาก Hive เป็น state เริ่มต้น
  @override
  SettingsState build() {
    final box = Hive.box(HiveBoxes.screenTimeSettings);
    final savedScaleIndex = box.get('fontScaleIndex', defaultValue: 1) as int;
    final savedFontIndex = box.get('fontFamilyIndex', defaultValue: 0) as int;

    return SettingsState(
      fontScale: FontScale
          .values[savedScaleIndex.clamp(0, FontScale.values.length - 1)],
      appFont:
          AppFont.values[savedFontIndex.clamp(0, AppFont.values.length - 1)],
    );
  }

  /// บันทึกขนาดตัวอักษรที่เลือกลง Hive แล้วอัปเดต state
  Future<void> setFontScale(FontScale scale) async {
    final box = Hive.box(HiveBoxes.screenTimeSettings);
    await box.put('fontScaleIndex', scale.index);
    state = state.copyWith(fontScale: scale);
  }

  /// บันทึกแบบตัวอักษรที่เลือกลง Hive แล้วอัปเดต state
  Future<void> setAppFont(AppFont font) async {
    final box = Hive.box(HiveBoxes.screenTimeSettings);
    await box.put('fontFamilyIndex', font.index);
    state = state.copyWith(appFont: font);
  }
}

/// Provider หลักที่ UI ใช้เข้าถึง state และ notifier ของหน้าตั้งค่า
final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
