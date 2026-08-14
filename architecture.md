# Demenish AI — Architecture Document

> เวอร์ชัน 2.0.0 (เดิมชื่อ Lumina) · Bundle ID `com.demenishai.app`
> เอกสารนี้ครอบคลุมทั้งฐานเดิม (เกม/ประเมิน/screen time) และส่วนขยาย v2
> (โปรไฟล์, โทรครอบครัว, นัดหมาย, flash card, สแกม, กล้อง/ML Kit, LINE)

## 1. สถาปัตยกรรมระดับสูง (High-Level Architecture)

```
┌─────────────────────────────────────────────────────────┐
│                    Demenish AI App                      │
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
│  │  ┌──────────────┐ ┌──────────────┐ ┌───────────┐  │  │
│  │  │ soundMatch   │ │ memoryMatch  │ │ colorSeq  │  │  │
│  │  │ Provider     │ │ Provider     │ │ Provider  │  │  │
│  │  ├──────────────┤ ├──────────────┤ ├───────────┤  │  │
│  │  │ assessment   │ │ screenTime   │ │ settings  │  │  │
│  │  │ Provider     │ │ Provider     │ │ Provider  │  │  │
│  │  └──────┬───────┘ └──────┬──────┘ └─────┬─────┘  │  │
│  └─────────┼───────────────┼───────────────┼────────┘  │
│            │               │               │            │
│  ┌─────────┴───────────────┴───────────────┴────────┐  │
│  │       Service Layer (Google Sheets + Storage)     │  │
│  │  ┌──────────────────────┐                         │  │
│  │  │ GoogleSheetsService  │  (Singleton + Cache)    │  │
│  │  └──────────┬───────────┘                         │  │
│  └─────────────┼────────────────────────────────────┘  │
│                │                                        │
│  ┌─────────────┴────────────────────────────────────┐  │
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
│   ├── splash/
│   │   └── splash_screen.dart         # หน้า Splash Screen
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
│   │   ├── memory_match/              # เกมจับคู่ภาพ
│   │   │   ├── memory_match_game.dart     # หน้าเล่นเกม
│   │   │   ├── memory_match_provider.dart # State + Logic
│   │   │   └── memory_match_result.dart   # หน้าผลคะแนน
│   │   │
│   │   ├── color_sequence/            # เกมลำดับสี
│   │   │   ├── color_sequence_game.dart     # หน้าเล่นเกม
│   │   │   ├── color_sequence_provider.dart # State + Logic
│   │   │   └── color_sequence_result.dart   # หน้าผลคะแนน
│   │   │
│   │   └── sequence/                  # เกมเรียงลำดับ (unused)
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
│   │   └── settings_provider.dart     # จัดเก็บ ฟอนต์ + ขนาด + ธีม + สีพื้นหลัง
│   │
│   └── ai_tips/
│       └── tips_widget.dart           # Widget คำแนะนำรายวัน
│
└── shared/                            # โค้ดที่ใช้ร่วมกัน
    ├── services/                      # บริการภายนอก
    │   └── google_sheets_service.dart # ดึงข้อมูลจาก Google Sheets (Singleton + Cache)
    │
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

### 3.3 Singleton Pattern (StorageService + GoogleSheetsService)
`StorageService` ใช้ Singleton เพื่อให้ทุกส่วนของแอปเข้าถึง Hive ผ่านจุดเดียว:
```dart
class StorageService {
  StorageService._();
  static final _instance = StorageService._();
  factory StorageService() => _instance;
}
```
`GoogleSheetsService` ใช้ Singleton + Cache เพื่อดึงข้อมูลจาก Google Sheets โดยไม่ต้องเรียกซ้ำ:
```dart
class GoogleSheetsService {
  GoogleSheetsService._();
  static final _instance = GoogleSheetsService._();
  factory GoogleSheetsService() => _instance;
  // cache data ไว้ในหน่วยความจำ
}
```

### 3.4 Composition over Inheritance
UI สร้างจาก Widget เล็ก ๆ ประกอบกัน แทนที่จะสืบทอด:
- `_GreetingCard` + `_GameCard` + `AiTipsCard` ประกอบกันเป็น Games Tab
- `_ScoreBar` + `_SpeakerButton` + `_OptionCard` ประกอบกันเป็น Sound Match Game

---

## 4. Data Flow (การไหลของข้อมูล)

### 4.1 การเล่นเกมจับคู่ภาพ (Memory Match)
```
User กดเล่น
    │
    ▼
