# Lumina — แอปฝึกสมองสำหรับผู้สูงอายุ

> คู่มือสำหรับการพัฒนา App ต่อ

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
| **เกมฝึกสมอง** | เล่นเกมเพื่อฝึกความจำและการคิด | จับคู่เสียง, จับคู่ภาพ, กดปุ่มตามลำดับ (3 เกม) |
| **แบบประเมินสมอง** | ทดสอบสุขภาพสมอง 4 ขั้นตอน | ถามวัน/เวลา, จำคำ, นับถอยหลัง |
| **จำกัดเวลาจอ** | ตั้งเวลาใช้มือถือไม่เกินกำหนด | ตั้ง 2 ชม./วัน แจ้งเตือนเมื่อเกิน |
| **ตั้งค่า** | ปรับธีม/ฟอนต์/ขนาดให้อ่านง่าย | เปลี่ยนโหมดมืด, เลือกสีพื้นหลัง, เปลี่ยนฟอนต์ |

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
| **http** | HTTP client | ดึงข้อมูลเกมจาก Google Sheets |

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
lumina/lib/                     <- โค้ดหลักอยู่ในนี้ทั้งหมด!
|
|- main.dart                    <- จุดเริ่มต้น (เปิด Hive -> รัน App)
|- app.dart                     <- ตั้งค่า Theme (Light/Dark) + Splash Screen
|
|- core/                        <- ค่ากลางที่ใช้ทั้งแอป
|   |- constants.dart           <-    คำศัพท์ 30 คำ, จำนวนข้อเกม
|   +- theme.dart               <-    สี Teal/Mint, ฟอนต์, ขนาดปุ่ม, สีพื้นหลัง 8 แบบ
|
|- features/                    <- ฟีเจอร์หลัก (แต่ละอันอยู่คนละโฟลเดอร์)
|   |- splash/
|   |   +- splash_screen.dart   <-    หน้า Splash แสดงโลโก้ 2 วินาที
|   |- home/                    <-    หน้าหลัก + เมนูด้านล่าง + โลโก้ใน AppBar
|   |- assessment/              <-    แบบประเมินสมอง (4 ขั้นตอน)
|   |- games/
|   |   |- sound_match/         <-    เกมจับคู่เสียง (3 ไฟล์ + word_emoji_map)
|   |   |- memory_match/        <-    เกมจับคู่ภาพ (3 ไฟล์) [ใหม่]
|   |   |- color_sequence/      <-    เกมกดปุ่มตามลำดับ (3 ไฟล์) [ใหม่]
|   |   +- sequence/            <-    เกมเรียงลำดับ (ไม่ได้ใช้งานแล้ว)
|   |- history/                 <-    ประวัติคะแนน
|   |- screen_time/             <-    จำกัดเวลาหน้าจอ
|   |- settings/                <-    ตั้งค่าธีม/ฟอนต์/ขนาด/สีพื้นหลัง
|   +- ai_tips/                 <-    คำแนะนำสุขภาพรายวัน
|
+- shared/                      <- โค้ดที่หลายฟีเจอร์ใช้ร่วมกัน
    |- services/
    |   +- google_sheets_service.dart <- โหลดข้อมูลเกมจาก Google Sheets [ใหม่]
    |- storage/                 <-    ระบบเก็บข้อมูล (Hive)
    |- utils/                   <-    เครื่องมือช่วย (แปลงวันที่ไทย)
    +- widgets/                 <-    Widget สำเร็จรูป (ปุ่ม, Dialog, GameResultScreen)

assets/images/
    +- logo.jpg                 <-    โลโก้ Lumina (ใช้ใน Splash + AppBar)
