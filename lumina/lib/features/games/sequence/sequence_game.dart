import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/exit_dialog.dart';
import 'sequence_data.dart';
import 'sequence_provider.dart';
import 'sequence_result.dart';

/// ไฟล์นี้เป็น UI หลักของเกม "เรียงลำดับ"
/// ผู้ใช้จะเห็นการ์ด 4 ใบที่สลับลำดับ แล้วต้องแตะเรียงลำดับให้ถูกต้อง
/// เช่น เรียงกิจวัตรประจำวัน หรือเรียงขนาดสัตว์จากเล็กไปใหญ่

/// Widget หลักของเกมเรียงลำดับ
class SequenceGame extends ConsumerStatefulWidget {
  const SequenceGame({super.key});

  @override
  ConsumerState<SequenceGame> createState() => _SequenceGameState();
}

class _SequenceGameState extends ConsumerState<SequenceGame> {
  bool _navigated = false; // ป้องกันการนำทางไปหน้าผลลัพธ์ซ้ำ

  /// เริ่มต้น: สุ่มสร้างโจทย์ทุกข้อหลัง Widget ถูกสร้าง
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sequenceGameProvider.notifier).startGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sequenceGameProvider); // อ่านสถานะเกมปัจจุบัน

    // เมื่อเล่นครบทุกข้อแล้ว นำทางไปหน้าผลคะแนน (ทำครั้งเดียว)
    if (state.isComplete && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SequenceResult()),
          );
        }
      });
      return const SizedBox.shrink();
    }

    final round = state.current; // ข้อมูลรอบปัจจุบัน
    if (round == null) {
      // ยังไม่มีข้อมูล แสดงตัวหมุนรอ
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ตรวจว่ากำลังแสดงผลถูก/ผิดอยู่หรือไม่
    final showFeedback = state.roundResult != RoundResult.none;

    return Scaffold(
      appBar: AppBar(
        title: const Text('เรียงลำดับ'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () async {
            final exit = await showExitConfirmation(context,
                title: 'ออกจากเกม?', message: 'คะแนนจะไม่ถูกบันทึก');
            if (exit && context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── แถบคะแนนและแถบความคืบหน้า ─────────────────────
            _ProgressHeader(
              score: state.score,
              current: state.currentRound,
              total: state.totalRounds,
            ),

            // ─── หัวข้อรอบนี้และคำแนะนำ ───────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      round.datasetTitle,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'แตะตามลำดับที่ถูกต้อง',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── ตาราง 2x2 แสดงการ์ดตัวเลือกที่สุ่มลำดับ ────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: round.scrambled.map((item) {
                    final tapIndex = state.tapIndexOf(item); // ลำดับที่ผู้ใช้แตะ
                    final isTapped = tapIndex >= 0; // ถูกแตะแล้วหรือยัง

                    // หาตำแหน่งที่ถูกต้องของรายการนี้ (สำหรับแสดงเฉลย)
                    int? correctIndex;
                    if (showFeedback) {
                      correctIndex = round.correctOrder
                          .indexWhere((c) => c.label == item.label);
                    }

                    return _SequenceCard(
                      item: item,
                      tapNumber: isTapped ? tapIndex + 1 : null,
                      showFeedback: showFeedback,
                      isCorrectPosition: showFeedback &&
                          isTapped &&
                          tapIndex == correctIndex,
                      correctNumber:
                          showFeedback ? (correctIndex! + 1) : null,
                      roundResult: state.roundResult,
                      onTap: showFeedback
                          ? null
                          : () => ref
                              .read(sequenceGameProvider.notifier)
                              .tapItem(item),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ─── ปุ่มด้านล่าง (ส่งคำตอบ / ข้อถัดไป) ───────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: showFeedback
                  ? _buildFeedbackFooter(context, state)
                  : _buildInputFooter(context, state),
            ),
          ],
        ),
      ),
    );
  }

  /// สร้างส่วนล่างตอนกำลังเลือกคำตอบ — มีปุ่มย้อนกลับและปุ่มส่งคำตอบ
  Widget _buildInputFooter(BuildContext context, SequenceGameState state) {
    return Column(
      children: [
        // ปุ่มย้อนกลับ (ยกเลิกการแตะล่าสุด)
        if (state.tappedOrder.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextButton.icon(
              onPressed: () {
                ref.read(sequenceGameProvider.notifier).undoLastTap();
              },
              icon: const Icon(Icons.undo_rounded),
              label: const Text('ย้อนกลับ'),
            ),
          ),
        // ปุ่มส่งคำตอบ (จะกดได้ก็ต่อเมื่อแตะครบทุกรายการแล้ว)
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: state.allTapped
                ? () {
                    ref.read(sequenceGameProvider.notifier).submitAnswer();
                  }
                : null,
            child: Text(
              state.allTapped
                  ? 'ส่งคำตอบ'
                  : 'แตะ ${state.itemsInRound - state.tappedOrder.length} รายการ',
            ),
          ),
        ),
      ],
    );
  }

  /// สร้างส่วนล่างตอนแสดงผลถูก/ผิด — มีข้อความบอกผลและปุ่มไปข้อถัดไป
  Widget _buildFeedbackFooter(
      BuildContext context, SequenceGameState state) {
    final isCorrect = state.roundResult == RoundResult.correct;

    return Column(
      children: [
        // กล่องข้อความแสดงผล "ถูกต้อง" หรือ "ลำดับยังไม่ถูก"
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCorrect
                ? AppTheme.success.withAlpha(20)
                : AppTheme.error.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCorrect
                  ? AppTheme.success.withAlpha(60)
                  : AppTheme.error.withAlpha(60),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: isCorrect ? AppTheme.success : AppTheme.error,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                isCorrect ? 'ถูกต้อง! ✓' : 'ลำดับยังไม่ถูก ดูเฉลยด้านบน',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isCorrect ? AppTheme.success : AppTheme.error,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ปุ่มไปข้อถัดไป หรือดูผลคะแนน (ถ้าเป็นข้อสุดท้าย)
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              ref.read(sequenceGameProvider.notifier).nextRound();
            },
            child: Text(
              state.currentRound < state.totalRounds - 1
                  ? 'ข้อถัดไป'
                  : 'ดูผลคะแนน',
            ),
          ),
        ),
      ],
    );
  }
}

