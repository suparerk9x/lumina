import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../shared/storage/storage_service.dart';

/// ไฟล์นี้เป็น Widget การ์ดคำแนะนำ AI
/// แสดงคำแนะนำที่เปลี่ยนไปตามผลคะแนนของผู้ใช้ (Rule-based)
/// ถ้ายังไม่มีข้อมูล จะสุ่มจากคำแนะนำทั่วไป

/// การ์ดคำแนะนำ AI ใช้กฎง่าย ๆ เลือกคำแนะนำตามคะแนนผู้ใช้
/// เก็บคำแนะนำใน initState เพื่อไม่ต้องคำนวณใหม่ทุกครั้งที่ build
class AiTipsCard extends StatefulWidget {
  const AiTipsCard({super.key});

  @override
  State<AiTipsCard> createState() => _AiTipsCardState();
}

class _AiTipsCardState extends State<AiTipsCard> {
  // คำแนะนำทั่วไปที่จะใช้เมื่อไม่มีข้อมูลเฉพาะ (สุ่มตามวันที่)
  static const _defaultTips = [
    'อ่านหนังสือหรือนิตยสารวันละ 15 นาที ช่วยกระตุ้นสมอง',
    'ลองเรียนรู้สิ่งใหม่ ๆ ทุกวัน เช่น คำศัพท์ใหม่ 1 คำ',
    'ออกกำลังกายเบา ๆ เช่น เดินเล่น ช่วยให้สมองแข็งแรง',
    'นอนหลับให้เพียงพอ 7-8 ชั่วโมง สมองจะได้พักผ่อน',
    'ทานอาหารที่มีโอเมก้า 3 เช่น ปลา ช่วยบำรุงสมอง',
  ];

  // คำแนะนำที่จะแสดงในการ์ด
  late String _tip;

  @override
  void initState() {
    super.initState();
    _tip = _generateTip();
  }

  /// สร้างคำแนะนำตามข้อมูลผู้ใช้:
  /// - ถ้าคะแนนประเมินต่ำและยังไม่เคยเล่นเกม -> แนะนำให้เล่นเกม
  /// - ถ้าคะแนนดีขึ้น -> ชม
  /// - ถ้าไม่มีข้อมูล -> สุ่มจากคำแนะนำทั่วไป
  String _generateTip() {
    try {
      final storage = StorageService();
      final assessments = storage.getAssessmentHistory(limit: 3);
      final soundScores = storage.getGameScores('sound_match', limit: 1);
      final sequenceScores = storage.getGameScores('sequence', limit: 1);

      if (assessments.isNotEmpty && assessments.first.totalScore < 5) {
        if (soundScores.isEmpty && sequenceScores.isEmpty) {
          return 'ลองเล่นเกมจับคู่เสียงวันละ 1 ครั้ง เพื่อฝึกความจำ';
        }
      }

      if (assessments.length >= 2 &&
          assessments[0].totalScore > assessments[1].totalScore) {
        return 'เยี่ยมมาก! สมองแข็งแรงขึ้น 🌟 ทำต่อไปนะ';
      }
    } catch (e) {
      developer.log('AiTipsCard error: $e', name: 'DemenishAI');
    }
    return _defaultTips[DateTime.now().day % _defaultTips.length];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFFF0F4FF),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: AppTheme.primary.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lightbulb_rounded,
                color: AppTheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'คำแนะนำวันนี้',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _tip,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
