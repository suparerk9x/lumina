import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings.dart';
import '../../../core/theme.dart';
import '../assessment_state.dart';

/// ไฟล์นี้เป็นขั้นตอนที่ 3 ของแบบประเมิน: นับถอยหลัง
/// ให้ผู้ใช้นับจาก 20 ลบครั้งละ 3 (20, 17, 14, 11, 8) รวม 5 คำตอบ
/// มีแป้นตัวเลขให้กด คะแนนเต็ม 5 (ตอบถูก 1 ข้อ = 1 คะแนน)

/// คลาส StepCountdown แสดงแบบทดสอบนับถอยหลัง ลบครั้งละ 3
class StepCountdown extends ConsumerStatefulWidget {
  const StepCountdown({super.key});

  @override
  ConsumerState<StepCountdown> createState() => _StepCountdownState();
}

/// State ภายในของ StepCountdown
/// เก็บคำตอบผู้ใช้, คำถามปัจจุบัน, ตัวเลขที่กำลังพิมพ์
class _StepCountdownState extends ConsumerState<StepCountdown> {
  /// คำตอบที่ถูกต้อง: 20, 17, 14, 11, 8 (ลบทีละ 3)
  static const _expectedAnswers = [20, 17, 14, 11, 8];

  final List<int?> _userAnswers = List.filled(5, null); // คำตอบผู้ใช้ 5 ข้อ
  int _currentQuestion = 0; // ข้อที่กำลังตอบ (0-4)
  String _inputBuffer = ''; // ตัวเลขที่กำลังพิมพ์
  bool _isComplete = false; // ตอบครบ 5 ข้อหรือยัง

  /// เพิ่มตัวเลขที่กด (จำกัดไม่เกิน 3 หลัก)
  void _appendDigit(int digit) {
    if (_inputBuffer.length >= 3) return;
    setState(() => _inputBuffer += digit.toString());
  }

  /// ลบตัวเลขตัวสุดท้ายที่พิมพ์
  void _deleteDigit() {
    if (_inputBuffer.isEmpty) return;
    setState(() {
      _inputBuffer = _inputBuffer.substring(0, _inputBuffer.length - 1);
    });
  }

  /// ยืนยันคำตอบ บันทึกแล้วไปข้อถัดไป หรือจบถ้าตอบครบ 5 ข้อ
  void _confirmAnswer() {
    if (_inputBuffer.isEmpty) return;

    final answer = int.tryParse(_inputBuffer);
    setState(() {
      _userAnswers[_currentQuestion] = answer;
      _inputBuffer = '';

      if (_currentQuestion < 4) {
        _currentQuestion++;
      } else {
        _isComplete = true;
        _calculateAndSubmit();
      }
    });
  }

  /// คำนวณคะแนน: เทียบคำตอบผู้ใช้กับเฉลย ถูก 1 ข้อ = 1 คะแนน
  void _calculateAndSubmit() {
    int score = 0;
    for (int i = 0; i < _expectedAnswers.length; i++) {
      if (_userAnswers[i] == _expectedAnswers[i]) {
        score++;
      }
    }
    ref.read(assessmentProvider.notifier).setCountdownScore(score);
  }