// ─── แถบแสดงคะแนนและความคืบหน้า ────────────────────────────────────────

/// แถบด้านบนแสดงคะแนน (เช่น 2/5) และแถบสีแสดงว่าทำถึงข้อไหนแล้ว
class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.score,
    required this.current,
    required this.total,
  });

  final int score;
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$score/$total',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: List.generate(total, (i) {
                return Expanded(
                  child: Container(
                    height: 6,
                    margin: EdgeInsets.only(
                      left: i == 0 ? 0 : 3,
                      right: i == total - 1 ? 0 : 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: i < current
                          ? AppTheme.success
                          : i == current
                              ? AppTheme.primary
                              : Colors.grey.shade300,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── การ์ดตัวเลือกในเกมเรียงลำดับ ──────────────────────────────────────────

/// การ์ดแสดง Emoji + ชื่อรายการ 1 ใบ
/// แสดงหมายเลขลำดับที่ผู้ใช้แตะ และเปลี่ยนสีตามผลถูก/ผิด
class _SequenceCard extends StatelessWidget {
  const _SequenceCard({
    required this.item,
    required this.tapNumber,
    required this.showFeedback,
    required this.isCorrectPosition,
    required this.correctNumber,
    required this.roundResult,
    required this.onTap,
  });

  final SequenceItem item; // ข้อมูลรายการ (ชื่อ + emoji)
  final int? tapNumber; // ลำดับที่ผู้ใช้แตะ (null = ยังไม่แตะ)
  final bool showFeedback;
  final bool isCorrectPosition;
  final int? correctNumber;
  final RoundResult roundResult;
  final VoidCallback? onTap;

  /// คำนวณสีขอบ: แตะแล้ว = สีหลัก, ถูก = เขียว, ผิด = แดง
  Color get _borderColor {
    if (!showFeedback) {
      return tapNumber != null ? AppTheme.primary : Colors.grey.shade300;
    }
    if (roundResult == RoundResult.correct) return AppTheme.success;
    // ตอบผิด: แสดงสีตามว่าตำแหน่งนี้ถูกหรือผิด
    return isCorrectPosition ? AppTheme.success : AppTheme.error;
  }

  /// คำนวณสีพื้นหลัง: ปกติ = ขาว, ถูก = เขียวอ่อน, ผิด = แดงอ่อน
  Color get _bgColor {
    if (!showFeedback) {
      return tapNumber != null
          ? AppTheme.primary.withAlpha(10)
          : Colors.white;
    }
    if (roundResult == RoundResult.correct) {
      return AppTheme.success.withAlpha(15);
    }
    return isCorrectPosition
        ? AppTheme.success.withAlpha(15)
        : AppTheme.error.withAlpha(10);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bgColor,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      elevation: showFeedback ? 0 : 1,
      shadowColor: Colors.black.withAlpha(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Container(
          constraints: const BoxConstraints(minHeight: 80),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: _borderColor,
              width: (tapNumber != null || showFeedback) ? 2.5 : 1.5,
            ),
          ),
          child: Stack(
            children: [
              // เนื้อหาหลัก — Emoji และชื่อรายการ
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 40)),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      style:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ],
                ),
              ),

              // วงกลมแสดงลำดับที่ผู้ใช้แตะ (ก่อนส่งคำตอบ)
              if (tapNumber != null && !showFeedback)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _OrderBadge(
                    number: tapNumber!,
                    color: AppTheme.primary,
                  ),
                ),

              // แสดงหมายเลขลำดับที่ถูกต้อง (ตอนแสดงเฉลย)
              if (showFeedback && correctNumber != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _OrderBadge(
                    number: correctNumber!,
                    color: roundResult == RoundResult.correct
                        ? AppTheme.success
                        : isCorrectPosition
                            ? AppTheme.success
                            : AppTheme.error,
                  ),
                ),

              // ไอคอนถูก/ผิด (เครื่องหมายถูกสีเขียว หรือกากบาทสีแดง)
              if (showFeedback && tapNumber != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Icon(
                    isCorrectPosition || roundResult == RoundResult.correct
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: isCorrectPosition ||
                            roundResult == RoundResult.correct
                        ? AppTheme.success
                        : AppTheme.error,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── วงกลมแสดงหมายเลขลำดับ ─────────────────────────────────────

/// วงกลมเล็กมุมขวาบนของการ์ด แสดงตัวเลขลำดับ (1, 2, 3, 4)
class _OrderBadge extends StatelessWidget {
  const _OrderBadge({required this.number, required this.color});

  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