```

### หลักการจัดโฟลเดอร์: Feature-First
แทนที่จะรวมไฟล์ตามประเภท (เช่น models/, views/, controllers/) แอปนี้แบ่งตาม**ฟีเจอร์**:
- อยากแก้เกมจับคู่เสียง? -> ไปที่ `features/games/sound_match/`
- อยากแก้เกมจับคู่ภาพ? -> ไปที่ `features/games/memory_match/`
- อยากแก้เกมกดปุ่มตามลำดับ? -> ไปที่ `features/games/color_sequence/`
- อยากเพิ่มเกมใหม่? -> สร้างโฟลเดอร์ใหม่ใน `features/games/`

---

## 5. แอปทำงานอย่างไร?

### 5.1 เมื่อเปิดแอป (main.dart -> app.dart -> SplashScreen)

```
1. เปิด Hive (ฐานข้อมูล) -> เปิด Box 4 กล่อง
2. สร้าง ProviderScope (ตัวจัดการ State)
3. รัน LuminaApp (app.dart)
4. โหลด Theme (Light/Dark/System) + ฟอนต์ + สีพื้นหลังที่ตั้งไว้
5. แสดง SplashScreen (โลโก้ + ชื่อแอป) 2 วินาที
6. Fade transition ไป HomeScreen (หน้าหลัก)
```

### 5.2 หน้าหลัก (HomeScreen)
มี **Bottom Navigation Bar** 4 แท็บ:
```
+----------+----------+----------+----------+
| ฝึกสมอง  |  ประเมิน  | จำกัดเวลา |  ตั้งค่า  |
+----------+----------+----------+----------+
```
แท็บ "ฝึกสมอง" จะแสดงโลโก้ Lumina ที่มุมบนซ้ายของ AppBar

### 5.3 การเก็บข้อมูล
แอปนี้ทำงาน**ออฟไลน์ได้** ข้อมูลทุกอย่างเก็บในเครื่องผ่าน **Hive**:
```
assessment_results   -> เก็บผลประเมิน (สูงสุด 100 รายการ)
game_scores          -> เก็บคะแนนเกม (สูงสุด 200 รายการ)
screen_time_settings -> เก็บการตั้งค่าเวลา + ฟอนต์ + ธีม + สีพื้นหลัง
cached_game_data     -> เก็บ cache ข้อมูลเกมจาก Google Sheets (หมดอายุ 30 นาที)
```

### 5.4 Google Sheets Integration
เกมสามารถโหลดข้อมูล (คำศัพท์, Emoji) จาก **Google Sheets ที่ Publish เป็น CSV**:
- ออนไลน์: ดึงข้อมูลจาก Google Sheets แล้วเก็บ cache ใน Hive (30 นาที)
- ออฟไลน์: ใช้ cache เก่า (ถ้ามี) หรือ fallback ใช้ข้อมูล hardcoded ในโค้ด
- ตั้ง URL ได้ที่ `shared/services/google_sheets_service.dart`

---

## 6. ระบบจัดการ State (Riverpod)

### State คืออะไร?
**State** = ข้อมูลที่เปลี่ยนแปลงได้ เช่น คะแนนปัจจุบัน, ข้อที่กำลังเล่น, เวลาที่ใช้ไป

### ทำไมต้องใช้ Riverpod?
ถ้าไม่มี State Management เวลาคะแนนเปลี่ยน UI จะไม่อัปเดต ต้องมีระบบที่บอก UI ว่า "เฮ้ คะแนนเปลี่ยนแล้วนะ อัปเดตหน้าจอด้วย!"

### วิธีทำงาน (ง่าย ๆ)

```
   User กดปุ่ม
       |
       v
   ref.read(provider.notifier).doSomething()
       |
       v
   Notifier เปลี่ยน State
       |
       v
   ref.watch(provider) <- UI ดู State อยู่
       |
       v
   Flutter สร้าง Widget ใหม่ (อัปเดตหน้าจอ)
```

### ตัวอย่างจริงในแอป

```dart
// -- ไฟล์ Provider (sound_match_provider.dart) --

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

// -- ไฟล์ UI (sound_match_game.dart) --

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
| `memoryMatchProvider` | เกมจับคู่ภาพ: การ์ดทั้งหมด, คู่ที่จับได้, จำนวนครั้งที่เปิด, ระดับความยาก |
| `colorSequenceProvider` | เกมกดปุ่มตามลำดับ: ลำดับสี, ด่านปัจจุบัน, เฟสของเกม (แสดง/กด/ถูก/ผิด) |
| `screenTimeProvider` | เวลาหน้าจอ: เวลาที่ใช้, เวลาจำกัด, ประวัติสัปดาห์ |
| `settingsProvider` | การตั้งค่า: ฟอนต์, ขนาดตัวอักษร, โหมดธีม (light/dark/system), สีพื้นหลัง (8 presets) |

---

## 7. ระบบเก็บข้อมูล (Hive)