MemoryMatchNotifier.startGame()
    │  สร้างการ์ดคู่ + สลับตำแหน่ง
    ▼
UI แสดง Grid การ์ดคว่ำ
    │
    ▼
User เปิดการ์ดใบที่ 1
    │
    ▼
MemoryMatchNotifier.flipCard(index)
    │  เปิดการ์ด + รอเปิดใบที่ 2
    ▼
User เปิดการ์ดใบที่ 2
    │
    ▼
MemoryMatchNotifier.flipCard(index)
    │  ตรวจว่าตรงกันหรือไม่
    │  ตรงกัน → เก็บคู่ / ไม่ตรง → คว่ำกลับ
    ▼
ถ้าเปิดครบทุกคู่ → บันทึกคะแนนลง Hive
    │
    ▼
StorageService.saveGameScore()
    │
    ▼
Navigate → MemoryMatchResult (แสดงดาว + คะแนน)
```

### 4.2 การเล่นเกมลำดับสี (Color Sequence)
```
User กดเล่น
    │
    ▼
ColorSequenceNotifier.startGame()
    │  สร้างลำดับสีที่ต้องจำ
    ▼
UI แสดงลำดับสี (flash ทีละสี)
    │
    ▼
User กดสีตามลำดับ
    │
    ▼
ColorSequenceNotifier.selectColor(color)
    │  ตรวจลำดับ ถูก → ต่อ / ผิด → จบ
    ▼
ถ้ากดครบลำดับ → เพิ่มระดับ หรือจบเกม
    │
    ▼
StorageService.saveGameScore()
    │
    ▼
