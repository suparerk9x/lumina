import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings.dart';
import '../../../core/theme.dart';
import '../assessment_state.dart';

/// ไฟล์นี้เป็นขั้นตอนที่ 2 ของแบบประเมิน: จำคำ 3 คำ
/// แสดงคำ 3 คำให้ผู้ใช้จำภายในเวลาที่กำหนด (10 วินาที)
/// มี 3 เฟส: หน้าเตรียมพร้อม -> แสดงคำพร้อมนาฬิกาจับเวลา -> หมดเวลาไปต่อ
/// ขั้นตอนนี้ไม่มีคะแนน แต่คำที่จำจะถูกถามอีกครั้งใน step สุดท้าย

/// คลาส StepMemorize แสดงคำ 3 คำให้ผู้ใช้จำ พร้อมตัวจับเวลาแบบวงกลม
class StepMemorize extends ConsumerStatefulWidget {
  const StepMemorize({super.key});

  @override
  ConsumerState<StepMemorize> createState() => _StepMemorizeState();
}

/// State ภายในของ StepMemorize
/// ใช้ SingleTickerProviderStateMixin สำหรับ animation ของนาฬิกาวงกลม
class _StepMemorizeState extends ConsumerState<StepMemorize>
    with SingleTickerProviderStateMixin {
  late final int _totalSeconds; // เวลาจำคำทั้งหมด (วินาที) — ปรับตามช่วงอายุ

  late AnimationController _timerController; // ควบคุม animation วงกลม
  late Timer _countdownTimer; // ตัวนับถอยหลังทุก 1 วินาที
  late int _secondsLeft; // เวลาที่เหลือ
  bool _wordsHidden = false; // ซ่อนคำแล้วหรือยัง (หมดเวลา)
  bool _ready = false; // ผู้ใช้กดเริ่มแล้วหรือยัง

  @override
  void initState() {
    super.initState();
    // อ่านเวลาจำที่ปรับตามช่วงอายุจาก state (ข้อ 5)
    _totalSeconds = ref.read(assessmentProvider).memorizeSeconds;
    _secondsLeft = _totalSeconds;
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );
  }

  /// เริ่มจับเวลา เมื่อผู้ใช้กดปุ่ม "พร้อมแล้ว เริ่มเลย!"
  void _startTimer() {
    setState(() => _ready = true);
    _timerController.forward();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _wordsHidden = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    if (_ready) _countdownTimer.cancel();
    super.dispose();
  }

  /// เปลี่ยนสีนาฬิกาตามเวลาที่เหลือ: แดง (<=3), เหลือง (<=5), ปกติ
  Color get _timerColor {
    if (_secondsLeft <= 3) return AppTheme.error;
    if (_secondsLeft <= 5) return AppTheme.warning;
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final words = ref.watch(assessmentProvider).memorizeWords;

    // เฟส 0: หน้าเตรียมพร้อม (ยังไม่เริ่มจับเวลา)
    if (!_ready) {
      return _buildReadyScreen(context);
    }

    // เฟส 1: แสดงคำให้จำ พร้อมนาฬิกานับถอยหลัง
    if (!_wordsHidden) {
      return _buildMemorizeScreen(context, words);
    }

    // เฟส 2: หมดเวลาแล้ว แสดงปุ่มไปต่อ
    return _buildDoneScreen(context);
  }

  // ─── เฟส 0: หน้าเตรียมพร้อมก่อนเริ่มจำคำ ─────────────────

  /// สร้างหน้าเตรียมพร้อม แสดงคำอธิบายและปุ่มเริ่ม
  Widget _buildReadyScreen(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_rounded,
                  size: 64, color: AppTheme.primary),
            ),
            const SizedBox(height: 28),
            Text(
              tr('assess.memorizeReadyTitle'),
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              trp('assess.memorizeReadyBody', {'seconds': '$_totalSeconds'}),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _startTimer,
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: Text(tr('assess.readyStartButton')),
            ),
          ],
        ),
      ),
    );
  }

  // ─── เฟส 1: แสดงคำให้จำพร้อมนาฬิกาวงกลมนับถอยหลัง ──────

  /// สร้างหน้าแสดงคำ 3 คำ พร้อมนาฬิกาจับเวลาแบบวงกลม
  Widget _buildMemorizeScreen(BuildContext context, List<String> words) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ── นาฬิกาวงกลมขนาดใหญ่แสดงเวลาที่เหลือ ──
          SizedBox(
            width: 140,
            height: 140,
            child: AnimatedBuilder(
              animation: _timerController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CircularTimerPainter(
                    progress: 1.0 - _timerController.value,
                    color: _timerColor,
                    backgroundColor: Colors.grey.shade200,
                    strokeWidth: 8,
                  ),
                  child: child,
                );
              },
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        fontFamily:
                            Theme.of(context).textTheme.bodyLarge?.fontFamily,
                        fontSize: _secondsLeft <= 3 ? 48 : 42,
                        fontWeight: FontWeight.bold,
                        color: _timerColor,
                      ),
                      child: Text('$_secondsLeft'),
                    ),
                    Text(
                      tr('assess.secondsLabel'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('assess.memorizeTheseWords'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),

          // ── การ์ดแสดงคำที่ต้องจำ (มี animation ค่อยๆ โผล่ขึ้นมาทีละคำ) ──
          ...words.asMap().entries.map((entry) {
            final index = entry.key;
            final word = entry.value;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + index * 200),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(
                      color: AppTheme.primary.withAlpha(80),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(20),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // วงกลมแสดงลำดับคำ (1, 2, 3)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        word,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // ข้อความเตือนเมื่อเหลือเวลาน้อยกว่า 3 วินาที
          if (_secondsLeft <= 3 && _secondsLeft > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.error.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_rounded,
                        color: AppTheme.error, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      tr('assess.almostOutOfTime'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── เฟส 2: หมดเวลาแล้ว ─────────────────────────────────────

  /// สร้างหน้าแจ้งว่าหมดเวลาแล้ว พร้อมปุ่มไปข้อถัดไป
  Widget _buildDoneScreen(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 64,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tr('assess.timeUpTitle'),
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              tr('assess.timeUpBody'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(assessmentProvider.notifier).nextStep();
              },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(tr('assess.nextQuestion')),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ตัววาดนาฬิกาวงกลม (CustomPainter) ─────────────────────

/// คลาส _CircularTimerPainter วาดวงกลมแสดงเวลาที่เหลือ
/// progress = 1.0 คือเต็มวง, progress = 0.0 คือหมดเวลา
class _CircularTimerPainter extends CustomPainter {
  _CircularTimerPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double progress; // 1.0 = full, 0.0 = empty
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  /// วาดวงกลมพื้นหลัง (สีเทา) และวงกลมแสดงเวลาที่เหลือ (สีตาม _timerColor)
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // วาดวงกลมพื้นหลัง (สีเทา)
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // วาดส่วนโค้งแสดงเวลาที่เหลือ (เริ่มจากด้านบน)
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // start from top
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