### Hive คืออะไร?
Hive เป็น**ฐานข้อมูลในเครื่อง** (เหมือน SQLite แต่ง่ายกว่า) เก็บข้อมูลเป็น key-value

### Hive Box ทั้งหมด 4 กล่อง

| ชื่อ Box | เก็บอะไร | ตัวอย่าง key |
|----------|---------|-------------|
| `assessment_results` | ผลประเมินสมอง | `'results'` |
| `game_scores` | คะแนนเกมทุกเกม | `'scores'` |
| `screen_time_settings` | ตั้งค่าเวลา + ฟอนต์ + ธีม | `'fontScaleIndex'`, `'themeModeIndex'`, `'backgroundPresetIndex'` |
| `cached_game_data` | cache ข้อมูลจาก Google Sheets | `'sound_match_csv'`, `'sequence_csv'` + timestamp |

ชื่อ Box ทุกตัวเก็บไว้ใน `shared/storage/hive_boxes.dart` เป็น constant เพื่อป้องกันพิมพ์ผิด

### วิธีใช้ในแอป

```dart
// เปิดกล่อง (ทำตอน main.dart — ใช้ HiveBoxes.all เปิดทุกกล่องอัตโนมัติ)
await Hive.initFlutter();
for (final boxName in HiveBoxes.all) {
  await Hive.openBox(boxName);
}

// เขียนข้อมูล
final box = Hive.box(HiveBoxes.gameScores);
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
|- sound_match_game.dart       <- หน้าเล่นเกม (UI)
|- sound_match_provider.dart   <- Logic เกม (State)
|- sound_match_result.dart     <- หน้าแสดงผล
+- word_emoji_map.dart         <- ตาราง คำ->Emoji (เช่น 'แมว'->'🐱')
```

**วิธีทำงาน:**
1. `startGame()` -> สุ่มคำ 10 คำจาก wordPool (Google Sheets หรือ hardcoded) -> สร้างตัวเลือก 4 ตัวต่อข้อ
2. TTS อ่านออกเสียงคำ -> User เลือก Emoji -> `selectAnswer()` ตรวจคำตอบ
3. แสดง Feedback 1.5 วินาที (เขียว=ถูก, แดง=ผิด) -> `advanceRound()`
4. จบ 10 ข้อ -> บันทึกลง Hive -> แสดงผลพร้อมดาว

### 8.2 เกมจับคู่ภาพ (Memory Match) [ใหม่]

**ไฟล์ที่เกี่ยวข้อง:**
```
features/games/memory_match/
|- memory_match_game.dart      <- หน้าเล่นเกม (Grid ของการ์ดคว่ำ)
|- memory_match_provider.dart  <- Logic เกม + ระบบคะแนน
+- memory_match_result.dart    <- หน้าแสดงผล
```

**ระดับความยาก 3 ระดับ:**

| ระดับ | จำนวนคู่ | จำนวนการ์ด | Grid |
|-------|---------|-----------|------|
| ง่าย | 4 คู่ | 8 การ์ด | 2 คอลัมน์ |
| ปานกลาง | 6 คู่ | 12 การ์ด | 3 คอลัมน์ |
| ยาก | 8 คู่ | 16 การ์ด | 4 คอลัมน์ |

**วิธีทำงาน:**
1. เลือกระดับความยาก -> `startGame(difficulty)` -> สุ่มคำ+Emoji จาก Google Sheets (หรือ hardcoded) -> สร้างการ์ดคู่ -> สลับตำแหน่ง
2. User เปิดการ์ดทีละ 2 ใบ -> `flipCard(index)` -> เปิดการ์ด
3. เปิดครบ 2 ใบ -> `_checkMatch()` -> รอ 0.8 วินาที -> ถ้าเป็นคู่เดียวกัน = matched, ไม่ใช่ = คว่ำกลับ
4. จับคู่ครบทุกคู่ -> `_saveScore()` -> แสดงผล

**ระบบคะแนน (Fair Scoring):**
คะแนนคำนวณจากจำนวนครั้งที่เปิด (attempts) เทียบกับ "ต้นทุนขั้นต่ำจริง" (minimum realistic attempts):
- ต้นทุนขั้นต่ำ = pairs + ceil(pairs / 2) เพราะช่วงแรกต้องสุ่มเปิดเพื่อดูภาพ
- ratio <= 1.3 = คะแนนเต็ม, <= 2.0 = 75%, <= 3.0 = 50%, มากกว่า = 25%

