import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';

/// ไฟล์นี้เป็นฟังก์ชันแสดง dialog ยืนยันก่อนออกจากเกมหรือแบบประเมิน
/// ป้องกันผู้ใช้กดออกโดยไม่ตั้งใจ ข้อมูลที่ทำไปจะหายหมด

/// แสดง dialog ถามยืนยันก่อนออก คืนค่า true ถ้าผู้ใช้ยืนยัน, false ถ้ายกเลิก
Future<bool> showExitConfirmation(
  BuildContext context, {
  String? title,
  String? message,
}) async {
  final t = title ?? tr('common.exitTitle');
  final m = message ?? tr('common.exitMessage');
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      title: Text(
        t,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
      ),
      content: Text(
        m,
        style: const TextStyle(fontSize: 18, color: AppTheme.textSecondary),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        SizedBox(
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr('common.continue'),
                style: const TextStyle(fontSize: 18)),
          ),
        ),
        SizedBox(
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text(tr('common.exit'),
                style: const TextStyle(fontSize: 18)),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
