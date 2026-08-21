import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings.dart';
import '../../../core/theme.dart';
import '../assessment_state.dart';

/// ไฟล์นี้เป็นขั้นตอนที่ 1 ของแบบประเมิน: ถามวันและเวลา
/// ถามผู้ใช้ว่าวันนี้เป็นวันอะไร (จันทร์-อาทิตย์) และเป็นช่วงเวลาใด (เช้า/เที่ยง/เย็น/กลางคืน)
/// ให้ 1 คะแนนต่อคำตอบที่ถูก (เต็ม 2 คะแนน)

/// คลาส StepDateTime แสดงขั้นตอนที่ 1 ของแบบประเมิน
/// ถามผู้ใช้ว่าวันนี้เป็นวันอะไร และเป็นช่วงเวลาใด
class StepDateTime extends ConsumerStatefulWidget {
  const StepDateTime({super.key});

  @override
  ConsumerState<StepDateTime> createState() => _StepDateTimeState();
}

/// State ภายในของ StepDateTime
/// เก็บวันที่เลือก, ช่วงเวลาที่เลือก, และว่าแสดงคำถามช่วงเวลาหรือยัง
class _StepDateTimeState extends ConsumerState<StepDateTime> {
  /// รายชื่อวันในสัปดาห์ภาษาไทย (เรียงตาม DateTime.weekday: จันทร์=1 ... อาทิตย์=7)
  static const _thaiDays = [
    'วันจันทร์',
    'วันอังคาร',
    'วันพุธ',
    'วันพฤหัสบดี',
    'วันศุกร์',
    'วันเสาร์',
    'วันอาทิตย์',
  ];

  /// ตัวเลือกช่วงเวลาในวัน
  static const _timePeriods = ['เช้า', 'เที่ยง', 'เย็น', 'กลางคืน'];

  String? _selectedDay; // วันที่ผู้ใช้เลือก
  String? _selectedTime; // ช่วงเวลาที่ผู้ใช้เลือก
  bool _showTimeQuestion = false; // แสดงคำถามช่วงเวลาหรือยัง

  /// หา index ของวันปัจจุบัน (จันทร์=0, อังคาร=1, ..., อาทิตย์=6)
  int _correctDayIndex() {
    // DateTime.monday = 1 ... DateTime.sunday = 7
    return DateTime.now().weekday - 1;
  }

  /// หาช่วงเวลาที่ถูกต้องจากชั่วโมงปัจจุบัน
  String _correctTimePeriod() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'เช้า';
    if (hour >= 12 && hour < 13) return 'เที่ยง';
    if (hour >= 13 && hour < 18) return 'เย็น';
    return 'กลางคืน';
  }

  /// เมื่อผู้ใช้เลือกวัน ให้บันทึกแล้วแสดงคำถามช่วงเวลา
  void _selectDay(String day) {
    setState(() {
      _selectedDay = day;
      _showTimeQuestion = true;
    });
  }

  /// เมื่อผู้ใช้เลือกช่วงเวลา คำนวณคะแนนแล้วไป step ถัดไป
  void _selectTime(String time) {
    setState(() => _selectedTime = time);

    // คำนวณคะแนน: ตอบวันถูก +1, ตอบเวลาถูก +1
    int score = 0;
    if (_selectedDay == _thaiDays[_correctDayIndex()]) score++;
    if (time == _correctTimePeriod()) score++;

    ref.read(assessmentProvider.notifier).setDateTimeScore(score);

    // รอ 0.5 วินาทีแล้วไป step ถัดไป (ให้ผู้ใช้เห็นว่าเลือกแล้ว)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref.read(assessmentProvider.notifier).nextStep();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _showTimeQuestion
                  ? tr('assess.question2of2')
                  : tr('assess.question1of2'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 24),

          if (!_showTimeQuestion) ...[
            Text(
              tr('assess.whatDayTitle'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              tr('assess.whatDaySubtitle'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            ..._thaiDays.map(
              (day) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OptionButton(
                  label: _dayLabel(day),
                  isSelected: _selectedDay == day,
                  onTap: () => _selectDay(day),
                ),
              ),
            ),
          ] else ...[
            Text(
              tr('assess.whatTimeTitle'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              tr('assess.whatTimeSubtitle'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            ..._timePeriods.map(
              (period) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OptionButton(
                  label: _periodLabel(period),
                  icon: _iconForPeriod(period),
                  isSelected: _selectedTime == period,
                  onTap: () => _selectTime(period),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// แปลชื่อวัน (ค่าภายในเป็นภาษาไทย) เป็นข้อความที่แสดงตามภาษาปัจจุบัน
  String _dayLabel(String day) {
    const keys = {
      'วันจันทร์': 'assess.dayMon',
      'วันอังคาร': 'assess.dayTue',
      'วันพุธ': 'assess.dayWed',
      'วันพฤหัสบดี': 'assess.dayThu',
      'วันศุกร์': 'assess.dayFri',
      'วันเสาร์': 'assess.daySat',
      'วันอาทิตย์': 'assess.daySun',
    };
    final key = keys[day];
    return key != null ? tr(key) : day;
  }

  /// แปลชื่อช่วงเวลา (ค่าภายในเป็นภาษาไทย) เป็นข้อความที่แสดงตามภาษาปัจจุบัน
  String _periodLabel(String period) {
    switch (period) {
      case 'เช้า':
        return tr('assess.periodMorning');
      case 'เที่ยง':
        return tr('assess.periodNoon');
      case 'เย็น':
        return tr('assess.periodEvening');
      default:
        return tr('assess.periodNight');
    }
  }

  /// เลือกไอคอนที่เหมาะกับแต่ละช่วงเวลา (พระอาทิตย์, พลบค่ำ, พระจันทร์)
  IconData _iconForPeriod(String period) {
    switch (period) {
      case 'เช้า':
        return Icons.wb_sunny_rounded;
      case 'เที่ยง':
        return Icons.wb_sunny_outlined;
      case 'เย็น':
        return Icons.wb_twilight_rounded;
      default:
        return Icons.nightlight_round;
    }
  }
}

// ─── ปุ่มตัวเลือกที่ใช้ซ้ำได้ ─────────────────────────────

/// คลาส _OptionButton เป็นปุ่มตัวเลือกที่ใช้ทั้งคำถามวันและช่วงเวลา
/// เมื่อเลือกแล้วจะเปลี่ยนสีเป็นสีหลัก (primary) พร้อมตัวหนังสือสีขาว
class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppTheme.primary : Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
      elevation: isSelected ? 0 : 1,
      shadowColor: Colors.black.withAlpha(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  size: 28,
                ),
                const SizedBox(width: 12),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color:
                          isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