```
4 คู่: ต้นทุนขั้นต่ำ ~6 ครั้ง, เปิด <=8 = เต็ม, <=12 = ดี, <=18 = พอใช้
6 คู่: ต้นทุนขั้นต่ำ ~9 ครั้ง, เปิด <=12 = เต็ม, <=18 = ดี, <=27 = พอใช้
8 คู่: ต้นทุนขั้นต่ำ ~12 ครั้ง, เปิด <=16 = เต็ม, <=24 = ดี, <=36 = พอใช้
```

### 8.3 เกมกดปุ่มตามลำดับ (Color Sequence / Simon Says) [ใหม่]

**ไฟล์ที่เกี่ยวข้อง:**
```
features/games/color_sequence/
|- color_sequence_game.dart    <- หน้าเล่นเกม (ปุ่มสี 4 ปุ่ม)
|- color_sequence_provider.dart <- Logic เกม (State + ลำดับสี)
+- color_sequence_result.dart  <- หน้าแสดงผล
```

**สี 4 สีในเกม:** แดง, เขียว, น้ำเงิน, เหลือง (แต่ละสีมีสีปกติ + สี highlight)

**เฟสของเกม (GamePhase):**

| เฟส | สถานะ |
|-----|-------|
| `ready` | พร้อมเริ่ม |
| `showing` | ระบบกำลังแสดงลำดับสี (ผู้เล่นดูอย่างเดียว) |
| `inputting` | ผู้เล่นกดปุ่มตามลำดับ |
| `correct` | กดครบลำดับถูกต้อง -> ไปด่านถัดไป |
| `wrong` | กดผิด -> จบเกม |

**วิธีทำงาน:**
1. `startGame()` -> เริ่มด่าน 1
2. `_nextLevel()` -> สุ่มเพิ่มสีใหม่ 1 สีต่อท้ายลำดับ -> `_showSequence()`
3. ระบบ highlight สีทีละตัว (แสดง 0.6 วิ หยุด 0.3 วิ) -> เปลี่ยนเป็น `inputting`
4. ผู้เล่นกด `tapColor(color)`:
   - ถูก + ยังไม่ครบ -> รอกดต่อ
   - ถูก + ครบลำดับ -> `correct` -> รอ 0.8 วิ -> `_nextLevel()` (เพิ่มสีอีก 1)
   - ผิด -> `wrong` -> `_saveScore()` -> จบเกม
5. ด่านยิ่งสูง ลำดับยิ่งยาว (ด่าน 1 = จำ 1 สี, ด่าน 10 = จำ 10 สี)

**ระบบคะแนน:**
- เป้าหมาย: 20 ด่าน (`targetLevels = 20`)
- คะแนน = จำนวนด่านที่ผ่าน (level - 1 เพราะด่านสุดท้ายที่ผิดไม่นับ)
- ดาว: >=80% (16+ ด่าน) = 3 ดาว, >=50% (10+ ด่าน) = 2 ดาว, >=25% (5+ ด่าน) = 1 ดาว

### 8.4 แบบประเมินสมอง (Assessment)

**ไฟล์ที่เกี่ยวข้อง:**
```
features/assessment/
|- assessment_screen.dart      <- หน้าหลัก + Progress Bar
|- assessment_state.dart       <- State + Logic (คำนวณคะแนน)
|- result_screen.dart          <- หน้าผลลัพธ์ (วงกลมคะแนน + คำแนะนำ)
+- steps/
    |- step_date_time.dart     <- ขั้นตอน 1: เลือกวัน/เวลา
    |- step_memorize.dart      <- ขั้นตอน 2: จำคำ 3 คำ (10 วินาที)
    |- step_countdown.dart     <- ขั้นตอน 3: นับถอยหลัง (Number Pad)
    +- step_recall.dart        <- ขั้นตอน 4: เลือกคำที่จำได้
```

**การให้คะแนน (รวม 10 คะแนน):**
```
ขั้นตอน 1: ตอบวันถูก = 1, ตอบเวลาถูก = 1        (สูงสุด 2)
ขั้นตอน 2: ไม่มีคะแนน (แค่จำ)                    (สูงสุด 0)
ขั้นตอน 3: ตอบถูกข้อละ 1 คะแนน (5 ข้อ)           (สูงสุด 5)
ขั้นตอน 4: จำคำได้ข้อละ 1 คะแนน (เลือก 3 จาก 6) (สูงสุด 3)
                                          รวม = 10 คะแนน
```

