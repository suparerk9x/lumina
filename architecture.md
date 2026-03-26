# Lumina — Architecture Document

## 1. สถาปัตยกรรมระดับสูง (High-Level Architecture)

```
┌─────────────────────────────────────────────────────────┐
│                      Lumina App                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │              UI Layer (Flutter Widgets)            │  │
│  │  ┌──────────┐ ┌──────────┐ ┌────────┐ ┌────────┐ │  │
│  │  │ Games Tab│ │Assessment│ │ Screen │ │Settings│ │  │
│  │  │          │ │   Tab    │ │  Time  │ │  Tab   │ │  │
│  │  └────┬─────┘ └────┬─────┘ └───┬────┘ └───┬────┘ │  │
│  └───────┼────────────┼───────────┼───────────┼──────┘  │
│          │            │           │           │          │
│  ┌───────┴────────────┴───────────┴───────────┴──────┐  │
│  │           State Layer (Riverpod Notifiers)        │  │
│  │  ┌──────────────┐ ┌────────────┐ ┌─────────────┐ │  │
│  │  │ soundMatch   │ │ assessment │ │ screenTime  │ │  │
│  │  │ Provider     │ │ Provider   │ │ Provider    │ │  │
│  │  ├──────────────┤ ├────────────┤ ├─────────────┤ │  │
│  │  │ sequence     │ │ settings   │ │             │ │  │
│  │  │ Provider     │ │ Provider   │ │             │ │  │
│  │  └──────┬───────┘ └─────┬──────┘ └──────┬──────┘ │  │
│  └─────────┼───────────────┼───────────────┼────────┘  │
│            │               │               │            │
│  ┌─────────┴───────────────┴───────────────┴────────┐  │
│  │           Data Layer (Hive Local Storage)         │  │
│  │  ┌──────────────────────────────────────────────┐ │  │
│  │  │            StorageService (Singleton)         │ │  │
│  │  └──────┬────────────┬─────────────┬────────────┘ │  │
│  │         │            │             │              │  │
│  │  ┌──────┴──┐  ┌──────┴──┐  ┌───────┴──────────┐  │  │
│  │  │assess-  │  │ game    │  │ screen_time      │  │  │
│  │  │ment_    │  │ _scores │  │ _settings        │  │  │
│  │  │results  │  │         │  │                  │  │  │
│  │  └─────────┘  └─────────┘  └──────────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 2. โครงสร้างโฟลเดอร์ (Folder Structure)

```
lumina/lib/
│
├── main.dart                          # จุดเริ่มต้นแอป (Entry Point)
├── app.dart                           # MaterialApp + Theme + Home
│
├── core/                              # ค่าคงที่และธีมกลาง
│   ├── constants.dart                 # ค่าคงที่ (คำศัพท์, จำนวนข้อ)
│   └── theme.dart                     # สี, ฟอนต์, ปุ่ม (WCAG AA)
│
├── features/                          # ฟีเจอร์หลัก (แบ่งตามหน้าที่)
│   ├── home/
│   │   └── home_screen.dart           # หน้าหลัก + Bottom Navigation
│   │
│   ├── assessment/                    # แบบประเมินสมอง
│   │   ├── assessment_screen.dart     # หน้าจอหลัก + Progress Bar
│   │   ├── assessment_state.dart      # State + Notifier (Riverpod)
│   │   ├── result_screen.dart         # หน้าแสดงผลลัพธ์
│   │   └── steps/                     # แต่ละขั้นตอน
│   │       ├── step_date_time.dart    # ขั้นตอน 1: ถามวัน/เวลา
│   │       ├── step_memorize.dart     # ขั้นตอน 2: จำคำ 3 คำ
│   │       ├── step_countdown.dart    # ขั้นตอน 3: นับถอยหลัง
│   │       └── step_recall.dart       # ขั้นตอน 4: ทวนคำ
│   │
│   ├── games/                         # เกมฝึกสมอง
│   │   ├── sound_match/               # เกมจับคู่เสียง
│   │   │   ├── sound_match_game.dart  # หน้าเล่นเกม
│   │   │   ├── sound_match_provider.dart # State + Logic
│   │   │   ├── sound_match_result.dart   # หน้าผลคะแนน
│   │   │   └── word_emoji_map.dart    # แผนที่ คำ→Emoji
│   │   │
│   │   └── sequence/                  # เกมเรียงลำดับ
│   │       ├── sequence_game.dart     # หน้าเล่นเกม
│   │       ├── sequence_provider.dart # State + Logic
│   │       ├── sequence_data.dart     # ชุดข้อมูลลำดับ
│   │       └── sequence_result.dart   # หน้าผลคะแนน
│   │
│   ├── history/
│   │   └── history_screen.dart        # ประวัติคะแนนทั้งหมด
│   │
│   ├── screen_time/                   # จำกัดเวลาหน้าจอ
│   │   ├── screen_time_screen.dart    # หน้าจอ (วงกลม, ตั้งเวลา, กราฟ)
│   │   └── screen_time_provider.dart  # Logic การจับเวลา
│   │
│   ├── settings/                      # ตั้งค่า
│   │   ├── settings_screen.dart       # หน้าตั้งค่า
│   │   └── settings_provider.dart     # จัดเก็บ Font & Scale
│   │
│   └── ai_tips/
│       └── tips_widget.dart           # Widget คำแนะนำรายวัน
│
└── shared/                            # โค้ดที่ใช้ร่วมกัน
    ├── storage/                       # ระบบจัดเก็บข้อมูล (Hive)
    │   ├── storage_service.dart       # Singleton service หลัก
    │   ├── assessment_result.dart     # Model ผลประเมิน
    │   ├── game_score.dart            # Model คะแนนเกม
    │   └── hive_boxes.dart            # ชื่อ Box ทั้งหมด
    │
    ├── utils/
    │   └── thai_date.dart             # จัดรูปแบบวันที่ไทย (พ.ศ.)
    │
    └── widgets/                       # Widget ที่ใช้ซ้ำ
        ├── game_result_screen.dart    # หน้าผลเกม (ดาว + คะแนน)
        ├── exit_dialog.dart           # Dialog ยืนยันออก
        ├── empty_state.dart           # หน้าว่าง (ไม่มีข้อมูล)
        └── shimmer_loading.dart       # Loading Animation
