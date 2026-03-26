// ไฟล์นี้เก็บข้อมูลโจทย์ทั้งหมดของเกมเรียงลำดับ
// มี 5 ชุดคำถาม เช่น กิจวัตรประจำวัน, ช่วงเวลาในวัน, ขนาดสัตว์
// รายการในแต่ละชุดเรียงตามลำดับที่ถูกต้องไว้แล้ว

/// รายการ 1 ตัวในเกมเรียงลำดับ มีชื่อ (label) และ Emoji
class SequenceItem {
  const SequenceItem({required this.label, required this.emoji});

  final String label; // ชื่อรายการ เช่น "ตื่นนอน"
  final String emoji; // Emoji ประกอบ เช่น "🌅"
}

/// ชุดข้อมูล 1 ข้อ ประกอบด้วยหัวข้อและรายการที่เรียงลำดับถูกต้อง
class SequenceDataset {
  const SequenceDataset({required this.title, required this.items});

  final String title; // ชื่อหัวข้อ เช่น "กิจวัตรประจำวัน"
  final List<SequenceItem> items; // รายการเรียงตามลำดับที่ถูกต้อง
}

/// ชุดข้อมูลทั้งหมด 5 ชุด — รายการเรียงตามลำดับที่ถูกต้องแล้ว
/// ตอนเล่นจริงจะเลือก 4 รายการแรก แล้วสุ่มสลับลำดับให้ผู้ใช้เรียงใหม่
const List<SequenceDataset> sequenceDatasets = [
  // ชุดที่ 1 — เรียงกิจวัตรประจำวันตั้งแต่ตื่นจนเข้านอน
  SequenceDataset(
    title: 'กิจวัตรประจำวัน',
    items: [
      SequenceItem(label: 'ตื่นนอน', emoji: '🌅'),
      SequenceItem(label: 'ล้างหน้า', emoji: '🚿'),
      SequenceItem(label: 'แปรงฟัน', emoji: '🦷'),
      SequenceItem(label: 'กินข้าว', emoji: '🍚'),
      SequenceItem(label: 'อาบน้ำ', emoji: '🛁'),
      SequenceItem(label: 'เข้านอน', emoji: '🌙'),
    ],
  ),

  // ชุดที่ 2 — เรียงช่วงเวลาในวันจากเช้าถึงกลางคืน
  SequenceDataset(
    title: 'ช่วงเวลาในวัน',
    items: [
      SequenceItem(label: 'เช้า', emoji: '🌅'),
      SequenceItem(label: 'สาย', emoji: '🌤️'),
      SequenceItem(label: 'เที่ยง', emoji: '☀️'),
      SequenceItem(label: 'บ่าย', emoji: '🌇'),
      SequenceItem(label: 'เย็น', emoji: '🌆'),
      SequenceItem(label: 'กลางคืน', emoji: '🌙'),
    ],
  ),

  // ชุดที่ 3 — เรียงขนาดสัตว์จากเล็กสุดไปใหญ่สุด
  SequenceDataset(
    title: 'เรียงขนาดสัตว์',
    items: [
      SequenceItem(label: 'มด', emoji: '🐜'),
      SequenceItem(label: 'ปลา', emoji: '🐟'),
      SequenceItem(label: 'แมว', emoji: '🐱'),
      SequenceItem(label: 'คน', emoji: '🧑'),
      SequenceItem(label: 'วัว', emoji: '🐄'),
      SequenceItem(label: 'ช้าง', emoji: '🐘'),
    ],
  ),

  // ชุดที่ 4 — เรียงขั้นตอนซักผ้าตามลำดับ
  SequenceDataset(
    title: 'ขั้นตอนซักผ้า',
    items: [
      SequenceItem(label: 'ซักผ้า', emoji: '👕'),
      SequenceItem(label: 'ตากผ้า', emoji: '☀️'),
      SequenceItem(label: 'เก็บผ้า', emoji: '🧺'),
      SequenceItem(label: 'พับผ้า', emoji: '👐'),
    ],
  ),

  // ชุดที่ 5 — เรียงขั้นตอนปลูกต้นไม้ตามลำดับ
  SequenceDataset(
    title: 'ขั้นตอนปลูกต้นไม้',
    items: [
      SequenceItem(label: 'ขุดดิน', emoji: '⛏️'),
      SequenceItem(label: 'ใส่เมล็ด', emoji: '🌱'),
      SequenceItem(label: 'รดน้ำ', emoji: '💧'),
      SequenceItem(label: 'ต้นอ่อนงอก', emoji: '🌿'),
    ],
  ),
];