  @override
  Widget build(BuildContext context) {
    if (_isComplete) {
      return _buildCompleteSummary(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // การ์ดคำอธิบาย: นับถอยหลังจาก 20 ลบครั้งละ 3
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            ),
            child: Column(
              children: [
                const Icon(Icons.calculate_rounded,
                    size: 36, color: AppTheme.primary),
                const SizedBox(height: 8),
                Text(
                  tr('assess.countdownInstruction'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // จุดแสดงความคืบหน้า 5 จุด (เขียว = ตอบแล้ว, สีหลัก = กำลังตอบ)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final isDone = i < _currentQuestion;
              final isCurrent = i == _currentQuestion;
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppTheme.success
                      : isCurrent
                          ? AppTheme.primary
                          : Colors.grey.shade300,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // แสดงคำถาม เช่น "เริ่มจากตัวเลขอะไร?" หรือ "20 ลบ 3 ได้เท่าไหร่?"
          Text(
            trp('assess.answerNumber', {'n': '${_currentQuestion + 1}'}),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          if (_currentQuestion == 0)
            Text(
              tr('assess.startingNumberQuestion'),
              style: Theme.of(context).textTheme.titleLarge,
            )
          else
            Text(
              trp('assess.minusThreeQuestion',
                  {'value': '${_expectedAnswers[_currentQuestion - 1]}'}),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          const SizedBox(height: 24),

          // ช่องแสดงตัวเลขที่กำลังพิมพ์
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 72),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.primary, width: 2),
            ),
            child: Text(
              _inputBuffer.isEmpty ? '—' : _inputBuffer,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: _inputBuffer.isEmpty
                        ? AppTheme.textSecondary
                        : AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 24),

          // แป้นตัวเลข 0-9 พร้อมปุ่มลบและยืนยัน
          _buildNumberPad(context),
        ],
      ),
    );
  }

  /// สร้างแป้นตัวเลข 3x4 (1-9, ลบ, 0, ยืนยัน)
  Widget _buildNumberPad(BuildContext context) {
    return Column(
      children: [
        // Row 1: 1 2 3
        _numberRow([1, 2, 3]),
        const SizedBox(height: 12),
        // Row 2: 4 5 6
        _numberRow([4, 5, 6]),
        const SizedBox(height: 12),
        // Row 3: 7 8 9
        _numberRow([7, 8, 9]),
        const SizedBox(height: 12),
        // Row 4: delete 0 confirm
        Row(
          children: [
            Expanded(
              child: _PadButton(
                onTap: _deleteDigit,
                child: const Icon(Icons.backspace_rounded, size: 28),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PadButton(
                label: '0',
                onTap: () => _appendDigit(0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PadButton(
                color: _inputBuffer.isNotEmpty
                    ? AppTheme.primary
                    : Colors.grey.shade300,
                onTap: _confirmAnswer,
                child: Icon(
                  Icons.check_rounded,
                  size: 32,
                  color: _inputBuffer.isNotEmpty
                      ? Colors.white
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// สร้างแถวตัวเลข 3 ปุ่ม (เช่น [1, 2, 3])
  Widget _numberRow(List<int> digits) {
    return Row(
      children: digits.map((d) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: d == digits.first ? 0 : 6,
              right: d == digits.last ? 0 : 6,
            ),
            child: _PadButton(
              label: '$d',
              onTap: () => _appendDigit(d),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// สร้างหน้าสรุปผลหลังตอบครบ 5 ข้อ แสดงว่าข้อไหนถูก/ผิด
  Widget _buildCompleteSummary(BuildContext context) {
    final score = ref.watch(assessmentProvider).countdownScore;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.success.withAlpha(20),
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 64, color: AppTheme.success),
                const SizedBox(height: 16),
                Text(
                  tr('assess.allAnsweredTitle'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  trp('assess.correctOutOfFive', {'score': '$score'}),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // แสดงรายการคำตอบทั้ง 5 ข้อ พร้อมเฉลย (เขียว = ถูก, แดง = ผิด)
          ...List.generate(5, (i) {
            final isCorrect = _userAnswers[i] == _expectedAnswers[i];
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isCorrect
                    ? AppTheme.success.withAlpha(15)
                    : AppTheme.error.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCorrect
                      ? AppTheme.success.withAlpha(60)
                      : AppTheme.error.withAlpha(60),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? AppTheme.success : AppTheme.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      trp('assess.yourAnswer', {'answer': '${_userAnswers[i]}'}),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    trp('assess.correctAnswer',
                        {'answer': '${_expectedAnswers[i]}'}),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(assessmentProvider.notifier).nextStep();
            },
            child: Text(tr('assess.nextQuestion')),
          ),
        ],
      ),
    );
  }
}

// ─── ปุ่มบนแป้นตัวเลข ──────────────────────────────────────

/// คลาส _PadButton เป็นปุ่มกดบนแป้นตัวเลข
/// ใช้ได้ทั้งปุ่มตัวเลข, ปุ่มลบ, และปุ่มยืนยัน
class _PadButton extends StatelessWidget {
  const _PadButton({
    this.label,
    this.child,
    this.color,
    required this.onTap,
  });

  final String? label;
  final Widget? child;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
      elevation: 1,
      shadowColor: Colors.black.withAlpha(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        child: Container(
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: child ??
              Text(
                label ?? '',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
        ),
      ),
    );
  }
}
