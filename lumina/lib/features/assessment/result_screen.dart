import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import 'assessment_screen.dart';
import 'assessment_state.dart';

/// ไฟล์นี้แสดงหน้าจอผลลัพธ์หลังทำแบบประเมินสมองเสร็จ
/// แสดงคะแนนรวม, ระดับผลลัพธ์ (ดีมาก/ปานกลาง/ควรพบแพทย์),
/// คะแนนแยกแต่ละส่วน, และปุ่มทำแบบประเมินอีกครั้ง

/// คลาส AssessmentResultScreen แสดงผลการประเมินสมอง
/// บันทึกผลอัตโนมัติเมื่อเปิดหน้านี้ครั้งแรก
class AssessmentResultScreen extends ConsumerStatefulWidget {
  const AssessmentResultScreen({super.key});

  @override
  ConsumerState<AssessmentResultScreen> createState() =>
      _AssessmentResultScreenState();
}

/// State ภายในของหน้าจอผลลัพธ์
/// _saved ใช้แสดงข้อความ "บันทึกผลแล้ว" เมื่อบันทึกสำเร็จ
class _AssessmentResultScreenState
    extends ConsumerState<AssessmentResultScreen> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    // บันทึกผลการประเมินลงฐานข้อมูลเมื่อเปิดหน้านี้ครั้งแรก
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(assessmentProvider.notifier).saveResult();
      if (mounted) setState(() => _saved = true);
    });
  }

  /// สร้างหน้าจอแสดงผลการประเมิน
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);
    final score = state.totalScore;
    final max = state.maxScore;

    // กำหนดระดับผลลัพธ์ (ดีมาก/ปานกลาง/ควรพบแพทย์) จากคะแนน
    final tier = _getTier(score);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ผลการประเมิน'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // วงกลมแสดงคะแนนรวม (ตัวเลขใหญ่ตรงกลาง)
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tier.color.withAlpha(25),
                border: Border.all(color: tier.color, width: 4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$score',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: tier.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                        ),
                  ),
                  Text(
                    'จาก $max',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // อีโมจิและข้อความแสดงระดับผลลัพธ์
            Text(
              tier.emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              tier.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: tier.color,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              tier.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // แสดงคะแนนแยกแต่ละส่วนเป็นแถบกราฟ
            _ScoreBreakdown(
              label: 'วัน/เวลา',
              score: state.dateTimeScore,
              max: 2,
            ),
            _ScoreBreakdown(
              label: 'นับถอยหลัง',
              score: state.countdownScore,
              max: 5,
            ),
            _ScoreBreakdown(
              label: 'จำคำ',
              score: state.recallScore,
              max: 3,
            ),
            const SizedBox(height: 16),

            // ถ้าคะแนนต่ำ (<=4) แสดงคำแนะนำให้ปรึกษาแพทย์
            if (score <= 4) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withAlpha(15),
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: AppTheme.warning.withAlpha(50)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppTheme.warning, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ข้อแนะนำ',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppTheme.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'นี่เป็นเพียงการคัดกรองเบื้องต้น ไม่ใช่การวินิจฉัย '
                            'หากกังวล แนะนำให้ปรึกษาแพทย์เพื่อรับคำแนะนำเพิ่มเติม',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // แสดงข้อความ "บันทึกผลแล้ว" เมื่อบันทึกสำเร็จ
            if (_saved)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_rounded,
                        size: 18, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'บันทึกผลแล้ว',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                    ),
                  ],
                ),
              ),

            // ปุ่มทำแบบประเมินอีกครั้ง และปุ่มกลับหน้าหลัก
            ElevatedButton(
              onPressed: () {
                // รีเซ็ตแบบประเมินแล้วเริ่มใหม่
                ref.read(assessmentProvider.notifier).startAssessment();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const AssessmentScreen(),
                  ),
                );
              },
              child: const Text('ทำแบบประเมินอีกครั้ง'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('กลับหน้าหลัก'),
            ),
          ],
        ),
      ),
    );
  }

  /// กำหนดระดับผลลัพธ์จากคะแนน: >=8 ดีมาก, 5-7 ปานกลาง, <=4 ควรพบแพทย์
  _ResultTier _getTier(int score) {
    if (score >= 8) {
      return const _ResultTier(
        title: 'ดีมาก! สมองแข็งแรง',
        description: 'ผลการประเมินอยู่ในเกณฑ์ดี ควรทำกิจกรรมฝึกสมองอย่างสม่ำเสมอ',
        emoji: '💪',
        color: AppTheme.success,
      );
    } else if (score >= 5) {
      return const _ResultTier(
        title: 'ปานกลาง ควรฝึกเพิ่ม',
        description:
            'ผลการประเมินอยู่ในระดับปานกลาง แนะนำให้ฝึกสมองเป็นประจำทุกวัน',
        emoji: '🙂',
        color: AppTheme.warning,
      );
    } else {
      return const _ResultTier(
        title: 'ควรพบแพทย์ผู้เชี่ยวชาญ',
        description:
            'ผลการประเมินอยู่ในระดับที่ควรได้รับการดูแลเพิ่มเติม',
        emoji: '⚠️',
        color: AppTheme.error,
      );
    }
  }
}

/// คลาสเก็บข้อมูลระดับผลลัพธ์ (ชื่อ, คำอธิบาย, อีโมจิ, สี)
class _ResultTier {
  const _ResultTier({
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
  });

  final String title;
  final String description;
  final String emoji;
  final Color color;
}

// ─── แถวแสดงคะแนนแยกรายส่วน ────────────────────────────────

/// คลาส _ScoreBreakdown แสดงแถบกราฟคะแนนแต่ละส่วน
/// มีชื่อส่วน, แถบสี (เขียว/เหลือง/แดง ตามสัดส่วนคะแนน), และตัวเลขคะแนน
class _ScoreBreakdown extends StatelessWidget {
  const _ScoreBreakdown({
    required this.label,
    required this.score,
    required this.max,
  });

  final String label;
  final int score;
  final int max;

  @override
  Widget build(BuildContext context) {
    // คำนวณสัดส่วนคะแนน (0.0 - 1.0) สำหรับแสดงแถบกราฟ
    final ratio = max > 0 ? score / max : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                  ratio >= 0.7
                      ? AppTheme.success
                      : ratio >= 0.4
                          ? AppTheme.warning
                          : AppTheme.error,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$score/$max',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
