import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'flash_card_service.dart';

/// แสดง flash card รายวันเป็น pop-up (ข้อ 8)
Future<void> showFlashCardDialog(BuildContext context, FlashCard card) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _FlashCardDialog(card: card),
  );
}

class _FlashCardDialog extends StatefulWidget {
  const _FlashCardDialog({required this.card});

  final FlashCard card;

  @override
  State<_FlashCardDialog> createState() => _FlashCardDialogState();
}

class _FlashCardDialogState extends State<_FlashCardDialog> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.darkPrimary : AppTheme.primary;
    final card = widget.card;

    Uint8List? photo;
    if ((card.imageBase64 ?? '').isNotEmpty) {
      try {
        photo = base64Decode(card.imageBase64!);
      } catch (_) {
        photo = null;
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.style_rounded, color: primary, size: 26),
                const SizedBox(width: 8),
                Text('การ์ดวันนี้',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 20),

            if (photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  photo,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            if (photo != null) const SizedBox(height: 20),

            Text(
              card.question,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // เฉลย (เฉพาะการ์ดที่มีคำตอบ เช่น การ์ดรูปครอบครัว)
            if (card.answer != null) ...[
              if (_revealed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    card.answer!,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _revealed = true),
                    child: const Text('เฉลย'),
                  ),
                ),
            ] else
              Text(
                'ลองตอบในใจดูนะ',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ปิด'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
