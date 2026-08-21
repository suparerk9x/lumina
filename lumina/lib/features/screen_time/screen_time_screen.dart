import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import 'screen_time_provider.dart';

/// ไฟล์นี้เป็นหน้าจอจำกัดเวลาหน้าจอ (Screen Time)
/// แสดงเวลาที่ใช้วันนี้, ตั้งเวลาจำกัด, และสรุปสัปดาห์เป็นกราฟแท่ง

/// หน้าจอหลักของฟีเจอร์จำกัดเวลาหน้าจอ
/// ใช้ ConsumerStatefulWidget เพราะต้องฟังการเปลี่ยนแปลงของ provider
class ScreenTimeScreen extends ConsumerStatefulWidget {
  const ScreenTimeScreen({super.key});

  @override
  ConsumerState<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends ConsumerState<ScreenTimeScreen> {
  // ตัวแปรป้องกันไม่ให้แสดง dialog ซ้ำหลายครั้ง
  bool _alertDialogShowing = false;

  @override
  Widget build(BuildContext context) {
    // ฟังการเปลี่ยนแปลงของ state เมื่อใช้เกินเวลาจะแสดง dialog เตือน
    ref.listen(screenTimeProvider, (prev, next) {
      if (next.alertShown &&
          !(prev?.alertShown ?? false) &&
          !_alertDialogShowing) {
        _showOverLimitAlert(context);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(tr('screen.title'))),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            _TodayUsageSection(),
            _DailyLimitSection(),
            _WeekHistorySection(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// แสดง dialog เตือนเมื่อผู้ใช้ใช้เกินเวลาที่กำหนด
  /// มีปุ่มหยุดจับเวลา และปุ่มรับทราบแล้วใช้ต่อ
  void _showOverLimitAlert(BuildContext context) {
    _alertDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.warning_rounded, color: AppTheme.error, size: 48),
        title: Text(
          tr('screen.overLimitTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          tr('screen.overLimitMessage'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: AppTheme.textSecondary),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(screenTimeProvider.notifier).stopTracking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              minimumSize: const Size(200, 52),
            ),
            child: Text(tr('screen.stopTimer')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr('screen.acknowledgeContinue')),
          ),
        ],
      ),
    ).then((_) => _alertDialogShowing = false);
  }
}

// ═══════════════════════════════════════════════════════════════
// ส่วน: เวลาที่ใช้วันนี้ — นับวินาทีแบบ real-time
// ═══════════════════════════════════════════════════════════════

/// แสดงวงกลมแสดงเวลาที่ใช้วันนี้ พร้อมปุ่มเริ่ม/หยุดจับเวลา
/// มี ring แสดงสัดส่วนเวลาที่ใช้เทียบกับเวลาจำกัด
class _TodayUsageSection extends ConsumerWidget {
  const _TodayUsageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(screenTimeProvider);
    final isOver = state.isOverLimit;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          // Circular progress ring
          SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: _UsageRingPainter(
                ratio: state.usageRatio,
                isOver: isOver,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOver
                          ? Icons.warning_rounded
                          : state.isTracking
                              ? Icons.timer_rounded
                              : Icons.phone_android_rounded,
                      size: 28,
                      color: isOver
                          ? AppTheme.error
                          : state.isTracking
                              ? AppTheme.success
                              : AppTheme.primary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.usageFormatted,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isOver
                                ? AppTheme.error
                                : AppTheme.textPrimary,
                          ),
                    ),
                    Text(
                      state.isTracking
                          ? tr('screen.tracking')
                          : tr('screen.used'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: state.isTracking
                                ? AppTheme.success
                                : AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Limit label
          Text(
            trp('screen.dailyLimitLabel', {'limit': state.limitFormatted}),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),

          // Over-limit warning
          if (isOver) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.error.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.error, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('screen.overLimitWarning'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Tracking button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: state.isTracking
                ? OutlinedButton.icon(
                    onPressed: () {
                      ref.read(screenTimeProvider.notifier).stopTracking();
                    },
                    icon: const Icon(Icons.stop_rounded, size: 24),
                    label: Text(tr('screen.stopTimer')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error, width: 1.5),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () {
                      ref.read(screenTimeProvider.notifier).startTracking();
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 28),
                    label: Text(tr('screen.startTimer')),
                  ),
          ),

          // Reset today button
          if (state.todayUsage.inSeconds > 0 && !state.isTracking) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.read(screenTimeProvider.notifier).resetTodayUsage();
              },
              child: Text(
                tr('screen.resetToday'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ส่วน: ตั้งเวลาจำกัดรายวัน
// ═══════════════════════════════════════════════════════════════

/// ส่วนให้ผู้ใช้ตั้งเวลาจำกัดการใช้หน้าจอต่อวัน
/// ใช้ wheel picker สำหรับเลือกชั่วโมงและนาที
class _DailyLimitSection extends ConsumerStatefulWidget {
  const _DailyLimitSection();

  @override
  ConsumerState<_DailyLimitSection> createState() => _DailyLimitSectionState();
}

class _DailyLimitSectionState extends ConsumerState<_DailyLimitSection> {
  // ตัวควบคุม scroll wheel สำหรับเลือกชั่วโมงและนาที
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  // ตัวเลือกชั่วโมง (0-8) และนาที (0, 15, 30, 45)
  static const _hours = [0, 1, 2, 3, 4, 5, 6, 7, 8];
  static const _minutes = [0, 15, 30, 45];

  @override
  void initState() {
    super.initState();
    final limit = ref.read(screenTimeProvider).dailyLimit;
    _hourController =
        FixedExtentScrollController(initialItem: limit.inHours.clamp(0, 8));
    _minuteController = FixedExtentScrollController(
      initialItem: _minutes
          .indexOf((limit.inMinutes % 60 ~/ 15) * 15)
          .clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  /// บันทึกเวลาจำกัดที่เลือกลง Storage และแสดง snackbar ยืนยัน
  void _saveLimit() {
    final h = _hours[_hourController.selectedItem.clamp(0, _hours.length - 1)];
    final m = _minutes[_minuteController.selectedItem.clamp(0, _minutes.length - 1)];
    final limit = Duration(hours: h, minutes: m);
    ref.read(screenTimeProvider.notifier).setDailyLimit(limit);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            trp('screen.limitSaved', {'h': '$h', 'm': '$m'}),
            style: const TextStyle(fontSize: 18)),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.timer_outlined,
                        color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(tr('screen.setLimit'),
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 140,
                child: Row(
                  children: [
                    Expanded(
                      child: _WheelPicker(
                        controller: _hourController,
                        itemCount: _hours.length,
                        labelBuilder: (i) => '${_hours[i]}',
                        suffix: tr('screen.hours'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(':',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: _WheelPicker(
                        controller: _minuteController,
                        itemCount: _minutes.length,
                        labelBuilder: (i) =>
                            _minutes[i].toString().padLeft(2, '0'),
                        suffix: tr('screen.minutes'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveLimit,
                  child: Text(tr('screen.saveLimit')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget ตัวเลือกแบบหมุน (wheel) สำหรับเลือกตัวเลขชั่วโมงหรือนาที
class _WheelPicker extends StatelessWidget {
  const _WheelPicker({
    required this.controller,
    required this.itemCount,
    required this.labelBuilder,
    required this.suffix,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final String Function(int index) labelBuilder;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 48,
                physics: const FixedExtentScrollPhysics(),
                diameterRatio: 1.5,
                perspective: 0.003,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: itemCount,
                  builder: (context, index) {
                    return Center(
                      child: Text(
                        labelBuilder(index),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          suffix,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ส่วน: กราฟแท่งสรุปการใช้งานรายสัปดาห์ (ข้อมูลจริง)
// ═══════════════════════════════════════════════════════════════

/// แสดงกราฟแท่งสรุปเวลาใช้หน้าจอ 7 วัน (จันทร์-อาทิตย์)
class _WeekHistorySection extends ConsumerWidget {
  const _WeekHistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(screenTimeProvider);
    final hasAnyData = state.weekHistory.any((d) => d.inSeconds > 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bar_chart_rounded,
                        color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(tr('screen.weekSummary'),
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 24),
              if (!hasAnyData)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      tr('screen.noWeekData'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 180,
                  child: CustomPaint(
                    size: const Size(double.infinity, 180),
                    painter: _WeekBarChartPainter(
                      history: state.weekHistory,
                      limit: state.dailyLimit,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ตัววาดกราฟแท่ง ──────────────────────────────────────

/// CustomPainter สำหรับวาดกราฟแท่ง 7 วัน
/// แท่งสีเขียว = ใช้ไม่เกินเวลา, แท่งสีแดง = ใช้เกินเวลา
/// เส้นประ = เส้นแบ่งเวลาจำกัด
class _WeekBarChartPainter extends CustomPainter {
  _WeekBarChartPainter({required this.history, required this.limit});

  final List<Duration> history;
  final Duration limit;

  // ชื่อย่อวันในสัปดาห์ภาษาไทย
  static final _dayLabels = [
    tr('screen.dayMon'),
    tr('screen.dayTue'),
    tr('screen.dayWed'),
    tr('screen.dayThu'),
    tr('screen.dayFri'),
    tr('screen.daySat'),
    tr('screen.daySun'),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    const labelHeight = 28.0;
    const limitLineExtra = 8.0;
    final chartHeight = size.height - labelHeight - limitLineExtra;
    final barWidth = (size.width - 8 * 6) / 7;

    final rawMax = history.map((d) => d.inSeconds).reduce((a, b) => a > b ? a : b);
    final maxSeconds = rawMax
        .clamp(limit.inSeconds > 0 ? limit.inSeconds : 1, double.infinity)
        .toDouble();
    if (maxSeconds <= 0) return;

    // Limit line (dashed)
    if (limit.inSeconds > 0) {
      final limitY =
          chartHeight - (limit.inSeconds / maxSeconds * chartHeight) + limitLineExtra;
      final limitPaint = Paint()
        ..color = const Color(0xFF9E9E9E)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, limitY),
          Offset(math.min(startX + 6, size.width), limitY),
          limitPaint,
        );
        startX += 10;
      }
    }

    // Bars
    for (int i = 0; i < 7 && i < history.length; i++) {
      final x = i * (barWidth + 8);
      final seconds = history[i].inSeconds;
      if (seconds == 0) {
        // Draw a small dot for empty days
        canvas.drawCircle(
          Offset(x + barWidth / 2, chartHeight + limitLineExtra - 2),
          3,
          Paint()..color = Colors.grey.shade300,
        );
      } else {
        final barHeight =
            (seconds / maxSeconds * chartHeight).clamp(6.0, chartHeight);
        final isOver = limit.inSeconds > 0 && seconds > limit.inSeconds;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
                x, chartHeight - barHeight + limitLineExtra, barWidth, barHeight),
            const Radius.circular(6),
          ),
          Paint()
            ..color = isOver
                ? AppTheme.error.withAlpha(200)
                : AppTheme.success.withAlpha(200),
        );
      }

      // Day label
      final tp = TextPainter(
        text: TextSpan(
          text: _dayLabels[i],
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(x + (barWidth - tp.width) / 2, size.height - labelHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _WeekBarChartPainter old) =>
      old.history != history || old.limit != limit;
}

// ─── ตัววาดวงแหวนแสดงเวลาที่ใช้ ─────────────────────────────────────

/// CustomPainter วาดวงแหวนแสดงสัดส่วนเวลาที่ใช้
/// วงเทา = พื้นหลัง, วงสี = เวลาที่ใช้ไปแล้ว (น้ำเงิน=ปกติ, แดง=เกิน)
class _UsageRingPainter extends CustomPainter {
  _UsageRingPainter({required this.ratio, required this.isOver});

  final double ratio;
  final bool isOver;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 12.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * ratio.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = isOver ? AppTheme.error : AppTheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _UsageRingPainter old) =>
      old.ratio != ratio || old.isOver != isOver;
}