### 8.5 จำกัดเวลาหน้าจอ (Screen Time)

**ไฟล์ที่เกี่ยวข้อง:**
```
features/screen_time/
|- screen_time_screen.dart     <- UI (วงกลม, ตั้งเวลา, กราฟ 7 วัน)
+- screen_time_provider.dart   <- Logic จับเวลา (Timer ทุก 1 วินาที)
```

**สิ่งพิเศษ:**
- Timer ทุก 1 วินาที -> อัปเดต UI
- บันทึกลง Hive ทุก 10 วินาที (ประหยัดแบต)
- เปิดแอปใหม่ -> คำนวณเวลาที่ผ่านไปอัตโนมัติ (resume tracking)
- เปลี่ยนวัน -> ย้ายข้อมูลเก่าไป week history อัตโนมัติ

### 8.6 ตั้งค่า (Settings)

**ไฟล์ที่เกี่ยวข้อง:**
```
features/settings/
|- settings_screen.dart        <- UI เลือกธีม + สีพื้นหลัง + ฟอนต์ + ขนาด
+- settings_provider.dart      <- เก็บ/โหลด ค่าจาก Hive
```

**ตั้งค่าที่มี:**

| หมวด | ตัวเลือก |
|------|---------|
| **โหมดธีม** | สว่าง (Light), มืด (Dark), ตามระบบ (System) |
| **สีพื้นหลัง** | 8 presets: ค่าเริ่มต้น, ครีม, ฟ้าอ่อน, เขียวอ่อน, ชมพูอ่อน, ม่วงอ่อน, ส้มอ่อน, เทาอ่อน |
| **ฟอนต์** | Sarabun, Kanit, Prompt, Mitr, Noto Sans Thai |
| **ขนาดตัวอักษร** | เล็ก (0.9x), ปกติ (1.0x), ใหญ่ (1.2x), ใหญ่มาก (1.4x) |

### 8.7 Splash Screen [ใหม่]

**ไฟล์:** `features/splash/splash_screen.dart`

- แสดงโลโก้ (`assets/images/logo.jpg`) + ชื่อ "Lumina" + tagline
- Fade-in animation 0.8 วินาที
- รอ 2 วินาที แล้ว fade transition ไปหน้าหลัก
- รองรับโหมดมืด (เปลี่ยนสีพื้นหลัง)

---

## 9. อยากเพิ่มเกมใหม่ ทำยังไง?