```

---

## 3. Design Patterns ที่ใช้

### 3.1 Feature-First Architecture
โค้ดแบ่งตามฟีเจอร์ (assessment, games, settings) ไม่ใช่ตามประเภท (models, views, controllers) ทำให้:
- หาไฟล์ง่าย — อยากแก้เกมจับคู่เสียง ก็เข้าไปที่ `features/games/sound_match/`
- เพิ่มฟีเจอร์ใหม่ได้ง่าย — สร้างโฟลเดอร์ใหม่ใน `features/`
- แต่ละฟีเจอร์ไม่พึ่งพากัน (Loose Coupling)

### 3.2 Riverpod State Management
ใช้ `Notifier` + `NotifierProvider` จัดการ State:

```dart
// 1. สร้าง State class (immutable)
class SoundMatchState {
  final int score;
  final int currentRound;
  // ... copyWith() method
}

// 2. สร้าง Notifier (จัดการ logic)
class SoundMatchNotifier extends Notifier<SoundMatchState> {
  void selectAnswer(String word) { ... }
  void advanceRound() { ... }
}

// 3. สร้าง Provider (จุดเชื่อมต่อ UI ↔ State)
final soundMatchProvider = NotifierProvider<SoundMatchNotifier, SoundMatchState>(...);

// 4. UI ใช้ ref.watch() อ่าน state, ref.read() เรียก action
final state = ref.watch(soundMatchProvider);
ref.read(soundMatchProvider.notifier).selectAnswer('แมว');
```

### 3.3 Singleton Pattern (StorageService)
`StorageService` ใช้ Singleton เพื่อให้ทุกส่วนของแอปเข้าถึง Hive ผ่านจุดเดียว:
```dart
class StorageService {
  StorageService._();
  static final _instance = StorageService._();
  factory StorageService() => _instance;
}
```

### 3.4 Composition over Inheritance
UI สร้างจาก Widget เล็ก ๆ ประกอบกัน แทนที่จะสืบทอด:
- `_GreetingCard` + `_GameCard` + `AiTipsCard` ประกอบกันเป็น Games Tab
- `_ScoreBar` + `_SpeakerButton` + `_OptionCard` ประกอบกันเป็น Sound Match Game

---

## 4. Data Flow (การไหลของข้อมูล)

### 4.1 การเล่นเกมจับคู่เสียง
```
User กดเล่น
    │
    ▼
