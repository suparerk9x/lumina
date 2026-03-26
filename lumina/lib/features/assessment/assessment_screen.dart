import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../shared/widgets/exit_dialog.dart';
import 'assessment_state.dart';
import 'result_screen.dart';
import 'steps/step_countdown.dart';
import 'steps/step_date_time.dart';
import 'steps/step_memorize.dart';
import 'steps/step_recall.dart';

/// ไฟล์นี้เป็นหน้าจอหลักของแบบประเมินสมอง
/// ควบคุมการแสดงผลแต่ละขั้นตอน (step) และแถบความคืบหน้า (progress bar)
/// มีทั้งหมด 4 ขั้นตอน: วัน/เวลา, จำคำ, นับถอยหลัง, จำคำได้ไหม

/// คลาส AssessmentScreen เป็นหน้าจอหลักที่แสดงแบบประเมินสมอง
/// ใช้ ConsumerStatefulWidget เพื่อเชื่อมต่อกับ Riverpod state management
class AssessmentScreen extends ConsumerStatefulWidget {
  const AssessmentScreen({super.key});

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

/// State ภายในของ AssessmentScreen
/// _navigated ใช้ป้องกันไม่ให้เปลี่ยนหน้าซ้ำหลายครั้ง
class _AssessmentScreenState extends ConsumerState<AssessmentScreen> {
  bool _navigated = false;

  /// สร้างหน้าจอแบบประเมิน มี AppBar, แถบความคืบหน้า, และเนื้อหาแต่ละขั้นตอน
  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูลสถานะปัจจุบันจาก provider (เช่น อยู่ step ไหน, คะแนนเท่าไหร่)
    final state = ref.watch(assessmentProvider);

    // ถ้าทำแบบประเมินครบแล้ว ให้ไปหน้าผลลัพธ์ (ทำแค่ครั้งเดียว)
    if (state.isComplete && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const AssessmentResultScreen(),
            ),
          );
        }
      });
    }

    return Scaffold(
      // AppBar: ถ้าอยู่ step แรก แสดงปุ่มปิด (X), ถ้าอยู่ step อื่นแสดงปุ่มย้อนกลับ
      appBar: AppBar(
        title: const Text('แบบประเมินสมอง'),
        leading: state.currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  ref.read(assessmentProvider.notifier).previousStep();
                },
              )
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () async {
                  // แสดง dialog ยืนยันว่าต้องการออกจริงหรือไม่
                  final exit = await showExitConfirmation(
                    context,
                    title: 'ออกจากแบบประเมิน?',
                    message: 'ผลที่ทำไปจะไม่ถูกบันทึก',
                  );
                  if (exit && context.mounted) Navigator.of(context).pop();
                },
              ),
      ),
      body: Column(
        children: [
          // ─── แถบความคืบหน้า แสดงว่าอยู่ขั้นตอนไหนแล้ว ───
          _ProgressBar(currentStep: state.currentStep),

          // ─── เนื้อหาแต่ละขั้นตอน (สลับหน้าด้วย animation) ───
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStep(state.currentStep),
            ),
          ),
        ],
      ),
    );
  }

  /// เลือก widget ที่จะแสดงตาม step ปัจจุบัน
  /// step 0 = ถามวัน/เวลา, step 1 = จำคำ, step 2 = นับถอยหลัง, step 3 = จำคำได้ไหม
  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return const StepDateTime(key: ValueKey(0));
      case 1:
        return const StepMemorize(key: ValueKey(1));
      case 2:
        return const StepCountdown(key: ValueKey(2));
      case 3:
        return const StepRecall(key: ValueKey(3));
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── แถบความคืบหน้าพร้อมชื่อแต่ละขั้นตอน ──────────────────

/// คลาส _ProgressBar แสดงแถบความคืบหน้าด้านบน
/// มีชื่อ step และแถบสีแสดงว่าทำถึงไหนแล้ว
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.currentStep});

  /// ขั้นตอนปัจจุบัน (0-3)
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // ชื่อแต่ละขั้นตอน: สีเขียว = ทำแล้ว, สีหลัก = กำลังทำ, สีเทา = ยังไม่ถึง
          Row(
            children: List.generate(4, (i) {
              final isDone = i < currentStep;
              final isCurrent = i == currentStep;
              return Expanded(
                child: Text(
                  AssessmentState.stepTitles[i],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w400,
                        color: isDone
                            ? AppTheme.success
                            : isCurrent
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                      ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          // แถบสีแสดงความคืบหน้า (เขียว = เสร็จ, สีหลัก = กำลังทำ, เทา = รอ)
          Row(
            children: List.generate(4, (i) {
              final isDone = i < currentStep;
              final isCurrent = i == currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    left: i == 0 ? 0 : 3,
                    right: i == 3 ? 0 : 3,
                  ),
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isDone
                        ? AppTheme.success
                        : isCurrent
                            ? AppTheme.primary
                            : Colors.grey.shade300,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
