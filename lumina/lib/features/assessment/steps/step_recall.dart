import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../assessment_state.dart';

/// ไฟล์นี้เป็นขั้นตอนที่ 4 (สุดท้าย) ของแบบประเมิน: จำคำได้ไหม
/// แสดงตัวเลือก 6 คำ (3 คำถูกที่เคยให้จำ + 3 คำหลอก)
/// ผู้ใช้เลือกได้ไม่เกิน 3 คำ เลือกถูก = ได้คะแนน (เต็ม 3)

/// คลาส StepRecall แสดงขั้นตอนทดสอบว่าจำคำจากขั้นตอนที่ 2 ได้หรือไม่
/// ใช้ ConsumerWidget เพราะไม่ต้องมี state ภายใน (ใช้ state จาก provider)
class StepRecall extends ConsumerWidget {
  const StepRecall({super.key});

  /// สร้างหน้าจอให้ผู้ใช้เลือกคำที่คิดว่าเคยจำได้
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assessmentProvider);
    final selected = state.selectedRecallWords; // คำที่ผู้ใช้เลือกแล้ว
    final options = state.recallOptions; // ตัวเลือกทั้ง 6 คำ

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.psychology_rounded,
            size: 48,
            color: AppTheme.primary.withAlpha(180),
          ),
          const SizedBox(height: 16),
          Text(
            'จำคำได้ไหม?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'เลือกคำที่คุณเห็นก่อนหน้านี้',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.warning.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'เลือกได้ 3 คำ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.warning,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 24),

          // การ์ดตัวเลือกคำ (กดเลือก/ยกเลิก จำกัดเลือกได้ 3 คำ)
          ...options.map((word) {
            final isSelected = selected.contains(word);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecallCard(
                word: word,
                isSelected: isSelected,
                onTap: () {
                  // ถ้าเลือกครบ 3 คำแล้ว ไม่ให้เลือกเพิ่ม แสดง SnackBar แจ้งเตือน
                  if (!isSelected && selected.length >= 3) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'เลือกได้ 3 คำเท่านั้น กดเอาออกก่อนเลือกใหม่',
                          style: TextStyle(fontSize: 18),
                        ),
                        backgroundColor: AppTheme.warning,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                    return;
                  }
                  ref.read(assessmentProvider.notifier).toggleRecallWord(word);
                },
              ),
            );
          }),

          const SizedBox(height: 16),

          // ปุ่มยืนยันคำตอบ (กดได้เมื่อเลือกอย่างน้อย 1 คำ)
          ElevatedButton(
            onPressed: selected.isNotEmpty
                ? () {
                    ref.read(assessmentProvider.notifier).submitRecall();
                  }
                : null,
            child: Text(
              selected.isEmpty
                  ? 'เลือกคำที่จำได้'
                  : 'ยืนยันคำตอบ (${selected.length}/3)',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── การ์ดตัวเลือกคำในขั้นตอนจำคำ ─────────────────────────

/// คลาส _RecallCard เป็นการ์ดแสดงตัวเลือกคำแต่ละคำ
/// มี checkbox ด้านซ้าย เมื่อเลือกจะเปลี่ยนสีและแสดงเครื่องหมายถูก
class _RecallCard extends StatelessWidget {
  const _RecallCard({
    required this.word,
    required this.isSelected,
    required this.onTap,
  });

  final String word;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppTheme.primary.withAlpha(15) : Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      elevation: isSelected ? 0 : 1,
      shadowColor: Colors.black.withAlpha(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // ช่อง checkbox แบบ animation (เปลี่ยนสีเมื่อเลือก)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isSelected ? AppTheme.primary : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 22)
                    : null,
              ),
              const SizedBox(width: 20),
              Text(
                word,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
