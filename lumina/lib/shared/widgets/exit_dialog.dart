import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// ไฟล์นี้เป็นฟังก์ชันแสดง dialog ยืนยันก่อนออกจากเกมหรือแบบประเมิน
/// ป้องกันผู้ใช้กดออกโดยไม่ตั้งใจ ข้อมูลที่ทำไปจะหายหมด

/// แสดง dialog ถามยืนยันก่อนออก คืนค่า true ถ้าผู้ใช้ยืนยัน, false ถ้ายกเลิก
Future<bool> showExitConfirmation(
  BuildContext context, {
  String title = 'ออกจากหน้านี้?',
  String message = 'ข้อมูลที่ทำไปจะหายหมด',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 18, color: AppTheme.textSecondary),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        SizedBox(
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ทำต่อ', style: TextStyle(fontSize: 18)),
          ),
        ),
        SizedBox(
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('ออก', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
