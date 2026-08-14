import 'package:flutter/material.dart';

/// ไฟล์นี้กำหนดธีม (สี, ฟอนต์, รูปร่างปุ่ม ฯลฯ) ของแอป Demenish AI
/// ออกแบบให้ผู้สูงอายุอ่านง่าย โดยผ่านมาตรฐาน WCAG AA (คอนทราสต์สีเพียงพอ)

/// สีพื้นหลังที่ผู้ใช้เลือกได้ (preset) พร้อมชื่อภาษาไทย
class BackgroundPreset {
  const BackgroundPreset({
    required this.name,
    required this.lightColor,
    required this.darkColor,
  });

  final String name;
  final Color lightColor;
  final Color darkColor;
}

/// รายการสีพื้นหลังให้เลือก 8 แบบ
const List<BackgroundPreset> backgroundPresets = [
  BackgroundPreset(name: 'ค่าเริ่มต้น', lightColor: Color(0xFFF0F5F5), darkColor: Color(0xFF162224)),
  BackgroundPreset(name: 'ครีม', lightColor: Color(0xFFFFF8E7), darkColor: Color(0xFF2A2520)),
  BackgroundPreset(name: 'ฟ้าอ่อน', lightColor: Color(0xFFE8F4FD), darkColor: Color(0xFF1A2332)),
  BackgroundPreset(name: 'เขียวอ่อน', lightColor: Color(0xFFE8F5E9), darkColor: Color(0xFF1A2E1A)),
  BackgroundPreset(name: 'ชมพูอ่อน', lightColor: Color(0xFFFCE4EC), darkColor: Color(0xFF2E1A22)),
  BackgroundPreset(name: 'ม่วงอ่อน', lightColor: Color(0xFFF3E5F5), darkColor: Color(0xFF261A2E)),
  BackgroundPreset(name: 'ส้มอ่อน', lightColor: Color(0xFFFFF3E0), darkColor: Color(0xFF2E2518)),
  BackgroundPreset(name: 'เทาอ่อน', lightColor: Color(0xFFECEFF1), darkColor: Color(0xFF222528)),
];

/// คลาสรวมค่าธีมทั้งหมด ใช้ static เพื่อเรียกได้โดยไม่ต้องสร้าง object
class AppTheme {
  // ─── สีหลักของแอป (โทน Teal/Mint — WCAG AA) ──────────────
  static const Color primary = Color(0xFF3D7F80); // Teal เข้ม — contrast 5.0:1 บนขาว
  static const Color secondary = Color(0xFF5BC5A7); // Mint สด — accent, progress bar
  static const Color background = Color(0xFFF0F5F5); // พื้นหลังค่าเริ่มต้น (เขียวอ่อนมาก)
  static const Color surface = Colors.white; // พื้นผิว (การ์ด, แถบเมนู)
  static const Color textPrimary = Color(0xFF2D3436); // ตัวอักษรหลัก (เข้มมาก อ่านง่าย)
  static const Color textSecondary = Color(0xFF6B7B8A); // ตัวอักษรรอง (เทาเข้ม)
  static const Color success = Color(0xFF1B7A3D); // เขียวเข้ม (แยกจาก teal ชัดเจน)
  static const Color warning = Color(0xFFE65100); // ส้ม
  static const Color error = Color(0xFFC62828); // แดง

  // ─── สีสำหรับโหมดมืด ──────────────────────────────────
  static const Color darkPrimary = Color(0xFF6FD5B7); // Mint สว่าง — เด่นบนพื้นมืด
  static const Color darkSecondary = Color(0xFF4A8B8C); // Teal — accent ในโหมดมืด
  static const Color darkBackground = Color(0xFF162224); // พื้นหลังมืด (เขียวคล้ำ)
  static const Color darkSurface = Color(0xFF1E2D2F); // พื้นผิวมืด (เขียวเข้ม)
  static const Color darkTextPrimary = Color(0xFFE8EFF0); // ตัวอักษรหลักมืด
  static const Color darkTextSecondary = Color(0xFFA0B0B8); // ตัวอักษรรองมืด

  // ─── ความโค้งมน (Radii) ──────────────────────────────
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double inputRadius = 12.0;

  // ─── ขนาด ────────────────────────────────────────────────
  static const double buttonMinHeight = 56.0;

  // ─── สร้างธีมสว่าง ─────────────────────────────────────────
  static ThemeData lightTheme({
    double fontScale = 1.0,
    String fontFamily = 'Sarabun',
    Color? bgColor,
  }) {
    double s(double size) => size * fontScale;

    final base = TextStyle(fontFamily: fontFamily, height: 1.5);

    final textTheme = TextTheme(
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
      labelLarge: base.copyWith(
        color: Colors.white,
        fontSize: s(20),
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: bgColor ?? background,
      textTheme: textTheme,

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

      cardTheme: CardThemeData(
        color: surface,
        elevation: 3,
        shadowColor: Colors.black.withAlpha(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

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

      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),

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

  // ─── สร้างธีมมืด ─────────────────────────────────────────────
  static ThemeData darkTheme({
    double fontScale = 1.0,
    String fontFamily = 'Sarabun',
    Color? bgColor,
  }) {
    double s(double size) => size * fontScale;

    final base = TextStyle(fontFamily: fontFamily, height: 1.5);

    final textTheme = TextTheme(
      displayLarge: base.copyWith(
        color: darkTextPrimary,
        fontWeight: FontWeight.bold,
        fontSize: s(34),
      ),
      displayMedium: base.copyWith(
        color: darkTextPrimary,
        fontWeight: FontWeight.bold,
        fontSize: s(28),
      ),
      headlineLarge: base.copyWith(
        color: darkTextPrimary,
        fontWeight: FontWeight.bold,
        fontSize: s(28),
      ),
      headlineMedium: base.copyWith(
        color: darkTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: s(24),
      ),
      titleLarge: base.copyWith(
        color: darkTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: s(22),
      ),
      titleMedium: base.copyWith(
        color: darkTextPrimary,
        fontWeight: FontWeight.w500,
        fontSize: s(20),
      ),
      bodyLarge: base.copyWith(
        color: darkTextPrimary,
        fontSize: s(20),
      ),
      bodyMedium: base.copyWith(
        color: darkTextPrimary,
        fontSize: s(18),
      ),
      bodySmall: base.copyWith(
        color: darkTextSecondary,
        fontSize: s(16),
      ),
      labelLarge: base.copyWith(
        color: Colors.white,
        fontSize: s(20),
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.dark(
        primary: darkPrimary,
        onPrimary: Color(0xFF162224),
        secondary: darkSecondary,
        onSecondary: Colors.white,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        error: error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: bgColor ?? darkBackground,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: darkTextPrimary,
          fontSize: s(22),
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary, size: 28),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Color(0xFF162224),
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

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          minimumSize: const Size(double.infinity, buttonMinHeight),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: s(20),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          minimumSize: const Size(double.infinity, buttonMinHeight),
          side: BorderSide(color: darkPrimary, width: 1.5),
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

      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 3,
        shadowColor: Colors.black.withAlpha(80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          color: darkTextSecondary,
          fontSize: s(18),
        ),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: darkTextSecondary,
          fontSize: s(18),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: darkPrimary, width: 2),
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

      dividerTheme: DividerThemeData(
        color: Colors.grey.shade800,
        thickness: 1,
        space: 1,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkPrimary,
        unselectedItemColor: darkTextSecondary,
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
