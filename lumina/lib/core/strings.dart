// ระบบ 2 ภาษา (i18n) แบบ central table — ใช้ได้ทั้งใน widget และ enum
// ค่าเริ่มต้น = English, เลือกไทยได้ในตั้งค่า
//
// วิธีใช้: tr('key')  → คืนข้อความตามภาษาปัจจุบัน (appLang)
// appLang ถูก sync โดย settingsProvider เมื่อผู้ใช้เปลี่ยนภาษา

/// ภาษาปัจจุบันของแอป ('en' | 'th') — sync จาก settings
String appLang = 'en';

/// ภาษาที่รองรับ
const List<String> kSupportedLangs = ['en', 'th'];

/// แปลข้อความตาม key (fallback: en → key เอง)
String tr(String key) {
  final entry = _strings[key];
  if (entry == null) return key;
  return entry[appLang] ?? entry['en'] ?? key;
}

/// แทรกค่าในข้อความ เช่น trp('greeting.age', {'age': '70'})
String trp(String key, Map<String, String> params) {
  var s = tr(key);
  params.forEach((k, v) => s = s.replaceAll('{$k}', v));
  return s;
}

const Map<String, Map<String, String>> _strings = {
  // ── App / common ──
  'app.tagline': {'en': 'A Brain Tracker App', 'th': 'แอปฝึกสมองและดูแลสุขภาพ'},
  'common.cancel': {'en': 'Cancel', 'th': 'ยกเลิก'},
  'common.delete': {'en': 'Delete', 'th': 'ลบ'},
  'common.save': {'en': 'Save', 'th': 'บันทึก'},
  'common.close': {'en': 'Close', 'th': 'ปิด'},
  'common.ok': {'en': 'OK', 'th': 'ตกลง'},
  'common.edit': {'en': 'Edit', 'th': 'แก้ไข'},
  'common.add': {'en': 'Add', 'th': 'เพิ่ม'},
  'common.test': {'en': 'Test now', 'th': 'ทดสอบตอนนี้'},

  // ── Language ──
  'lang.title': {'en': 'Language', 'th': 'ภาษา'},
  'lang.en': {'en': 'English', 'th': 'English'},
  'lang.th': {'en': 'ไทย (Thai)', 'th': 'ไทย'},

  // ── Bottom navigation ──
  'nav.games': {'en': 'Brain', 'th': 'ฝึกสมอง'},
  'nav.assessment': {'en': 'Assess', 'th': 'ประเมิน'},
  'nav.screenTime': {'en': 'Screen', 'th': 'จำกัดเวลา'},
  'nav.settings': {'en': 'Settings', 'th': 'ตั้งค่า'},

  // ── Home ──
  'home.appbar': {'en': 'Brain Training', 'th': 'ฝึกสมอง'},
  'home.hello': {'en': 'Hello!', 'th': 'สวัสดี!'},
  'home.howAreYou': {'en': 'How are you today?', 'th': 'วันนี้เป็นอย่างไรบ้าง?'},
  'home.historyTooltip': {'en': 'Score history', 'th': 'ประวัติคะแนน'},
  'home.familyCall.title': {'en': 'Call Family', 'th': 'โทรหาครอบครัว'},
  'home.familyCall.subtitle':
      {'en': 'Tap to call children instantly', 'th': 'กดโทรหาลูกหลานได้ทันที'},
  'home.appointment.title': {'en': 'Doctor Appointments', 'th': 'นัดหมายแพทย์'},
  'home.appointment.subtitle':
      {'en': 'Save visits, get reminded early', 'th': 'บันทึกนัด แล้วเตือนก่อนถึงเวลา'},
  'home.scam.title': {'en': 'Scam Message Check', 'th': 'ตรวจข้อความหลอกลวง'},
  'home.scam.subtitle':
      {'en': 'Paste an SMS to check if it is safe', 'th': 'วางข้อความ SMS มาเช็กว่าปลอดภัยไหม'},
  'home.soundMatch.title': {'en': 'Sound Match', 'th': 'จับคู่เสียง'},
  'home.soundMatch.subtitle':
      {'en': 'Train listening memory', 'th': 'ฝึกความจำด้านการฟัง'},
  'home.memoryMatch.title': {'en': 'Picture Match', 'th': 'จับคู่ภาพ'},
  'home.memoryMatch.subtitle':
      {'en': 'Train visual memory', 'th': 'ฝึกความจำด้านภาพ'},
  'home.colorSequence.title': {'en': 'Tap in Order', 'th': 'กดปุ่มตามลำดับ'},
  'home.colorSequence.subtitle':
      {'en': 'Train memory and focus', 'th': 'ฝึกความจำและการสังเกต'},

  // ── Assessment tab (home) ──
  'assessment.tab.title': {'en': 'Brain Health Check', 'th': 'ประเมินสุขภาพสมอง'},
  'assessment.tab.ready': {'en': 'Ready to start?', 'th': 'พร้อมประเมินหรือยัง?'},
  'assessment.tab.desc': {
    'en': 'Take the assessment to see your brain health',
    'th': 'ทำแบบประเมินเพื่อดูสุขภาพสมองของคุณ'
  },
  'assessment.tab.start': {'en': 'Start Assessment', 'th': 'เริ่มประเมิน'},

  // ── Onboarding ──
  'onboarding.welcome': {'en': 'Welcome to Demenish AI', 'th': 'ยินดีต้อนรับสู่ Demenish AI'},
  'onboarding.subtitle': {
    'en': 'Tell us a bit to personalize the app\n(optional — you can set it later in Settings)',
    'th': 'บอกเราหน่อยเพื่อปรับแอปให้เหมาะกับคุณ\n(ข้ามได้ แล้วมาตั้งทีหลังที่หน้าตั้งค่า)'
  },
  'onboarding.name': {'en': 'Your name', 'th': 'ชื่อของคุณ'},
  'onboarding.nameHint': {'en': 'e.g. John', 'th': 'เช่น สมชาย'},
  'onboarding.age': {'en': 'Age range', 'th': 'ช่วงอายุ'},
  'onboarding.gender': {'en': 'Gender', 'th': 'เพศ'},
  'onboarding.start': {'en': 'Get Started', 'th': 'เริ่มใช้งาน'},
  'onboarding.skip': {'en': 'Skip for now', 'th': 'ข้ามไปก่อน'},

  // ── Profile ──
  'profile.title': {'en': 'My Info', 'th': 'ข้อมูลของฉัน'},
  'profile.name': {'en': 'Name', 'th': 'ชื่อ'},
  'profile.nameHint': {'en': 'Your name', 'th': 'ชื่อของคุณ'},
  'profile.family': {'en': 'Family Members', 'th': 'รายชื่อครอบครัว'},
  'profile.familyCount': {'en': '{n} people', 'th': '{n} คน'},

  // ── Settings ──
  'settings.title': {'en': 'Settings', 'th': 'ตั้งค่า'},
  'settings.myInfo': {'en': 'My Info', 'th': 'ข้อมูลของฉัน'},
  'settings.myInfoHint':
      {'en': 'Tap to set name, age and gender', 'th': 'แตะเพื่อตั้งชื่อ อายุ และเพศ'},
  'settings.theme': {'en': 'Theme Mode', 'th': 'โหมดธีม'},
  'settings.background': {'en': 'Background Color', 'th': 'สีพื้นหลัง'},
  'settings.font': {'en': 'Font', 'th': 'ฟอนต์'},
  'settings.fontSize': {'en': 'Text Size', 'th': 'ขนาดตัวอักษร'},
  'settings.familyLine': {'en': 'Notify Family via LINE', 'th': 'แจ้งครอบครัวผ่าน LINE'},
  'settings.familyLineHint': {
    'en': 'Family scans a QR to receive alerts',
    'th': 'ให้ลูกหลานสแกน QR แอดเพื่อรับแจ้งเตือน'
  },

  // ── Screen distance (settings section) ──
  'sd.title': {'en': 'Screen Distance Alert', 'th': 'เตือนระยะห่างหน้าจอ'},
  'sd.desc': {
    'en': 'Uses the front camera periodically (only while the app is open). '
        'Warns you to move back if you sit too close.',
    'th': 'ใช้กล้องหน้าตรวจเป็นช่วง เฉพาะตอนเปิดแอป '
        'ถ้านั่งใกล้จอเกินไปจะเตือนให้ถอยห่าง'
  },
  'sd.every': {'en': 'Check every', 'th': 'ตรวจทุก'},
  'sd.tooClose': {'en': 'Too close, please move back a bit', 'th': 'นั่งใกล้เกินไป ถอยห่างอีกนิดนะ'},
  'sd.good': {'en': 'Distance looks good', 'th': 'ระยะห่างกำลังดี'},
  'sd.noFace': {'en': 'No face found, look at the camera and retry', 'th': 'ไม่พบใบหน้า ลองมองที่กล้องแล้วลองใหม่'},
  'sd.warn': {'en': 'Sitting too close — move back to protect your eyes', 'th': 'นั่งใกล้จอเกินไป ถอยห่างอีกนิดนะ เพื่อถนอมสายตา'},

  // ── Drowsiness (settings section) ──
  'drowsy.title': {'en': 'Drowsiness Detection', 'th': 'ตรวจจับอาการง่วง'},
  'drowsy.desc': {
    'en': 'Uses the front camera periodically (only while the app is open). '
        'If drowsiness is detected, warns you to rest and alerts family via LINE.',
    'th': 'ใช้กล้องหน้าตรวจเป็นช่วง เฉพาะตอนเปิดแอป '
        'ถ้าพบว่ากำลังง่วง จะเตือนให้พัก และแจ้งครอบครัวผ่าน LINE'
  },
  'drowsy.lineReady': {'en': 'LINE: ready to notify', 'th': 'LINE: พร้อมส่งแจ้งเตือน'},
  'drowsy.lineNotReady': {'en': 'LINE: not configured (see docs/backend)', 'th': 'LINE: ยังไม่ได้ตั้งค่า (ดู docs/backend)'},
  'drowsy.warn': {'en': 'You seem drowsy — rest your eyes for a moment', 'th': 'ดูเหมือนกำลังง่วง พักสายตาสักครู่นะ'},
  'common.minutes': {'en': '{n} min', 'th': '{n} นาที'},

  // ── Enums: AgeRange ──
  'age.below60': {'en': 'Under 60', 'th': 'ต่ำกว่า 60 ปี'},
  'age.60to69': {'en': '60–69', 'th': '60–69 ปี'},
  'age.70to79': {'en': '70–79', 'th': '70–79 ปี'},
  'age.80plus': {'en': '80+', 'th': '80 ปีขึ้นไป'},

  // ── Enums: Gender ──
  'gender.male': {'en': 'Male', 'th': 'ชาย'},
  'gender.female': {'en': 'Female', 'th': 'หญิง'},
  'gender.unspecified': {'en': 'Not specified', 'th': 'ไม่ระบุ'},

  // ── Enums: FontScale ──
  'fontscale.small': {'en': 'Small', 'th': 'เล็ก'},
  'fontscale.normal': {'en': 'Normal', 'th': 'ปกติ'},
  'fontscale.large': {'en': 'Large', 'th': 'ใหญ่'},
  'fontscale.extraLarge': {'en': 'Extra Large', 'th': 'ใหญ่มาก'},

  // ── Enums: Font descriptions ──
  'font.sarabun.desc': {'en': 'Easy to read, clean', 'th': 'อ่านง่าย เรียบ'},
  'font.kanit.desc': {'en': 'Modern, rounded', 'th': 'ทันสมัย โค้งมน'},
  'font.prompt.desc': {'en': 'Clean, sharp', 'th': 'สะอาดตา คมชัด'},
  'font.mitr.desc': {'en': 'Friendly, cute', 'th': 'เป็นมิตร น่ารัก'},
  'font.noto.desc': {'en': 'Standard, complete', 'th': 'มาตรฐาน ครบทุกตัว'},

  // ── Enums: ThemeMode ──
  'theme.light': {'en': 'Light', 'th': 'สว่าง'},
  'theme.dark': {'en': 'Dark', 'th': 'มืด'},
  'theme.system': {'en': 'System', 'th': 'ตามระบบ'},
};
