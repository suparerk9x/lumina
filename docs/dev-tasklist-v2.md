# Dev Task List — Lumina v2 (ฟีเจอร์ใหม่ 9 ข้อ)

> อ้างอิงจาก `docs/สรุป-update.md` + โค้ดจริงใน `lumina/lib/`
> Stack ปัจจุบัน: Flutter · Riverpod 3 · Hive · offline-first · feature-first
> Effort: **S** = 1–2 วัน · **M** = 3–5 วัน · **L** = 1–2 สัปดาห์+

---

## 0. อ่านก่อนเริ่ม — ผลกระทบสถาปัตยกรรม (Architecture Impact)

ฟีเจอร์ใหม่หลายตัว**ทำลายสมมติฐานเดิม**ของแอป ต้องตัดสินใจก่อนลงมือ:

| เรื่อง | สถานะเดิม | ของใหม่ต้องมี | กระทบข้อ |
|-------|----------|--------------|---------|
| **กล้อง + Face detection** | ไม่มี | `camera` + `google_mlkit_face_detection` — sample ทุก 5 นาที **เฉพาะตอนเปิดแอป** | 4, 6 |
| **AI on-device** | ไม่มี | ML Kit (ง่วง) + rule-based ไทย (สแกม) — ฟรี ไม่มี LLM | 3, 6 |
| **รับข้อความมาเช็ก** | ไม่มี | **paste + share-to-app** (ทั้ง iOS/Android) — ตัด auto notification | 3 |
| **Notification engine** | ไม่มี | `flutter_local_notifications` + timezone | 1, 4, 6 |
| **User profile** (อายุ/เพศ/เบอร์ครอบครัว) | ไม่มี | Hive box ใหม่ + onboarding + Settings | 2, 5, 6 |
| **Backend (LINE proxy)** | ไม่มี | Cloudflare Workers + KV (ฟรี) | 6 |
| **โทรออก** | ไม่มี | `url_launcher` (tel:) | 2 |
| **Offline-first** | เป็นหลักการหลัก | ข้อ 3 (rule-based) ยังออฟไลน์ได้ · ข้อ 6 LINE ต้องเน็ต | 3, 6 |
| **Web target** | รันบน Chrome ได้ | กล้อง/โทร/LINE ใช้ไม่ได้บนเว็บ → โฟกัส mobile | 2,4,6 |

### ✅ Decisions (ตัดสินแล้ว 2026-08-14)
1. **AI ข้อ 3 & 6 = on-device ฟรีทั้งหมด**
   - ข้อ 6 (ง่วง/ระยะจอ): ใช้ **ML Kit Face Detection** (`google_mlkit_face_detection`) — บนเครื่อง ฟรี ไม่ต้องเทรน model. ใช้ค่า `eyeOpenProbability` + `headEulerAngle` + ขนาด bounding box ทำ logic เอง
   - ข้อ 3 (สแกม): เริ่มด้วย **rule-based ภาษาไทย** (keyword + URL heuristic) ฟรี ออฟไลน์ ทำงานทุกเครื่อง → เสริม TFLite classifier ทีหลังถ้าต้องการ. **ตัด on-device LLM** (หนักเกินสำหรับเครื่องผู้สูงอายุ)
2. **ข้อ 3 สแกม = rule-based ไทย + รับข้อความแบบ paste / share-to-app** (ทำงานเหมือนกันทั้ง iOS/Android ตาม feature-parity). **ตัด** auto-capture ผ่าน NotificationListener (iOS ทำไม่ได้). Flow: ผู้ใช้แชร์/วางข้อความน่าสงสัยเข้าแอป → checker วิเคราะห์
3. **ข้อ 6 LINE = LINE Messaging API (free 300 msg/เดือน) + backend บน Cloudflare Workers + KV** (ฟรี ไม่มี cold start). Worker ทำ 2 อย่าง: (a) webhook เก็บ `userId` ตอนครอบครัวแอด OA, (b) push proxy เก็บ channel token ฝั่ง server (ห้ามฝังในแอป)
4. **ข้อ 5 อายุ/เพศ:** เก็บใน user profile — ถามตอน **onboarding เริ่มแอป** (ข้ามได้) + แก้ทีหลังได้ที่ **Settings**
5. **ข้อ 4 & 6 กล้อง = sampling เป็นช่วง ทุก 5 นาที (default) + config ได้** — เปิดกล้องแวบเดียว sample แล้วปิด. **ทำงานเฉพาะตอนเปิดแอปอยู่ (foreground)** ทั้งสองแพลตฟอร์ม (iOS ห้าม background camera → เพื่อ parity จึงไม่ทำ background monitoring บน Android ด้วย)

