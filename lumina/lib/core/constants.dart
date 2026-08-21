// ไฟล์นี้เก็บค่าคงที่ (constants) ที่ใช้ทั่วทั้งแอป
// เช่น ชื่อแอป, คำศัพท์สำหรับเกม, และการตั้งค่าเกมต่าง ๆ

import 'strings.dart';

/// คลาสรวมค่าคงที่ทั้งหมดของแอป ใช้ static const เพื่อไม่ต้องสร้าง object
class AppConstants {
  // ชื่อและเวอร์ชันของแอป
  static const String appName = 'Demenish AI';
  static const String appVersion = '2.0.0';

  // ─── Word Pool (Memory Game — 30 คำ, 2 ภาษา) ────────────
  /// คลังคำศัพท์ 30 คำ สำหรับเกมฝึกความจำ (ต้องตรงกับ key ใน wordEmojiMap)
  static const List<String> _wordPoolTh = [
    'บ้าน', 'แมว', 'น้ำ', 'ต้นไม้', 'รถ', 'ปลา', 'โต๊ะ',
    'ดวงดาว', 'หนังสือ', 'กล้วย', 'เก้าอี้', 'ดอกไม้', 'นาฬิกา',
    'แก้ว', 'รองเท้า', 'ประตู', 'หมอน', 'ข้าว', 'พระอาทิตย์',
    'จาน', 'โทรศัพท์', 'พัดลม', 'แม่น้ำ', 'เสื้อ', 'ช้อน',
    'จักรยาน', 'เทียน', 'ส้ม', 'หน้าต่าง', 'หมวก',
  ];

  static const List<String> _wordPoolEn = [
    'house', 'cat', 'water', 'tree', 'car', 'fish', 'table',
    'star', 'book', 'banana', 'chair', 'flower', 'clock',
    'glass', 'shoe', 'door', 'pillow', 'rice', 'sun',
    'plate', 'phone', 'fan', 'river', 'shirt', 'spoon',
    'bicycle', 'candle', 'orange', 'window', 'hat',
  ];

  /// คลังคำตามภาษาปัจจุบัน
  static List<String> get wordPool =>
      appLang == 'th' ? _wordPoolTh : _wordPoolEn;

  // ─── Game Config (ค่าตั้งต้นของเกมต่าง ๆ) ──────────────
  /// จำนวนรอบของเกมจับคู่เสียง
  static const int soundMatchRounds = 10;
  /// จำนวนรอบของเกมเรียงลำดับ
  static const int sequenceGameRounds = 5;
  /// เวลา (วินาที) ที่แสดงคำให้ผู้เล่นจำก่อนเริ่มตอบ
  static const int memoryDisplaySeconds = 10;
  /// ระยะเวลาแสดงผลตอบกลับ (ถูก/ผิด) ก่อนไปข้อถัดไป
  static const Duration feedbackDuration = Duration(milliseconds: 800);
}
