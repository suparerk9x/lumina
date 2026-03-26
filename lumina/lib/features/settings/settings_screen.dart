import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../shared/storage/storage_service.dart';
import '../screen_time/screen_time_provider.dart';
import 'settings_provider.dart';

/// ไฟล์นี้เป็นหน้าตั้งค่าของแอป
/// ให้ผู้ใช้เลือกแบบตัวอักษร, ขนาดตัวอักษร, ดูข้อมูลแอป, และลบข้อมูลทั้งหมด

/// หน้าจอตั้งค่า แสดงตัวเลือกต่าง ๆ สำหรับปรับแต่งแอป
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ตั้งค่า')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ─── ส่วนเลือกแบบตัวอักษร ────────────────────────────
          _FontFamilySection(
            current: settings.appFont,
            fontScale: settings.fontScale.value,
            onSelect: (font) {
              ref.read(settingsProvider.notifier).setAppFont(font);
            },
          ),
          const SizedBox(height: 20),

          // ─── ส่วนเลือกขนาดตัวอักษร ──────────────────────────────
          _FontScaleSection(
            current: settings.fontScale,
            fontFamily: settings.appFont.family,
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
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'เวอร์ชัน ${AppConstants.appVersion}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
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
// ส่วนเลือกแบบตัวอักษร (Font Family)
// ═══════════════════════════════════════════════════════════════

/// แสดงรายการฟอนต์ไทยให้ผู้ใช้เลือก พร้อมตัวอย่างตัวอักษร
class _FontFamilySection extends StatelessWidget {
  const _FontFamilySection({
    required this.current,
    required this.fontScale,
    required this.onSelect,
  });

  final AppFont current;
  final double fontScale;
  final ValueChanged<AppFont> onSelect;

  @override
  Widget build(BuildContext context) {
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
                    color: AppTheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.font_download_rounded,
                      color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'แบบตัวอักษร',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Font options
            ...AppFont.values.map((font) {
              final isSelected = current == font;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: isSelected
                      ? AppTheme.primary.withAlpha(15)
                      : Colors.white,
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
                              ? AppTheme.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Radio
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                              color: isSelected
                                  ? AppTheme.primary
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
                                        ? AppTheme.primary
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  font.description,
                                  style: TextStyle(
                                    fontFamily: font.family,
                                    fontSize: 15,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Preview
                          Text(
                            'กขค',
                            style: TextStyle(
                              fontFamily: font.family,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
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

/// แสดงตัวเลือกขนาดตัวอักษร (เล็ก, ปกติ, ใหญ่, ใหญ่มาก) พร้อมตัวอย่าง
class _FontScaleSection extends StatelessWidget {
  const _FontScaleSection({
    required this.current,
    required this.fontFamily,
    required this.onSelect,
  });

  final FontScale current;
  final String fontFamily;
  final ValueChanged<FontScale> onSelect;

  @override
  Widget build(BuildContext context) {
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
                    color: AppTheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.text_fields_rounded,
                      color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'ขนาดตัวอักษร',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
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
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'สวัสดี วันนี้เป็นอย่างไรบ้าง?',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 18 * current.value,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Scale options
            ...FontScale.values.map((scale) {
              final isSelected = current == scale;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: isSelected
                      ? AppTheme.primary.withAlpha(15)
                      : Colors.white,
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
                              ? AppTheme.primary
                              : Colors.grey.shade300,
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
                                    ? AppTheme.primary
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                              color: isSelected
                                  ? AppTheme.primary
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
                                  ? AppTheme.primary
                                  : AppTheme.textPrimary,
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
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
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