Navigate → ColorSequenceResult (แสดงดาว + คะแนน)
```

### 4.3 การจับเวลาหน้าจอ
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

### 4.4 แบบประเมิน
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
| `memoryMatchProvider` | `MemoryMatchState` | จัดการเกมจับคู่ภาพ |
| `colorSequenceProvider` | `ColorSequenceState` | จัดการเกมลำดับสี |
| `screenTimeProvider` | `ScreenTimeState` | จับเวลา + ประวัติสัปดาห์ |
| `settingsProvider` | `SettingsState` | ฟอนต์ + ขนาด + ธีม + สีพื้นหลัง |
| `profileProvider` | `UserProfile` | ชื่อ/อายุ/เพศ + รายชื่อครอบครัว [v2] |
| `appointmentsProvider` | `List<Appointment>` | นัดหมาย + ตั้ง/ยกเลิกแจ้งเตือน [v2] |
| `screenDistanceProvider` | `ScreenDistanceState` | เตือนระยะจอ (timer + กล้อง, foreground) [v2] |
| `drowsinessProvider` | `DrowsinessState` | ตรวจง่วง (timer + กล้อง) + แจ้ง LINE [v2] |

### 5.2 หลักการ State Management
1. **Immutable State**: ทุก State class ใช้ `final` fields + `copyWith()` method
2. **Unidirectional Data Flow**: UI → Notifier → State → UI (ไม่ย้อนกลับ)
3. **Single Source of Truth**: ข้อมูลอยู่ใน Riverpod Provider ที่เดียว, Hive เป็นแค่ Persistence

---

## 6. Theme & Design System

### 6.1 สี (Teal/Mint Palette)

**Light Mode:**
```
Primary:        #3D7F80  (Teal หลัก)
Secondary:      #5BC5A7  (Mint เสริม)
Success:        #1B7A3D  (เขียวเข้ม)
Text Primary:   #2D3436
Text Secondary: #6B7B8A
Background:     #F0F5F5
```

**Dark Mode:**
```
Primary:        #6FD5B7  (Mint สว่าง)
Secondary:      #4A8B8C  (Teal เข้ม)
Background:     #162224
Surface:        #1E2D2F
```

> หมายเหตุ: รองรับ Light/Dark mode + 8 background presets ให้ผู้ใช้เลือก

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
| http | 1.4.0 | HTTP client (Google Sheets + LINE push) |
| url_launcher | 6.3.x | โทรออก `tel:` (โทรครอบครัว) [v2] |
| image_picker | 1.1.x | เลือกรูปสมาชิกครอบครัว [v2] |
| flutter_local_notifications | 19.4.x | แจ้งเตือนในเครื่อง (นัดหมาย/พัก) [v2] |
| timezone | 0.10.x | timezone สำหรับตั้งเวลาแจ้งเตือน (Asia/Bangkok) [v2] |
| camera | 0.11.x | เปิดกล้องหน้าถ่าย 1 เฟรม [v2] |
| google_mlkit_face_detection | 0.13.x | ตรวจใบหน้า on-device (ระยะจอ/ง่วง) [v2] |
| permission_handler | 11.3.x | ขอสิทธิ์กล้อง [v2] |

> **Gradle:** เปิด core library desugaring (`desugar_jdk_libs`) — จำเป็นสำหรับ flutter_local_notifications

---

## 12. ส่วนขยาย v2.0.0 (Demenish AI Additions)

### 12.1 Service Layer เพิ่มเติม (`shared/services/`)
| Service | หน้าที่ | ทำงานที่ไหน |
|---------|--------|-------------|
| `NotificationService` | schedule/cancel/showNow + timezone | on-device |
| `ScamDetector` | rule-based ไทย (keyword + URL heuristic) → risk + reasons | on-device, offline |
| `FaceSamplingService` | เปิดกล้องหน้า → 1 เฟรม → ML Kit → face ratio/eye/head → ปิด | on-device |
| `LineService` | POST ไป Cloudflare Worker `/push` (no-op ถ้าไม่ตั้งค่า) | ต้องต่อเน็ต |

### 12.2 Hive Boxes เพิ่มเติม
| Box | เก็บ |
|-----|------|
| `user_profile` | โปรไฟล์ (ชื่อ/อายุ/เพศ) + รายชื่อครอบครัว (ชื่อ/เบอร์/รูป base64/lineUserId) |
| `appointments` | รายการนัดหมาย (`items`) |
| `flash_card` | วันที่แสดงการ์ดล่าสุด (`lastShown`) |
| `screen_time_settings` | + keys ใหม่: `screenDistanceEnabled/IntervalMin`, `drowsyEnabled/IntervalMin` |

### 12.3 Backend Layer (LINE push proxy)
```
Demenish AI App ──POST /push (x-app-key)──▶ Cloudflare Worker ──▶ LINE Messaging API
ครอบครัวแอด LINE OA ──follow──▶ Worker /webhook (verify signature) ──▶ ตอบ userId
```
- โค้ด + คู่มือ: `docs/backend/` (cloudflare-worker.js + README.md)
- Config ฝั่งแอปผ่าน `--dart-define=LINE_WORKER_URL=... --dart-define=LINE_APP_KEY=...`
- ห้ามฝัง channel access token ในแอป → เก็บฝั่ง Worker เท่านั้น

### 12.4 หลักการฟีเจอร์กล้อง (ข้อ 4 & 6)
- **Interval sampling** (ไม่ใช่ stream) — เปิดกล้องแวบเดียวทุก N นาที แล้วปิด
- **Foreground-only** — ผูกกับ `WidgetsBindingObserver` ที่ Home (parity iOS/Android + ประหยัดแบต)
- **Opt-in** — ปิดไว้ก่อน ผู้ใช้เปิดเอง + ขอสิทธิ์กล้องผ่าน `permission_handler`
- เกณฑ์ที่ต้องจูนบนเครื่องจริง: `kTooCloseRatio` (0.55), `kEyesClosedThreshold` (0.25)

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