SoundMatchNotifier.startGame()
    │  สุ่มคำ 10 ข้อ + ตัวเลือก 4 ตัว
    ▼
UI แสดง Grid 2x2 + เล่นเสียง TTS
    │
    ▼
User เลือกคำตอบ
    │
    ▼
SoundMatchNotifier.selectAnswer(word)
    │  ตรวจคำตอบ + แสดง Feedback (เขียว/แดง)
    ▼
Timer 1.5 วินาที
    │
    ▼
SoundMatchNotifier.advanceRound()
    │  ถ้าข้อสุดท้าย → บันทึกคะแนนลง Hive
    ▼
StorageService.saveGameScore()
    │
    ▼
Navigate → SoundMatchResult (แสดงดาว + คะแนน)
```

### 4.2 การจับเวลาหน้าจอ
```
User กด "เริ่มจับเวลา"
    │
    ▼
ScreenTimeNotifier.startTracking()
    │  บันทึก startTime ลง Hive
    │  เริ่ม Timer ทุก 1 วินาที
    ▼
┌──────────────────────────┐
│  ทุก 1 วินาที:           │
│  - อัปเดต todayUsage     │
│  - เช็คว่าเกินเวลาไหม   │
│                          │
│  ทุก 10 วินาที:          │
│  - บันทึกลง Hive         │
└──────────┬───────────────┘
           │
           ▼ (ถ้าเกินเวลา)
ScreenTimeState.alertShown = true
    │
    ▼
UI แสดง Alert Dialog
    │
    ▼
User เลือก "หยุด" หรือ "ใช้ต่อ"
```

### 4.3 แบบประเมิน
```
User กด "เริ่มประเมิน"
    │
    ▼
AssessmentNotifier.startAssessment()
    │  สุ่มคำ 3 คำ + คำหลอก 3 คำ
    ▼
Step 1: StepDateTime → setDateTimeScore()     (0-2 คะแนน)
    │
    ▼
Step 2: StepMemorize → (ไม่มีคะแนน, แค่จำ)
    │
    ▼
Step 3: StepCountdown → setCountdownScore()   (0-5 คะแนน)
    │
    ▼
Step 4: StepRecall → submitRecall()           (0-3 คะแนน)
    │  คำนวณ recallScore + set isComplete = true
    ▼
AssessmentResultScreen
    │  auto-save ผ่าน saveResult()
    ▼