### ขั้นตอน 1: สร้างโฟลเดอร์
```
features/games/my_new_game/
|- my_new_game.dart           <- UI ของเกม
|- my_new_game_provider.dart  <- State + Logic
+- my_new_game_result.dart    <- หน้าผล (ใช้ GameResultScreen)
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
    // ตรวจคำตอบ -> อัปเดต score
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

**GameResultScreen คำนวณดาวอัตโนมัติ:**
- คะแนน >= 80% = 3 ดาว
- คะแนน >= 50% = 2 ดาว
- คะแนน >= 25% = 1 ดาว
- น้อยกว่า = 0 ดาว

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

### ขั้นตอน 6 (ทางเลือก): โหลดข้อมูลจาก Google Sheets

ถ้าอยากให้เกมโหลดข้อมูลจาก Google Sheets ได้:
1. เพิ่ม URL + parse method ใน `google_sheets_service.dart`
2. เรียก `GoogleSheetsService().fetchXxxData()` ตอน `startGame()`
3. ถ้า return null -> fallback ใช้ข้อมูล hardcoded

เท่านี้! HistoryScreen จะแสดงคะแนนเกมใหม่อัตโนมัติ

---

## 10. คำศัพท์ที่ควรรู้

| คำ | ความหมาย | ตัวอย่างในโปรเจค |
|----|---------|-----------------|
| **Widget** | ส่วนประกอบ UI ทุกอย่างใน Flutter | `Text()`, `ElevatedButton()`, `Card()` |
| **State** | ข้อมูลที่เปลี่ยนแปลงได้ | คะแนน, ข้อปัจจุบัน, เวลาที่ใช้ |
| **Provider** | ตัวส่งข้อมูลจาก State ไป UI | `soundMatchProvider`, `memoryMatchProvider` |
| **Notifier** | ตัวจัดการ State (มี method ต่าง ๆ) | `SoundMatchNotifier.selectAnswer()` |
| **ref.watch()** | อ่าน State (UI อัปเดตเมื่อเปลี่ยน) | `ref.watch(soundMatchProvider)` |
| **ref.read()** | เรียก Action (ไม่ทำให้ UI rebuild) | `ref.read(provider.notifier).start()` |
| **Hive Box** | "กล่อง" เก็บข้อมูลใน Hive | `Hive.box(HiveBoxes.gameScores)` |
| **Singleton** | Object ที่มีแค่ตัวเดียวในแอป | `StorageService()`, `GoogleSheetsService()` |
| **copyWith()** | สร้าง State ใหม่จากของเดิม (เปลี่ยนบางค่า) | `state.copyWith(score: 5)` |
| **ConsumerWidget** | Widget ที่ใช้ Riverpod ได้ | `class MyScreen extends ConsumerWidget` |
| **CustomPaint** | วาดกราฟิกเอง (วงกลม, กราฟ) | `_CircularTimerPainter` |
| **TTS** | Text-to-Speech (แปลงข้อความเป็นเสียง) | เสียงอ่านคำในเกมจับคู่เสียง |
| **WCAG AA** | มาตรฐาน Accessibility ระดับ AA | สีตัดกันชัด (contrast ratio >= 4.5:1) |
| **Buddhist Era** | ปีพุทธศักราช (ค.ศ. + 543) | 2026 -> 2569 |
| **ThemeMode** | โหมดธีมของแอป (light/dark/system) | `AppThemeMode.dark` |
| **Splash Screen** | หน้าจอเริ่มต้นเมื่อเปิดแอป | `SplashScreen` แสดงโลโก้ 2 วินาที |

---

## ธีมสีของแอป (Teal/Mint)

### โหมดสว่าง (Light)
| ชื่อสี | ค่า Hex | ใช้ทำอะไร |
|--------|---------|----------|
| Primary (Teal) | `#3D7F80` | สีหลัก — ปุ่ม, เมนูที่เลือก, เส้นขอบ |
| Secondary (Mint) | `#5BC5A7` | สี accent — progress bar, ไอคอน |
| Background | `#F0F5F5` | พื้นหลัง (เปลี่ยนได้ตาม preset) |
| Text Primary | `#2D3436` | ตัวอักษรหลัก |
| Text Secondary | `#6B7B8A` | ตัวอักษรรอง |

### โหมดมืด (Dark)
| ชื่อสี | ค่า Hex | ใช้ทำอะไร |
|--------|---------|----------|
| Primary (Mint) | `#6FD5B7` | สีหลัก — เด่นบนพื้นมืด |
| Secondary (Teal) | `#4A8B8C` | สี accent |
| Background | `#162224` | พื้นหลังมืด (เปลี่ยนได้ตาม preset) |
| Text Primary | `#E8EFF0` | ตัวอักษรหลัก |
| Text Secondary | `#A0B0B8` | ตัวอักษรรอง |

---

## เริ่มต้นจากไหนดี?

1. **อ่านโค้ด `main.dart` + `app.dart`** -> เข้าใจจุดเริ่มต้นและ Splash Screen
2. **ดู `home_screen.dart`** -> เข้าใจโครงสร้างหน้าหลัก
3. **ลองอ่าน `sound_match_provider.dart`** -> เข้าใจ State Management
4. **ลองอ่าน `memory_match_provider.dart`** -> เข้าใจ Memory Match + Google Sheets
5. **ลองอ่าน `color_sequence_provider.dart`** -> เข้าใจ Simon Says game loop
6. **ลองอ่าน `storage_service.dart`** -> เข้าใจการเก็บข้อมูล
7. **ลองเพิ่มเกมใหม่ตามขั้นตอนในข้อ 9** -> ฝึกเขียนจริง!

> **Tip:** รันแอปบน Chrome (`flutter run -d chrome`) แล้วลองเล่นทุกฟีเจอร์ก่อน จะช่วยให้เข้าใจโค้ดเร็วขึ้นมาก!
