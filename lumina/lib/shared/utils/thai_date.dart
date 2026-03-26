// ไฟล์นี้เป็นฟังก์ชันช่วยแปลงวันที่เป็นรูปแบบไทย (พ.ศ.)
// ปี พ.ศ. = ปี ค.ศ. + 543

/// แปลง DateTime เป็นวันที่ไทย รูปแบบ DD/MM/YYYY+543
/// เช่น DateTime(2026, 3, 26) จะได้ "26/03/2569"
String formatThaiDate(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year + 543}';
}

/// แปลง DateTime เป็นวันที่ไทยแบบสั้น (ไม่มีปี) รูปแบบ DD/MM
/// เช่น DateTime(2026, 3, 26) จะได้ "26/03"
String formatThaiDateShort(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}';
}
