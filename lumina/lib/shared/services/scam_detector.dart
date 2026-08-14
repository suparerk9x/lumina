// ตัวตรวจจับข้อความหลอกลวงแบบ rule-based ภาษาไทย (ข้อ 3)
// ทำงานบนเครื่องทั้งหมด (offline) ไม่ต้องต่อเน็ต ไม่มี AI model
// ให้คะแนนความเสี่ยงจากคำต้องสงสัย + ลิงก์ที่น่าสงสัย พร้อมเหตุผลที่ตรวจเจอ

/// ระดับความเสี่ยงของข้อความ
enum ScamRisk {
  low('ดูปลอดภัย', 'ไม่พบสัญญาณหลอกลวงชัดเจน แต่ถ้าไม่แน่ใจ ลองถามลูกหลานดูนะ'),
  medium('น่าสงสัย', 'มีสัญญาณที่ต้องระวัง ตรวจสอบให้แน่ใจก่อนทำตาม'),
  high('เสี่ยงสูง', 'อย่ากดลิงก์ อย่าโอนเงิน อย่าให้ข้อมูลส่วนตัว โทรถามลูกหลานก่อน');

  const ScamRisk(this.label, this.advice);

  final String label;
  final String advice;
}

/// ผลการวิเคราะห์ข้อความ
class ScamResult {
  const ScamResult({required this.risk, required this.reasons});

  final ScamRisk risk;
  final List<String> reasons; // เหตุผล/สิ่งที่ตรวจเจอ (แสดงให้ผู้ใช้)
}

class ScamDetector {
  ScamDetector._();
  static final ScamDetector _instance = ScamDetector._();
  factory ScamDetector() => _instance;

  // คำเสี่ยงสูง — เกี่ยวกับการโอนเงิน/ให้ข้อมูล/ข่มขู่ (คะแนน 3 ต่อกลุ่ม)
  static const List<String> _highKeywords = [
    'โอนเงิน', 'โอนด่วน', 'โอนก่อน', 'ยืนยันตัวตน', 'ยืนยันข้อมูล',
    'กรอกข้อมูล', 'เลขบัตรประชาชน', 'เลขบัญชี', 'รหัสผ่าน', 'บัตรเครดิต',
    'otp', 'รหัส otp', 'บัญชีถูกระงับ', 'บัญชีถูกอายัด', 'ระงับการใช้งาน',
    'พัสดุตกค้าง', 'พัสดุตีกลับ', 'ภาษีคืน', 'คืนภาษี', 'หมายจับ',
    'ฟอกเงิน', 'ปปง', 'อายัดบัญชี', 'ค้ำประกัน', 'โอนค่าธรรมเนียม',
  ];

  // คำเสี่ยงกลาง — ล่อใจ/เร่งรีบ/กู้เงิน (คะแนน 1)
  static const List<String> _mediumKeywords = [
    'ได้รับรางวัล', 'ถูกรางวัล', 'ลุ้นโชค', 'รับเครดิตฟรี', 'เครดิตฟรี',
    'เงินกู้', 'อนุมัติเงินกู้', 'ดอกเบี้ยต่ำ', 'สมัครด่วน', 'คลิกเลย',
    'กดลิงก์', 'คลิกลิงก์', 'กดรับสิทธิ์', 'รับสิทธิ์', 'ด่วนที่สุด',
    'ภายใน 24 ชั่วโมง', 'ภายในวันนี้', 'เร่งด่วน', 'จำนวนจำกัด',
    'เจ้าหน้าที่', 'ตำรวจ', 'สรรพากร', 'ไปรษณีย์', 'กรมศุลกากร',
  ];

  // โดเมนย่อลิงก์ (ปิดบังปลายทาง)
  static const List<String> _shorteners = [
    'bit.ly', 'tinyurl.com', 'cutt.ly', 'shorturl', 'is.gd', 't.co',
    'goo.gl', 'rb.gy', 'ow.ly', 'buff.ly', 'lin.ee', 's.id',
  ];

  // นามสกุลโดเมนที่มักใช้ในเว็บหลอกลวง
  static const List<String> _suspiciousTlds = [
    '.xyz', '.top', '.club', '.online', '.site', '.info', '.cc',
    '.work', '.buzz', '.rest', '.icu', '.vip', '.live', '.shop',
  ];

  static final RegExp _urlRegex =
      RegExp(r'((https?:\/\/)?[a-z0-9.\-]+\.[a-z]{2,}(\/[^\s]*)?)',
          caseSensitive: false);
  static final RegExp _ipUrlRegex =
      RegExp(r'https?:\/\/\d{1,3}(\.\d{1,3}){3}', caseSensitive: false);

  /// วิเคราะห์ข้อความ คืนระดับความเสี่ยง + เหตุผล
  ScamResult analyze(String input) {
    final text = input.trim();
    if (text.isEmpty) {
      return const ScamResult(risk: ScamRisk.low, reasons: []);
    }
    final lower = text.toLowerCase();

    int score = 0;
    final reasons = <String>[];

    // 1) คำเสี่ยงสูง
    final highHits = _highKeywords.where(lower.contains).toList();
    if (highHits.isNotEmpty) {
      score += 3 * highHits.length;
      reasons.add('มีคำที่มักใช้หลอกลวง: ${_preview(highHits)}');
    }

    // 2) คำเสี่ยงกลาง
    final medHits = _mediumKeywords.where(lower.contains).toList();
    if (medHits.isNotEmpty) {
      score += medHits.length;
      reasons.add('มีคำชวนเชื่อ/เร่งรีบ: ${_preview(medHits)}');
    }

    // 3) ลิงก์
    final hasUrl = _urlRegex.hasMatch(lower);
    if (hasUrl) {
      score += 1;
      reasons.add('มีลิงก์ให้กด — ระวังก่อนกดทุกครั้ง');

      if (_ipUrlRegex.hasMatch(lower)) {
        score += 3;
        reasons.add('ลิงก์เป็นตัวเลข IP แทนชื่อเว็บ (พบมากในเว็บปลอม)');
      }
      final shortener = _shorteners.where(lower.contains).toList();
      if (shortener.isNotEmpty) {
        score += 2;
        reasons.add('ใช้ลิงก์ย่อที่ซ่อนปลายทาง: ${_preview(shortener)}');
      }
      final tld = _suspiciousTlds.where(lower.contains).toList();
      if (tld.isNotEmpty) {
        score += 2;
        reasons.add('โดเมนแปลก (${_preview(tld)}) ไม่ใช่เว็บทางการ');
      }
    }

    // 4) รวมพลัง: ขอโอนเงิน/ข้อมูล + มีลิงก์ = อันตรายมาก
    if (highHits.isNotEmpty && hasUrl) {
      score += 2;
    }

    final risk = score >= 5
        ? ScamRisk.high
        : (score >= 2 ? ScamRisk.medium : ScamRisk.low);

    return ScamResult(risk: risk, reasons: reasons);
  }

  String _preview(List<String> items) {
    const max = 3;
    final shown = items.take(max).join(', ');
    return items.length > max ? '$shown …' : shown;
  }
}
