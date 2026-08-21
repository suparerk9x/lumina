import 'package:hive_flutter/hive_flutter.dart';

import '../../core/strings.dart';
import '../../shared/storage/hive_boxes.dart';
import '../../shared/storage/storage_service.dart';

/// การ์ดกระตุ้นความจำ 1 ใบ (ข้อ 8)
/// - ถ้ามีรูปครอบครัว: แสดงรูป + ถามว่า "คนนี้คือใคร" (answer = ชื่อ)
/// - ถ้าไม่มี: แสดงคำถามกระตุ้นความจำให้ตอบในใจ (answer = null)
class FlashCard {
  const FlashCard({
    required this.question,
    this.imageBase64,
    this.answer,
  });

  final String question;
  final String? imageBase64;
  final String? answer;
}

/// Service สำหรับ flash card รายวัน — คุมว่าจะแสดงวันละครั้ง และสร้างการ์ด
class FlashCardService {
  FlashCardService._();
  static final FlashCardService _instance = FlashCardService._();
  factory FlashCardService() => _instance;

  /// คีย์คำถามกระตุ้นความจำ (ใช้เมื่อยังไม่มีรูปครอบครัว) — แปลตามภาษา
  static const List<String> _promptKeys = [
    'flash.prompt1',
    'flash.prompt2',
    'flash.prompt3',
    'flash.prompt4',
    'flash.prompt5',
    'flash.prompt6',
    'flash.prompt7',
  ];

  Box get _box => Hive.box(HiveBoxes.flashCard);

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  /// ยังไม่ได้แสดงการ์ดของวันนี้หรือยัง
  bool shouldShowToday() {
    try {
      return _box.get('lastShown') != _todayKey();
    } catch (_) {
      return false;
    }
  }

  /// บันทึกว่าแสดงการ์ดของวันนี้แล้ว
  Future<void> markShownToday() async {
    try {
      await _box.put('lastShown', _todayKey());
    } catch (_) {
      // เงียบไว้ — ไม่ใช่เรื่องคอขาดบาดตาย
    }
  }

  /// สร้างการ์ดของวันนี้ (คืน null ถ้าไม่มีอะไรจะแสดง)
  FlashCard? buildTodayCard() {
    final dayIndex = DateTime.now().difference(DateTime(2020)).inDays;

    final contacts = StorageService().getUserProfile().contacts;
    final withPhoto =
        contacts.where((c) => (c.photoBase64 ?? '').isNotEmpty).toList();

    if (withPhoto.isNotEmpty) {
      final c = withPhoto[dayIndex % withPhoto.length];
      return FlashCard(
        question: tr('flash.q.who'),
        imageBase64: c.photoBase64,
        answer: c.name,
      );
    }

    if (_promptKeys.isNotEmpty) {
      return FlashCard(question: tr(_promptKeys[dayIndex % _promptKeys.length]));
    }
    return null;
  }
}
