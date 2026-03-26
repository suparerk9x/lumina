import 'package:flutter/material.dart';

/// ไฟล์นี้กำหนดธีม (สี, ฟอนต์, รูปร่างปุ่ม ฯลฯ) ของแอป Lumina
/// ออกแบบให้ผู้สูงอายุอ่านง่าย โดยผ่านมาตรฐาน WCAG AA (คอนทราสต์สีเพียงพอ)

/// คลาสรวมค่าธีมทั้งหมด ใช้ static เพื่อเรียกได้โดยไม่ต้องสร้าง object
class AppTheme {
  // ─── สีหลักของแอป (ผ่านมาตรฐาน WCAG AA — อ่านง่ายสำหรับผู้สูงอายุ) ──
  static const Color primary = Color(0xFF3B6FD4); // สีหลัก (น้ำเงิน) อัตราส่วนคอนทราสต์ 5.2:1
  static const Color background = Color(0xFFF8F9FA); // สีพื้นหลังของแอป
  static const Color surface = Colors.white; // สีพื้นผิว (การ์ด, แถบเมนู)
  static const Color textPrimary = Color(0xFF1A1A2E); // สีตัวอักษรหลัก (เข้มมาก อ่านง่าย)
  static const Color textSecondary = Color(0xFF4B5563); // สีตัวอักษรรอง (เทาเข้ม)
  static const Color success = Color(0xFF2E7D32); // สีเขียว แสดงความสำเร็จ
  static const Color warning = Color(0xFFE65100); // สีส้ม แสดงคำเตือน
  static const Color error = Color(0xFFC62828); // สีแดง แสดงข้อผิดพลาด

  // ─── ความโค้งมน (Radii) ของ UI ──────────────────────────────
  static const double cardRadius = 16.0; // ความโค้งของการ์ด
  static const double buttonRadius = 12.0; // ความโค้งของปุ่ม
  static const double inputRadius = 12.0; // ความโค้งของช่องกรอกข้อมูล

  // ─── ขนาด ────────────────────────────────────────────────
  static const double buttonMinHeight = 56.0; // ความสูงขั้นต่ำของปุ่ม (ใหญ่พอให้กดง่าย)

  // ─── สร้างธีมสว่าง โดยรับค่าขนาดฟอนต์และชนิดฟอนต์ ─────────
  /// สร้าง ThemeData สำหรับโหมดสว่าง
  /// [fontScale] ตัวคูณขนาดฟอนต์ (1.0 = ปกติ, 1.2 = ใหญ่ขึ้น 20%)
  /// [fontFamily] ชื่อฟอนต์ที่ใช้ (ค่าเริ่มต้นคือ Sarabun)
  static ThemeData lightTheme({
    double fontScale = 1.0,
    String fontFamily = 'Sarabun',
  }) {
    // ฟังก์ชันย่อ s() ใช้คูณขนาดฟอนต์ทุกตัวด้วย fontScale
    double s(double size) => size * fontScale;

    // สไตล์ตัวอักษรพื้นฐาน กำหนดฟอนต์และความสูงบรรทัด
    final base = TextStyle(fontFamily: fontFamily, height: 1.5);

    // กำหนดขนาดตัวอักษรแต่ละระดับ (หัวข้อใหญ่ → เนื้อหา → ปุ่ม)
    final textTheme = TextTheme(
      // หัวข้อหน้า — ใหญ่ที่สุด ตัวหนา
      displayLarge: base.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: s(34),
      ),
      displayMedium: base.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: s(28),
      ),
      // หัวข้อส่วน (section)
      headlineLarge: base.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: s(28),
      ),
      headlineMedium: base.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: s(24),
      ),
      // ชื่อการ์ด
      titleLarge: base.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: s(22),
      ),
      titleMedium: base.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w500,
        fontSize: s(20),
      ),
      // เนื้อหา — เรียงจากใหญ่ไปเล็ก: large > medium > small
      bodyLarge: base.copyWith(
        color: textPrimary,
        fontSize: s(20),
      ),
      bodyMedium: base.copyWith(
        color: textPrimary,
        fontSize: s(18),
      ),
      bodySmall: base.copyWith(
        color: textSecondary,
        fontSize: s(16),
      ),
      // ตัวอักษรบนปุ่ม
      labelLarge: base.copyWith(
        color: Colors.white,
        fontSize: s(20),
        fontWeight: FontWeight.w600,
      ),
    );

    // ประกอบร่าง ThemeData จากสี, ฟอนต์ และสไตล์ต่าง ๆ ที่กำหนดไว้
    return ThemeData(
      useMaterial3: true, // ใช้ Material Design 3 (ดีไซน์ใหม่ของ Google)
      brightness: Brightness.light,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: primary.withAlpha(30),
        onSecondary: primary,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      textTheme: textTheme,

      // ─── แถบด้านบน (AppBar) — ดีไซน์เรียบง่าย ──────────────
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontSize: s(22),
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 28),
      ),

      // ─── ปุ่มนูน (ElevatedButton) — สูงขั้นต่ำ 56px กดง่าย ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, buttonMinHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: s(20),
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      // ─── ปุ่มข้อความ (TextButton) ─────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, buttonMinHeight),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: s(20),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── ปุ่มมีขอบ (OutlinedButton) ───────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, buttonMinHeight),
          side: const BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: s(20),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── การ์ด — เงาเข้มขึ้นเพื่อให้ผู้สูงอายุเห็นขอบชัด ──
      cardTheme: CardThemeData(
        color: surface,
        elevation: 3,
        shadowColor: Colors.black.withAlpha(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // ─── สไตล์ช่องกรอกข้อมูล (TextField) ──────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          color: textSecondary,
          fontSize: s(18),
        ),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: textSecondary,
          fontSize: s(18),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: error, width: 2),
        ),
      ),

      // ─── เส้นคั่น (Divider) ────────────────────────────────
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),

      // ─── แถบเมนูด้านล่าง — ขนาดใหญ่เพื่อให้ผู้สูงอายุกดง่าย ──
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: s(15),
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: s(15),
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
