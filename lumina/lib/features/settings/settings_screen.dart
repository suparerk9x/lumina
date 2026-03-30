import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../shared/storage/storage_service.dart';
import '../screen_time/screen_time_provider.dart';
import 'settings_provider.dart';

/// หน้าจอตั้งค่า แสดงตัวเลือกต่าง ๆ สำหรับปรับแต่งแอป
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('ตั้งค่า')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ─── ส่วนเลือกโหมดธีม (สว่าง/มืด/ตามระบบ) ──────────
          _ThemeModeSection(
            current: settings.themeMode,
            isDark: isDark,
            onSelect: (mode) {
              ref.read(settingsProvider.notifier).setThemeMode(mode);
            },
          ),
          const SizedBox(height: 20),

          // ─── ส่วนเลือกสีพื้นหลัง ────────────────────────────
          _BackgroundColorSection(
            currentIndex: settings.backgroundPresetIndex,
            isDark: isDark,
            onSelect: (index) {
              ref.read(settingsProvider.notifier).setBackgroundPreset(index);
            },
          ),
          const SizedBox(height: 20),

          // ─── ส่วนเลือกแบบตัวอักษร ────────────────────────────
          _FontFamilySection(
            current: settings.appFont,
            fontScale: settings.fontScale.value,
            isDark: isDark,
            onSelect: (font) {
              ref.read(settingsProvider.notifier).setAppFont(font);
            },
          ),
          const SizedBox(height: 20),

          // ─── ส่วนเลือกขนาดตัวอักษร ──────────────────────────────
          _FontScaleSection(
            current: settings.fontScale,
            fontFamily: settings.appFont.family,
            isDark: isDark,
            onSelect: (scale) {
              ref.read(settingsProvider.notifier).setFontScale(scale);
            },
          ),
          const SizedBox(height: 24),

          // ─── ข้อมูลแอป ───────────────────────────────
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    'Lumina',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'แอปฝึกสมองสำหรับผู้สูงอายุ',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'เวอร์ชัน ${AppConstants.appVersion}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ─── ส่วนลบข้อมูลทั้งหมด ─────────────────────────────
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: AppTheme.error, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'จัดการข้อมูล',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text('ลบข้อมูลทั้งหมด?'),
                            content: const Text(
                              'คะแนนประเมิน คะแนนเกม และการตั้งค่าจะถูกลบหมด',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('ยกเลิก'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.error,
                                ),
                                child: const Text('ลบทั้งหมด'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await StorageService().clearAllData();
                          ref
                              .read(screenTimeProvider.notifier)
                              .clearWeekHistory();
                          ref
                              .read(screenTimeProvider.notifier)
                              .resetTodayUsage();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('ลบข้อมูลเรียบร้อยแล้ว',
                                    style: TextStyle(fontSize: 18)),
                                backgroundColor: AppTheme.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                      ),
                      child: const Text('ลบข้อมูลทั้งหมด'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ส่วนเลือกโหมดธีม (Theme Mode)
// ═══════════════════════════════════════════════════════════════

class _ThemeModeSection extends StatelessWidget {
  const _ThemeModeSection({
    required this.current,
    required this.isDark,
    required this.onSelect,
  });

  final AppThemeMode current;
  final bool isDark;
  final ValueChanged<AppThemeMode> onSelect;

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        isDark ? AppTheme.darkPrimary : AppTheme.primary;
    final textColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final secondaryTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.palette_rounded,
                      color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'โหมดธีม',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: AppThemeMode.values.map((mode) {
                final isSelected = current == mode;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: mode != AppThemeMode.values.last ? 10 : 0,
                    ),
                    child: Material(
                      color: isSelected
                          ? primaryColor.withAlpha(15)
                          : cardBg,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => onSelect(mode),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : (isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                mode.icon,
                                size: 28,
                                color: isSelected
                                    ? primaryColor
                                    : secondaryTextColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                mode.label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? primaryColor
                                      : textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ส่วนเลือกสีพื้นหลัง (Background Color)
// ═══════════════════════════════════════════════════════════════

class _BackgroundColorSection extends StatelessWidget {
  const _BackgroundColorSection({
    required this.currentIndex,
    required this.isDark,
    required this.onSelect,
  });

  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        isDark ? AppTheme.darkPrimary : AppTheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.format_paint_rounded,
                      color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'สีพื้นหลัง',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(backgroundPresets.length, (index) {
                final preset = backgroundPresets[index];
                final isSelected = currentIndex == index;
                final displayColor =
                    isDark ? preset.darkColor : preset.lightColor;

                return GestureDetector(
                  onTap: () => onSelect(index),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: displayColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : (isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400),
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withAlpha(60),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? Icon(Icons.check_rounded,
                                color: primaryColor, size: 24)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        preset.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? primaryColor
                              : Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ส่วนเลือกแบบตัวอักษร (Font Family)
// ═══════════════════════════════════════════════════════════════

class _FontFamilySection extends StatelessWidget {
  const _FontFamilySection({
    required this.current,
    required this.fontScale,
    required this.isDark,
    required this.onSelect,
  });

  final AppFont current;
  final double fontScale;
  final bool isDark;
  final ValueChanged<AppFont> onSelect;

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        isDark ? AppTheme.darkPrimary : AppTheme.primary;
    final textColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final secondaryTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.font_download_rounded,
                      color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'แบบตัวอักษร',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...AppFont.values.map((font) {
              final isSelected = current == font;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: isSelected
                      ? primaryColor.withAlpha(15)
                      : cardBg,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => onSelect(font),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 64),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor
                              : (isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : (isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade400),
                                width: 2,
                              ),
                              color: isSelected
                                  ? primaryColor
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  font.displayName,
                                  style: TextStyle(
                                    fontFamily: font.family,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? primaryColor
                                        : textColor,
                                  ),
                                ),
                                Text(
                                  font.description,
                                  style: TextStyle(
                                    fontFamily: font.family,
                                    fontSize: 15,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'กขค',
                            style: TextStyle(
                              fontFamily: font.family,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? primaryColor
                                  : secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ส่วนเลือกขนาดตัวอักษร (Font Scale)
// ═══════════════════════════════════════════════════════════════

class _FontScaleSection extends StatelessWidget {
  const _FontScaleSection({
    required this.current,
    required this.fontFamily,
    required this.isDark,
    required this.onSelect,
  });

  final FontScale current;
  final String fontFamily;
  final bool isDark;
  final ValueChanged<FontScale> onSelect;

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        isDark ? AppTheme.darkPrimary : AppTheme.primary;
    final textColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final secondaryTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.background;
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.text_fields_rounded,
                      color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'ขนาดตัวอักษร',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'ตัวอย่างข้อความ',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 20 * current.value,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'สวัสดี วันนี้เป็นอย่างไรบ้าง?',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 18 * current.value,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...FontScale.values.map((scale) {
              final isSelected = current == scale;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: isSelected
                      ? primaryColor.withAlpha(15)
                      : cardBg,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => onSelect(scale),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor
                              : (isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : (isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade400),
                                width: 2,
                              ),
                              color: isSelected
                                  ? primaryColor
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            scale.label,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 18 * scale.value,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? primaryColor
                                  : textColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'อ',
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 24 * scale.value,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? primaryColor
                                  : secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