StorageService.saveAssessmentResult()
```

---

## 5. State Management Architecture

### 5.1 Provider ทั้งหมด

| Provider | State Type | หน้าที่ |
|----------|-----------|---------|
| `assessmentProvider` | `AssessmentState` | จัดการแบบประเมิน 4 ขั้นตอน |
| `soundMatchProvider` | `SoundMatchState` | จัดการเกมจับคู่เสียง |
| `sequenceGameProvider` | `SequenceGameState` | จัดการเกมเรียงลำดับ |
| `screenTimeProvider` | `ScreenTimeState` | จับเวลา + ประวัติสัปดาห์ |
| `settingsProvider` | `SettingsState` | ฟอนต์ + ขนาดตัวอักษร |

### 5.2 หลักการ State Management
1. **Immutable State**: ทุก State class ใช้ `final` fields + `copyWith()` method
2. **Unidirectional Data Flow**: UI → Notifier → State → UI (ไม่ย้อนกลับ)
3. **Single Source of Truth**: ข้อมูลอยู่ใน Riverpod Provider ที่เดียว, Hive เป็นแค่ Persistence

---

## 6. Theme & Design System

### 6.1 สี (WCAG AA Compliant)
```
Primary:       #3B6FD4  (5.2:1 contrast on white)
Success:       #2E7D32  (5.9:1)
Warning:       #E65100  (5.5:1)
Error:         #C62828  (7.8:1)
Text Primary:  #1A1A2E  (15.4:1)
Text Secondary:#4B5563  (7.0:1)
Background:    #F8F9FA
Surface:       #FFFFFF
```

### 6.2 ขนาดตัวอักษร (พร้อม Font Scale)
```
Display Large:   34px × scale  (หัวเรื่องหลัก)
Headline Medium: 24px × scale  (หัวหมวด)
Title Large:     22px × scale  (ชื่อการ์ด)
Body Large:      20px × scale  (เนื้อหาหลัก)
Body Medium:     18px × scale  (เนื้อหาทั่วไป)
Body Small:      16px × scale  (ข้อมูลเสริม)
```

### 6.3 มุมโค้ง (Border Radius)
```
Card:   16px
Button: 12px
Input:  12px
```

---

## 7. Platform-Specific Handling

### 7.1 Web
- **TTS**: ต้องค้นหา Thai voice จาก browser voices list
- **Autoplay**: ต้องมี user interaction ก่อนเล่นเสียง (Web Start Screen)
- **Speech Rate**: 0.8 (เร็วกว่า native)

### 7.2 Native (iOS/Android)
- **TTS**: ใช้ `setLanguage('th-TH')` ตรง ๆ
- **Speech Rate**: 0.4 (ช้ากว่า เพราะ native engine พูดเร็วกว่า)

### 7.3 Desktop (Windows/macOS/Linux)
- โครงสร้างพร้อมแล้ว แต่ยังไม่ได้ปรับแต่งเฉพาะ

---

## 8. Custom Painters

แอปใช้ `CustomPaint` สำหรับกราฟิกที่ซับซ้อน:

| Painter | ไฟล์ | ทำหน้าที่ |
|---------|------|----------|
| `_CircularTimerPainter` | step_memorize.dart | วงกลมนับถอยหลัง (10 วินาที) |
| `_UsageRingPainter` | screen_time_screen.dart | วงกลมแสดงสัดส่วนเวลาใช้งาน |
| `_WeekBarChartPainter` | screen_time_screen.dart | กราฟแท่ง 7 วัน + เส้นจำกัด |

---

## 9. Dependencies

| Package | เวอร์ชัน | ใช้ทำอะไร |
|---------|---------|----------|
| flutter_riverpod | 3.3.1 | State Management |
| hive_flutter | 1.1.0 | Local Database (NoSQL) |
| flutter_tts | 4.2.5 | Text-to-Speech ภาษาไทย |
| audioplayers | 6.6.0 | เล่นเสียง (สำรอง) |
| shared_preferences | 2.5.4 | Preferences พื้นฐาน |
| shimmer | 3.0.0 | Loading Animation |
| go_router | 17.1.0 | Navigation (มีแต่ยังไม่ใช้หลัก) |

---

## 10. Error Handling Strategy

1. **StorageService**: ทุก method ห่อด้วย `try/catch` + `developer.log()`
2. **Malformed Data**: ข้อมูลเสียจะถูกข้าม (skip) ไม่ทำให้แอปล่ม
3. **TTS Errors**: catch แล้ว log, ไม่ crash
4. **Null Safety**: Dart strict null safety ทั้งหมด

---

## 11. การเพิ่มเกมใหม่ (How to Add a New Game)

1. สร้างโฟลเดอร์ใหม่ใน `features/games/` เช่น `features/games/word_puzzle/`
2. สร้าง 3 ไฟล์:
   - `word_puzzle_game.dart` — UI ของเกม
   - `word_puzzle_provider.dart` — State + Logic
   - `word_puzzle_result.dart` — หน้าผลคะแนน (ใช้ `GameResultScreen`)
3. เพิ่ม `_GameCard` ใน `home_screen.dart` เพื่อให้เข้าเกมได้
4. ใช้ `StorageService().saveGameScore()` บันทึกคะแนน (gameType ใหม่)
5. HistoryScreen จะแสดงคะแนนอัตโนมัติ (ผ่าน `getGameScores()`)
