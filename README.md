# Lumina — แอปฝึกสมองสำหรับผู้สูงอายุ

> คู่มือสำหรับนักเรียนชั้น ม.5 ที่จะเข้ามาพัฒนาต่อ

---

## สารบัญ
1. [Lumina คืออะไร?](#1-lumina-คืออะไร)
2. [เทคโนโลยีที่ใช้](#2-เทคโนโลยีที่ใช้)
3. [ติดตั้งและรันโปรเจค](#3-ติดตั้งและรันโปรเจค)
4. [โครงสร้างโปรเจค (อธิบายทีละโฟลเดอร์)](#4-โครงสร้างโปรเจค)
5. [แอปทำงานอย่างไร?](#5-แอปทำงานอย่างไร)
6. [ระบบจัดการ State (Riverpod)](#6-ระบบจัดการ-state-riverpod)
7. [ระบบเก็บข้อมูล (Hive)](#7-ระบบเก็บข้อมูล-hive)
8. [ฟีเจอร์แต่ละอัน ทำงานยังไง?](#8-ฟีเจอร์แต่ละอัน)
9. [อยากเพิ่มเกมใหม่ ทำยังไง?](#9-อยากเพิ่มเกมใหม่-ทำยังไง)
10. [คำศัพท์ที่ควรรู้](#10-คำศัพท์ที่ควรรู้)

---

## 1. Lumina คืออะไร?

**Lumina** คือแอปมือถือที่สร้างมาเพื่อ**ผู้สูงอายุ** โดยเฉพาะ มีฟีเจอร์หลัก 4 อย่าง:

| ฟีเจอร์ | ทำอะไร | ตัวอย่าง |
|---------|-------|---------|
| **เกมฝึกสมอง** | เล่นเกมเพื่อฝึกความจำและการคิด | เกมจับคู่เสียง, เกมเรียงลำดับ |
| **แบบประเมินสมอง** | ทดสอบสุขภาพสมอง 4 ขั้นตอน | ถามวัน/เวลา, จำคำ, นับถอยหลัง |
| **จำกัดเวลาจอ** | ตั้งเวลาใช้มือถือไม่เกินกำหนด | ตั้ง 2 ชม./วัน แจ้งเตือนเมื่อเกิน |
| **ตั้งค่า** | ปรับฟอนต์/ขนาดให้อ่านง่าย | เปลี่ยนฟอนต์เป็น Kanit, ขยายตัวอักษร |

### ทำไมตัวหนังสือต้องใหญ่?
เพราะผู้สูงอายุมักมีปัญหาสายตา แอปนี้เลยออกแบบให้:
- ปุ่มใหญ่ (56px ขึ้นไป)
- ตัวอักษรใหญ่ (ปรับได้ถึง 1.4 เท่า)
- สีตัดกันชัด (ตามมาตรฐาน WCAG AA)
- ภาษาไทยทั้งหมด

---

## 2. เทคโนโลยีที่ใช้

| เทคโนโลยี | คือ อะไร | ทำไม ถึงใช้ |
|-----------|---------|-----------|
| **Flutter** | Framework สำหรับสร้างแอปข้ามแพลตฟอร์ม | เขียนครั้งเดียว ใช้ได้ทั้ง iOS, Android, Web |
| **Dart** | ภาษาโปรแกรมของ Flutter | คล้าย Java/JavaScript เรียนรู้ง่าย |
| **Riverpod** | ระบบจัดการ State | ควบคุมข้อมูลที่เปลี่ยนแปลงได้ (เช่น คะแนน) |
| **Hive** | ฐานข้อมูลในเครื่อง (NoSQL) | เก็บคะแนน/การตั้งค่าโดยไม่ต้องต่อ Internet |
| **flutter_tts** | Text-to-Speech | อ่านออกเสียงคำภาษาไทยในเกมจับคู่เสียง |

### ติดตั้งสิ่งที่ต้องมีก่อน
1. [Flutter SDK](https://flutter.dev/docs/get-started/install) (เวอร์ชัน 3.11.3+)
2. Code Editor — แนะนำ [VS Code](https://code.visualstudio.com/) + Flutter Extension
3. Android Studio (สำหรับ Android Emulator) หรือ Chrome (สำหรับ Web)

---

## 3. ติดตั้งและรันโปรเจค

```bash
# 1. เปิด Terminal แล้วเข้าไปในโฟลเดอร์ lumina
cd lumina

# 2. ดาวน์โหลด dependencies (packages ที่แอปต้องใช้)
flutter pub get

# 3. รันแอปบน Chrome (ง่ายสุด)
flutter run -d chrome

# 4. หรือรันบน Android Emulator
flutter run -d emulator-5554

# 5. หรือรันบน Windows
flutter run -d windows
```

ถ้าเจอ error ให้ลอง:
```bash
flutter doctor    # เช็คว่าติดตั้งครบไหม
flutter clean     # ลบ cache แล้ว pub get ใหม่
flutter pub get
```

---

## 4. โครงสร้างโปรเจค

```
lumina/lib/                     ← โค้ดหลักอยู่ในนี้ทั้งหมด!
│
├── main.dart                   ← 🚀 จุดเริ่มต้น (เปิด Hive → รัน App)
├── app.dart                    ← 🎨 ตั้งค่า Theme + หน้าแรก
│
├── core/                       ← ⚙️ ค่ากลางที่ใช้ทั้งแอป
│   ├── constants.dart          ←    คำศัพท์ 30 คำ, จำนวนข้อเกม
│   └── theme.dart              ←    สี, ฟอนต์, ขนาดปุ่ม
│
├── features/                   ← 🏗️ ฟีเจอร์หลัก (แต่ละอันอยู่คนละโฟลเดอร์)
│   ├── home/                   ←    หน้าหลัก + เมนูด้านล่าง
│   ├── assessment/             ←    แบบประเมินสมอง (4 ขั้นตอน)
│   ├── games/
│   │   ├── sound_match/        ←    เกมจับคู่เสียง
│   │   └── sequence/           ←    เกมเรียงลำดับ
│   ├── history/                ←    ประวัติคะแนน
│   ├── screen_time/            ←    จำกัดเวลาหน้าจอ
│   ├── settings/               ←    ตั้งค่าฟอนต์/ขนาด
│   └── ai_tips/                ←    คำแนะนำสุขภาพรายวัน
│
└── shared/                     ← 🔧 โค้ดที่หลายฟีเจอร์ใช้ร่วมกัน
    ├── storage/                ←    ระบบเก็บข้อมูล (Hive)
    ├── utils/                  ←    เครื่องมือช่วย (แปลงวันที่ไทย)
    └── widgets/                ←    Widget สำเร็จรูป (ปุ่ม, Dialog)
```

### หลักการจัดโฟลเดอร์: Feature-First
แทนที่จะรวมไฟล์ตามประเภท (เช่น models/, views/, controllers/) แอปนี้แบ่งตาม**ฟีเจอร์**:
- อยากแก้เกมจับคู่เสียง? → ไปที่ `features/games/sound_match/`
- อยากแก้แบบประเมิน? → ไปที่ `features/assessment/`
- อยากเพิ่มเกมใหม่? → สร้างโฟลเดอร์ใหม่ใน `features/games/`

---

## 5. แอปทำงานอย่างไร?

### 5.1 เมื่อเปิดแอป (main.dart)

```
1. เปิด Hive (ฐานข้อมูล) → เปิด Box 3 กล่อง
2. สร้าง ProviderScope (ตัวจัดการ State)
3. รัน LuminaApp (app.dart)
4. โหลด Theme + ฟอนต์ที่ตั้งไว้
5. แสดง HomeScreen (หน้าหลัก)
```

### 5.2 หน้าหลัก (HomeScreen)
มี **Bottom Navigation Bar** 4 แท็บ:
```
┌──────────┬──────────┬──────────┬──────────┐
│ ฝึกสมอง  │  ประเมิน  │ จำกัดเวลา │  ตั้งค่า  │
│   🧠     │   📋     │   📱     │   ⚙️    │
└──────────┴──────────┴──────────┴──────────┘
```

### 5.3 การเก็บข้อมูล
แอปนี้**ไม่ต้องต่อ Internet** ข้อมูลทุกอย่างเก็บในเครื่องผ่าน **Hive**:
```
assessment_results  → เก็บผลประเมิน (สูงสุด 100 รายการ)
game_scores         → เก็บคะแนนเกม (สูงสุด 200 รายการ)
screen_time_settings → เก็บการตั้งค่าเวลา + ฟอนต์
```

---

## 6. ระบบจัดการ State (Riverpod)

### State คืออะไร?
**State** = ข้อมูลที่เปลี่ยนแปลงได้ เช่น คะแนนปัจจุบัน, ข้อที่กำลังเล่น, เวลาที่ใช้ไป

### ทำไมต้องใช้ Riverpod?
ถ้าไม่มี State Management เวลาคะแนนเปลี่ยน UI จะไม่อัปเดต ต้องมีระบบที่บอก UI ว่า "เฮ้ คะแนนเปลี่ยนแล้วนะ อัปเดตหน้าจอด้วย!"

### วิธีทำงาน (ง่าย ๆ)

```
   User กดปุ่ม
       │
       ▼
   ref.read(provider.notifier).doSomething()
       │
       ▼
   Notifier เปลี่ยน State
       │
       ▼
   ref.watch(provider) ← UI ดู State อยู่
       │
       ▼
   Flutter สร้าง Widget ใหม่ (อัปเดตหน้าจอ)
```

### ตัวอย่างจริงในแอป

```dart
// ── ไฟล์ Provider (sound_match_provider.dart) ──

// State: เก็บข้อมูลเกม
class SoundMatchState {
  final int score;         // คะแนน
  final int currentRound;  // ข้อปัจจุบัน
  final bool isComplete;   // จบเกมแล้วหรือยัง
}

// Notifier: จัดการ logic
class SoundMatchNotifier extends Notifier<SoundMatchState> {
  void selectAnswer(String word) {
    // ตรวจคำตอบ ถ้าถูก +1 คะแนน
    state = state.copyWith(score: state.score + 1);
  }
}

// ── ไฟล์ UI (sound_match_game.dart) ──

// อ่าน State
final state = ref.watch(soundMatchProvider);
Text('คะแนน: ${state.score}');  // UI อัปเดตอัตโนมัติเมื่อ score เปลี่ยน

// เรียก Action
ref.read(soundMatchProvider.notifier).selectAnswer('แมว');
```

### Provider ทั้งหมดในแอป

| Provider | เก็บข้อมูลอะไร |
|----------|---------------|
| `assessmentProvider` | แบบประเมิน: ข้อปัจจุบัน, คะแนน, คำที่สุ่ม |
| `soundMatchProvider` | เกมจับคู่เสียง: ข้อ, คะแนน, ตัวเลือก |
| `sequenceGameProvider` | เกมเรียงลำดับ: ข้อ, ลำดับที่แตะ, คะแนน |
| `screenTimeProvider` | เวลาหน้าจอ: เวลาที่ใช้, เวลาจำกัด, ประวัติสัปดาห์ |
| `settingsProvider` | การตั้งค่า: ฟอนต์, ขนาดตัวอักษร |

---

## 7. ระบบเก็บข้อมูล (Hive)

### Hive คืออะไร?
Hive เป็น**ฐานข้อมูลในเครื่อง** (เหมือน SQLite แต่ง่ายกว่า) เก็บข้อมูลเป็น key-value

### วิธีใช้ในแอป

```dart
// เปิดกล่อง (ทำตอน main.dart)
await Hive.initFlutter();
await Hive.openBox('game_scores');

// เขียนข้อมูล
final box = Hive.box('game_scores');
box.put('scores', [{'score': 8, 'total': 10}]);

// อ่านข้อมูล
final scores = box.get('scores');
```

### StorageService: ตัวกลางเข้าถึง Hive
แทนที่จะเรียก Hive ตรง ๆ ทุกที่ เราสร้าง `StorageService` เป็น**ตัวกลาง**:

```dart
// แทนที่จะเขียน Hive ตรง ๆ...
final box = Hive.box('game_scores');
final list = box.get('scores') as List;
list.add(score.toMap());
box.put('scores', list);

// ใช้ StorageService แทน (สั้นกว่า ปลอดภัยกว่า)
StorageService().saveGameScore(score);
```

---

## 8. ฟีเจอร์แต่ละอัน

### 8.1 เกมจับคู่เสียง (Sound Match)

**ไฟล์ที่เกี่ยวข้อง:**
```
features/games/sound_match/
├── sound_match_game.dart       ← หน้าเล่นเกม (UI)
├── sound_match_provider.dart   ← Logic เกม (State)
├── sound_match_result.dart     ← หน้าแสดงผล
└── word_emoji_map.dart         ← ตาราง คำ→Emoji (เช่น 'แมว'→'🐱')
```

**วิธีทำงาน:**
1. `startGame()` → สุ่มคำ 10 คำจาก wordPool → สร้างตัวเลือก 4 ตัวต่อข้อ
2. TTS อ่านออกเสียงคำ → User เลือก Emoji → `selectAnswer()` ตรวจคำตอบ
3. แสดง Feedback 1.5 วินาที (เขียว=ถูก, แดง=ผิด) → `advanceRound()`
4. จบ 10 ข้อ → บันทึกลง Hive → แสดงผลพร้อมดาว

### 8.2 เกมเรียงลำดับ (Sequence)

**ไฟล์ที่เกี่ยวข้อง:**
```
features/games/sequence/
├── sequence_game.dart          ← หน้าเล่นเกม (Grid 2x2)
├── sequence_provider.dart      ← Logic เกม
├── sequence_data.dart          ← ชุดข้อมูล 5 หัวข้อ
└── sequence_result.dart        ← หน้าแสดงผล
```

**ชุดข้อมูล 5 หัวข้อ:**
1. กิจวัตรประจำวัน (ตื่นนอน → เข้านอน)
2. ช่วงเวลาในวัน (เช้า → กลางคืน)
3. ขนาดสัตว์ (มด → ช้าง)
4. ขั้นตอนซักผ้า (ซัก → พับ)
5. ขั้นตอนปลูกต้นไม้ (ขุดดิน → ต้นอ่อนงอก)

### 8.3 แบบประเมินสมอง (Assessment)

**ไฟล์ที่เกี่ยวข้อง:**
```
features/assessment/
├── assessment_screen.dart      ← หน้าหลัก + Progress Bar
├── assessment_state.dart       ← State + Logic (คำนวณคะแนน)
├── result_screen.dart          ← หน้าผลลัพธ์ (วงกลมคะแนน + คำแนะนำ)
└── steps/
    ├── step_date_time.dart     ← ขั้นตอน 1: เลือกวัน/เวลา
    ├── step_memorize.dart      ← ขั้นตอน 2: จำคำ 3 คำ (10 วินาที)
    ├── step_countdown.dart     ← ขั้นตอน 3: นับถอยหลัง (Number Pad)
    └── step_recall.dart        ← ขั้นตอน 4: เลือกคำที่จำได้
```

**การให้คะแนน (รวม 10 คะแนน):**
```
ขั้นตอน 1: ตอบวันถูก = 1, ตอบเวลาถูก = 1        (สูงสุด 2)
ขั้นตอน 2: ไม่มีคะแนน (แค่จำ)                    (สูงสุด 0)
ขั้นตอน 3: ตอบถูกข้อละ 1 คะแนน (5 ข้อ)           (สูงสุด 5)
ขั้นตอน 4: จำคำได้ข้อละ 1 คะแนน (เลือก 3 จาก 6) (สูงสุด 3)
                                          รวม = 10 คะแนน
```

### 8.4 จำกัดเวลาหน้าจอ (Screen Time)

**ไฟล์ที่เกี่ยวข้อง:**
```
features/screen_time/
├── screen_time_screen.dart     ← UI (วงกลม, ตั้งเวลา, กราฟ 7 วัน)
└── screen_time_provider.dart   ← Logic จับเวลา (Timer ทุก 1 วินาที)
```

**สิ่งพิเศษ:**
- Timer ทุก 1 วินาที → อัปเดต UI
- บันทึกลง Hive ทุก 10 วินาที (ประหยัดแบต)
- เปิดแอปใหม่ → คำนวณเวลาที่ผ่านไปอัตโนมัติ (resume tracking)
- เปลี่ยนวัน → ย้ายข้อมูลเก่าไป week history อัตโนมัติ

### 8.5 ตั้งค่า (Settings)

**ไฟล์ที่เกี่ยวข้อง:**
```
features/settings/
├── settings_screen.dart        ← UI เลือกฟอนต์ + ขนาด
└── settings_provider.dart      ← เก็บ/โหลด ค่าจาก Hive
```

**ฟอนต์ที่เลือกได้:**
| ชื่อ | ลักษณะ |
|------|--------|
| Sarabun | อ่านง่าย เรียบ |
| Kanit | ทันสมัย โค้งมน |
| Prompt | สะอาดตา คมชัด |
| Mitr | เป็นมิตร น่ารัก |
| Noto Sans Thai | มาตรฐาน ครบทุกตัว |

---

## 9. อยากเพิ่มเกมใหม่ ทำยังไง?

### ขั้นตอน 1: สร้างโฟลเดอร์
```
features/games/my_new_game/
├── my_new_game.dart           ← UI ของเกม
├── my_new_game_provider.dart  ← State + Logic
└── my_new_game_result.dart    ← หน้าผล (ใช้ GameResultScreen)
```

### ขั้นตอน 2: สร้าง Provider

```dart
// my_new_game_provider.dart

class MyGameState {
  final int score;
  final int currentRound;
  final bool isComplete;
  // ... constructor + copyWith
}

class MyGameNotifier extends Notifier<MyGameState> {
  @override
  MyGameState build() => const MyGameState();

  void startGame() {
    state = MyGameState(/* เริ่มต้นใหม่ */);
  }

  void submitAnswer(/* ... */) {
    // ตรวจคำตอบ → อัปเดต score
  }

  void nextRound() {
    // ไปข้อถัดไป หรือ จบเกม + บันทึกคะแนน
  }
}

final myGameProvider = NotifierProvider<MyGameNotifier, MyGameState>(
  MyGameNotifier.new,
);
```

### ขั้นตอน 3: สร้างหน้าผล

```dart
// my_new_game_result.dart

class MyGameResult extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myGameProvider);
    return GameResultScreen(  // ใช้ Widget สำเร็จรูป!
      title: 'ผลคะแนน',
      score: state.score,
      total: state.totalRounds,
      onPlayAgain: () { /* เริ่มใหม่ */ },
      onGoHome: () => Navigator.of(context).pop(),
    );
  }
}
```

### ขั้นตอน 4: เพิ่มปุ่มในหน้าหลัก

เปิดไฟล์ `features/home/home_screen.dart` แล้วเพิ่ม `_GameCard`:

```dart
_GameCard(
  icon: Icons.my_icon,
  title: 'เกมใหม่',
  subtitle: 'คำอธิบายเกม',
  color: const Color(0xFFE3F2FD),
  iconColor: Colors.blue,
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyNewGame()),
    );
  },
),
```

### ขั้นตอน 5: บันทึกคะแนน

```dart
// ใน Notifier ของเกม
Future<void> _saveScore() async {
  final score = GameScore(
    date: DateTime.now(),
    gameType: 'my_new_game',  // ชื่อเกม (ห้ามซ้ำกับเกมอื่น)
    score: state.score,
    total: state.totalRounds,
    durationSeconds: /* เวลาที่เล่น */,
  );
  await StorageService().saveGameScore(score);
}
```

เท่านี้! HistoryScreen จะแสดงคะแนนเกมใหม่อัตโนมัติ

---

## 10. คำศัพท์ที่ควรรู้

| คำ | ความหมาย | ตัวอย่างในโปรเจค |
|----|---------|-----------------|
| **Widget** | ส่วนประกอบ UI ทุกอย่างใน Flutter | `Text()`, `ElevatedButton()`, `Card()` |
| **State** | ข้อมูลที่เปลี่ยนแปลงได้ | คะแนน, ข้อปัจจุบัน, เวลาที่ใช้ |
| **Provider** | ตัวส่งข้อมูลจาก State ไป UI | `soundMatchProvider` |
| **Notifier** | ตัวจัดการ State (มี method ต่าง ๆ) | `SoundMatchNotifier.selectAnswer()` |
| **ref.watch()** | อ่าน State (UI อัปเดตเมื่อเปลี่ยน) | `ref.watch(soundMatchProvider)` |
| **ref.read()** | เรียก Action (ไม่ทำให้ UI rebuild) | `ref.read(provider.notifier).start()` |
| **Hive Box** | "กล่อง" เก็บข้อมูลใน Hive | `Hive.box('game_scores')` |
| **Singleton** | Object ที่มีแค่ตัวเดียวในแอป | `StorageService()` |
| **copyWith()** | สร้าง State ใหม่จากของเดิม (เปลี่ยนบางค่า) | `state.copyWith(score: 5)` |
| **ConsumerWidget** | Widget ที่ใช้ Riverpod ได้ | `class MyScreen extends ConsumerWidget` |
| **CustomPaint** | วาดกราฟิกเอง (วงกลม, กราฟ) | `_CircularTimerPainter` |
| **TTS** | Text-to-Speech (แปลงข้อความเป็นเสียง) | เสียงอ่านคำในเกมจับคู่เสียง |
| **WCAG AA** | มาตรฐาน Accessibility ระดับ AA | สีตัดกันชัด (contrast ratio ≥ 4.5:1) |
| **Buddhist Era** | ปีพุทธศักราช (ค.ศ. + 543) | 2026 → 2569 |

---

## เริ่มต้นจากไหนดี?

1. **อ่านโค้ด `main.dart` + `app.dart`** → เข้าใจจุดเริ่มต้น
2. **ดู `home_screen.dart`** → เข้าใจโครงสร้างหน้าหลัก
3. **ลองอ่าน `sound_match_provider.dart`** → เข้าใจ State Management
4. **ลองอ่าน `storage_service.dart`** → เข้าใจการเก็บข้อมูล
5. **ลองเพิ่มเกมใหม่ตามขั้นตอนในข้อ 9** → ฝึกเขียนจริง!

> **Tip:** รันแอปบน Chrome (`flutter run -d chrome`) แล้วลองเล่นทุกฟีเจอร์ก่อน จะช่วยให้เข้าใจโค้ดเร็วขึ้นมาก!