### ⚙️ Platform strategy = feature parity (iOS = Android)
- ข้อ 3: paste/share only ทั้งคู่ (ไม่มี auto)
- ข้อ 4, 6: กล้อง sample เฉพาะตอนใช้แอป ไม่ monitor เบื้องหลัง
- ผลข้างเคียงที่ยอมรับ: ข้อ 4/6 จะเตือนได้เฉพาะระหว่างผู้ใช้เปิด Lumina ค้างไว้ (เหมาะกับ use case "เล่นเกม/ใช้แอปนานๆ แล้วง่วง/จ้อจอใกล้")

---

## 1. งานฐาน (Foundation) — ต้องทำก่อน เพราะหลายฟีเจอร์พึ่งพา

### F1. User Profile system  `[M]`  → ปลดล็อกข้อ 2, 5, 6
- [ ] สร้าง `shared/storage/user_profile.dart` (model: ชื่อ, ช่วงอายุ/ปีเกิด, เพศ, รายชื่อครอบครัว[{ชื่อ, รูป, เบอร์, lineUserId}])
- [ ] เพิ่ม Hive box `user_profile` ใน `shared/storage/hive_boxes.dart` + เปิดใน `main.dart`
- [ ] เพิ่ม method ใน `storage_service.dart` (get/save profile, add/remove contact)
- [ ] **Onboarding เริ่มแอป** (แสดงครั้งแรกหลัง splash, ข้ามได้): ถามชื่อ + **อายุ** + **เพศ** → เก็บ flag `onboardingDone`
- [ ] **Settings**: เพิ่มส่วนแก้ **อายุ/เพศ** ได้ทีหลัง (ตาม decision #4)
- [ ] สร้าง `features/profile/` (screen + provider) — แก้ไขข้อมูลส่วนตัว + รายชื่อครอบครัว

### F2. Notification engine  `[M]`  → ปลดล็อกข้อ 1, 4, 6
- [ ] เพิ่ม `flutter_local_notifications` + `timezone` ใน pubspec
- [ ] Android: config `AndroidManifest.xml` (permission + boot receiver ถ้าต้องเตือนหลัง reboot)
- [ ] iOS: request permission + config `Info.plist`
- [ ] สร้าง `shared/services/notification_service.dart` (singleton: schedule / cancel / instant)
- [ ] ทดสอบ scheduled notification ข้ามวัน + timezone ไทย

### F3. Camera + Face detection base  `[L]`  → ปลดล็อกข้อ 4, 6
- [ ] เพิ่ม `camera` + `google_mlkit_face_detection` + `permission_handler` ใน pubspec
- [ ] เปิด option ML Kit: `enableClassification: true` (ได้ eyeOpenProbability) + head angles
- [ ] ขอสิทธิ์กล้อง + หน้าอธิบายเหตุผล/consent (ผู้สูงอายุ)
- [ ] สร้าง `shared/services/face_sampling_service.dart` — **sampling เป็นช่วง**: เปิด front camera → จับ 1–2 เฟรม → detect → ปิดกล้อง (ไม่ stream ต่อเนื่อง)
- [ ] Scheduler: รันทุก **5 นาที (default) + config ได้** ใน Settings — **เดินเฉพาะตอน app foreground** (ผูกกับ `WidgetsBindingObserver`, หยุดเมื่อ background)
- [ ] toggle เปิด/ปิดรวมใน Settings + ปิด web target

---

## 2. ฟีเจอร์ตาม PDF (เรียงตามความพร้อม/ความเสี่ยง)

### ✅ ข้อ 5 — แบบประเมินตามช่วงอายุ/เพศ  `[S–M]`  · ความเสี่ยงต่ำ · ทำได้เลยหลัง F1
ปรับ `features/assessment/`
- [ ] อ่านอายุ/เพศจาก user profile (F1)
- [ ] แยกชุดคำถาม/ระดับความยากตามช่วงอายุ ใน `assessment_state.dart` + `core/constants.dart`
- [ ] ปรับคำ/บริบทให้เหมาะกับเพศ (ถ้าเกี่ยวข้อง)
- [ ] เพิ่มตัวเลือก "เพศ" ในหน้า Settings (ตามที่ PDF ระบุ)
- [ ] Fallback: ถ้าไม่มีข้อมูลอายุ → ใช้ชุดกลาง (default เดิม)

### ✅ ข้อ 7 — เปลี่ยนภาพของแอป  `[S]`  · ความเสี่ยงต่ำ
- [ ] เปลี่ยน asset ใน `assets/images/` + อัปเดต `pubspec.yaml`
- [ ] อัปเดตจุดที่อ้าง `logo.jpg`: `splash_screen.dart`, `home_screen.dart` (AppBar)

### ✅ ข้อ 9 — เปลี่ยนไอคอนแอป + ชื่อ  `[S]`  · ความเสี่ยงต่ำ
- [ ] ใช้ `flutter_launcher_icons` gen ไอคอนทุก density (Android + iOS)
- [ ] เปลี่ยนชื่อแอป: `AndroidManifest.xml` (`android:label`) + iOS `Info.plist` (`CFBundleDisplayName`)
- [ ] (พื้นหลัง/ตัวอย่างคงเดิมตาม PDF)

### ✅ ข้อ 2 — ระบบโทรหาครอบครัว  `[M]`  · ต้องมี F1
- [ ] เพิ่ม `url_launcher` ใน pubspec
- [ ] สร้าง `features/family_call/` (grid รูปสมาชิก + ปุ่มโทร)
- [ ] อ่านรายชื่อครอบครัว (ชื่อ/รูป/เบอร์) จาก user profile (F1)
- [ ] หน้าเพิ่ม/แก้สมาชิก + เลือกรูปจากเครื่อง (`image_picker`)
- [ ] กดปุ่ม → `launchUrl(tel:...)` · ปุ่มใหญ่ตามมาตรฐาน accessibility เดิม
- [ ] เพิ่มการ์ดเข้าหน้าหลัก `home_screen.dart`

### ✅ ข้อ 8 — Flash Card รายวัน  `[M]`  · ต้องมี F1 (ใช้รูปลูกหลาน)
- [ ] สร้าง `features/flash_card/` (provider + dialog)
- [ ] Logic "ครั้งแรกของวัน": เก็บ `lastShownDate` ใน Hive → เทียบวันปัจจุบัน
- [ ] Pop-up 1 การ์ดตอนเข้าแอป (trigger ใน `home_screen.dart` / หลัง splash)
- [ ] เนื้อหาการ์ด: รูปลูกหลาน (จาก profile) + คำถาม "คนนี้ชื่ออะไร / คือใคร"
- [ ] แหล่งการ์ดอื่น (คำศัพท์/ภาพ) — ดึงจาก Google Sheets ได้ (ใช้ service เดิม)
- [ ] บันทึกผลตอบ (ถ้าต้องการเก็บสถิติความจำ)

### ✅ ข้อ 1 — เตือนนัดหมายแพทย์  `[M]`  · ต้องมี F2
- [ ] สร้าง `shared/storage/appointment.dart` (model: หัวข้อ, วันเวลา, หมอ/สถานที่, note) + Hive box
- [ ] method ใน `storage_service.dart` (CRUD นัดหมาย)
- [ ] สร้าง `features/appointments/` (list + form เพิ่ม/แก้ + date/time picker)
- [ ] schedule notification ล่วงหน้า (เลือกช่วงเตือน เช่น 1 วัน/1 ชม.ก่อน) ผ่าน F2
- [ ] ยกเลิก/อัปเดต notification เมื่อแก้/ลบนัด
- [ ] เพิ่มเมนูเข้าหน้าหลัก

### ⚠️ ข้อ 4 — เตือนระยะห่างหน้าจอ  `[M–L]`  · ต้องมี F3
- [ ] ใช้ `face_sampling_service` (F3) ประเมินระยะจากขนาด bounding box (หน้าใหญ่ = ใกล้)
- [ ] Calibrate เกณฑ์ "ใกล้เกินไป" (สัดส่วนหน้า/กรอบภาพ) + cooldown ไม่เตือนซ้ำถี่
- [ ] แจ้งเตือนให้ถอยห่าง (in-app banner + optional notification F2)
- [ ] Toggle เปิด/ปิด + ตั้ง interval ใน Settings (แชร์ scheduler กับข้อ 6)

### ⚠️ ข้อ 6 — ตรวจจับอาการง่วง + แจ้ง LINE  `[L]`  · ต้องมี F2 + F3 + Backend
- [ ] ใช้ ML Kit (F3): `eyeOpenProbability < ~0.3` ต่อเนื่องหลาย sample + `headEulerAngleX` (ก้มหน้า) → สัญญาณง่วง
- [ ] Logic ยืนยันหลายรอบ (กัน false positive จากกระพริบตา/ก้มมองมือถือปกติ)
- [ ] แจ้งเตือนผู้ใช้ให้พักผ่อน (in-app + notification F2)
- [ ] **ส่ง LINE ให้ครอบครัว** ผ่าน backend (ดู B1): app → Cloudflare Worker → LINE push
- [ ] ตั้งค่าเปิด/ปิด + เลือกผู้รับจาก family contacts (F1, ต้องมี `lineUserId`)

### 🔶 ข้อ 3 — ตรวจจับข้อความหลอกลวง (rule-based ไทย)  `[M]`  · iOS + Android เหมือนกัน
- [ ] สร้าง `shared/services/scam_detector.dart` — **rule-based ไทย** (ออฟไลน์เต็ม):
  - keyword list: "พัสดุตกค้าง / บัญชีถูกระงับ / ยืนยันตัวตน / กดลิงก์ / โอนเงินด่วน / ถูกรางวัล / OTP" ฯลฯ (แยกไฟล์ให้แก้ง่าย)
  - URL heuristic: โดเมนแปลก, ลิงก์ย่อ (bit.ly/…), non-official TLD, ปน IP address, unicode หลอกตา
  - รวมเป็นคะแนนความเสี่ยง (ต่ำ/กลาง/สูง) + คืน "เหตุผลที่เจอ"
- [ ] สร้าง `features/scam_check/` : ช่อง **paste** ข้อความ → กดตรวจ → แสดงผล
- [ ] รับผ่าน **share-to-app** (share intent) จากแอปข้อความ — ทำงานทั้ง iOS/Android
- [ ] แสดงผล: ระดับความเสี่ยง + คำ/ลิงก์ที่ตรวจเจอ + คำแนะนำตัวใหญ่ ("อย่ากดลิงก์ / อย่าโอนเงิน / โทรถามลูกหลานก่อน")
- [ ] (เฟสหลัง ถ้าต้องการแม่นขึ้น) เสริม TFLite classifier
- [ ] เพิ่มเมนูเข้าหน้าหลัก

### 🔧 B1 — Backend LINE proxy (Cloudflare Workers)  `[M]`  · แยก repo/deploy ต่างหาก
- [ ] สร้าง Worker + KV namespace (ฟรี) · เก็บ `CHANNEL_ACCESS_TOKEN`, `CHANNEL_SECRET` เป็น secret
- [ ] Endpoint `/webhook`: verify signature → จับ event `follow` → เก็บ `userId` ลง KV
- [ ] Endpoint `/push`: รับ request จากแอป (auth ด้วย key) → เรียก LINE push API ส่ง alert
- [ ] ตั้ง LINE OA (Messaging API channel) + ผูก webhook URL · โควตา free 300 msg/เดือน
- [ ] Flow ผูกผู้ใช้: ครอบครัวแอด OA เป็นเพื่อน → ได้ `lineUserId` → กรอก/สแกนเข้าแอป (เก็บใน contact F1)

---

## 3. ลำดับแนะนำ (Suggested Phasing)

**Sprint 1 — Quick wins + Foundation**
ข้อ 7, ข้อ 9 (branding) · F1 (profile) · ข้อ 5 (assessment ตามอายุ) · ข้อ 2 (โทรครอบครัว)

**Sprint 2 — Notification-based**
F2 (notification engine) · ข้อ 1 (นัดหมาย) · ข้อ 8 (flash card)

**Sprint 3 — สแกม + Camera/AI**
ข้อ 3 (rule-based สแกม — แยกอิสระ ไม่ต้องรอ F3) · F3 (camera/face base, foreground) · ข้อ 4 (ระยะจอ)

**Sprint 4 — ง่วง + LINE (ต้องมี backend)**
B1 (Cloudflare Worker + LINE OA) · ข้อ 6 (ง่วง → แจ้ง LINE)

> เหตุผล: risk ต่ำ + ปลดล็อก dependency ก่อน (F1/F2). ข้อ 3 rule-based แยกอิสระได้เลย. งาน backend/LINE (ซับซ้อนสุด, มี external setup) ดันไปท้าย
> **Platform = feature parity:** ทุกฟีเจอร์ทำงานเหมือนกัน iOS/Android. ข้อ 3 = paste/share เท่านั้น · ข้อ 4,6 = กล้อง sample เฉพาะตอนเปิดแอป (ไม่ monitor เบื้องหลัง)

---

## 4. Cross-cutting (ทำควบทุกฟีเจอร์)
- [ ] ทุก UI ใหม่ยึดมาตรฐานเดิม: ปุ่ม ≥56px, ฟอนต์ปรับ 1.4x, contrast WCAG AA, ภาษาไทยทั้งหมด
- [ ] ใช้ pattern เดิม: Notifier + `copyWith` + `StorageService` เป็นตัวกลาง Hive
- [ ] Privacy: หน้าอธิบาย + consent สำหรับกล้อง/ไมค์/ข้อความ (ข้อ 3,4,6)
- [ ] เพิ่ม permission strings ใน AndroidManifest + Info.plist ทุกตัวที่เพิ่ม
- [ ] อัปเดต `README.md` + `pubspec version` เป็น 2.0.0
- [ ] ทดสอบบนอุปกรณ์จริง (กล้อง/โทร/LINE ทดบน Chrome ไม่ได้)
