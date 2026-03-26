import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// ไฟล์นี้เป็น Widget แสดงเมื่อไม่มีข้อมูล (สถานะว่าง)
/// มี emoji ข้อความ และปุ่ม action (ถ้ามี)

/// Widget สำหรับแสดงหน้าว่างเมื่อยังไม่มีข้อมูล
/// มี emoji ใหญ่ ข้อความอธิบาย และปุ่มให้ผู้ใช้ทำอะไรบางอย่าง (optional)
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.emoji,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String emoji;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 20,
                  ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
