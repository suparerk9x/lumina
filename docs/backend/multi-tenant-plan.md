# Demenish AI — Multi-tenant Blueprint (เฟส 1+)

> แผนขยายจาก **เฟส 0 (broadcast, OA เดียว = 1 บ้าน)** ไปเป็น **หลายบ้าน** แบบ world-class
> หลักคิด: บ้าน (Household) = tenant · LINE เป็นแอปฝั่งผู้ดูแล (ไม่ build แอปที่สอง) · ผูกคนด้วย invite link ไม่ต้องพิมพ์ ID

---

## 1. โมเดลข้อมูล (Cloudflare D1 — SQLite)

```sql
CREATE TABLE households (
  id TEXT PRIMARY KEY,            -- uuid
  name TEXT,                      -- "บ้านคุณยายสมศรี"
  created_at INTEGER
);

CREATE TABLE devices (            -- เครื่องผู้สูงอายุ (ตัวส่ง)
  id TEXT PRIMARY KEY,            -- uuid
  household_id TEXT NOT NULL,
  senior_name TEXT,
  device_key_hash TEXT,          -- hash ของ key ที่ฝังในแอป (auth /alert)
  consent_at INTEGER,            -- ผู้สูงอายุยินยอมเมื่อไร
  created_at INTEGER
);

CREATE TABLE caregivers (         -- ลูกหลาน (ตัวรับ ผ่าน LINE)
  household_id TEXT NOT NULL,
  line_user_id TEXT NOT NULL,
  display_name TEXT,
  role TEXT,                      -- primary | member
  quiet_start INTEGER,            -- ชั่วโมง 0-23 (ห้ามรบกวน)
  quiet_end INTEGER,
  created_at INTEGER,
  PRIMARY KEY (household_id, line_user_id)
);

CREATE TABLE invites (            -- ลิงก์เชิญเข้าบ้าน
  token TEXT PRIMARY KEY,         -- เซ็น HMAC + หมดอายุ
  household_id TEXT NOT NULL,
  expires_at INTEGER
);

CREATE TABLE events (             -- audit + feed
  id TEXT PRIMARY KEY,
  household_id TEXT NOT NULL,
  type TEXT,                      -- drowsy | screen_distance | heartbeat
  severity TEXT,                  -- info | warn | urgent
  ts INTEGER,
  ack_by TEXT                     -- line_user_id ที่กดรับทราบ
);
```

ทุก endpoint กรองด้วย `household_id` → บ้านแยกขาดกัน (tenant isolation)

---

## 2. Auth — device JWT (แทน global APP_KEY)

- ตอน onboard เครื่องผู้สูงอายุ: แอปขอ `POST /device/register {householdName}` → Worker สร้าง household + device + คืน **device token (JWT)** ฝังในเครื่อง (secure storage)
- ทุก `/alert` ส่ง `Authorization: Bearer <device JWT>` → Worker รู้ householdId จาก JWT
- key หลุด 1 เครื่อง = กระทบแค่บ้านเดียว (ไม่ใช่ทั้งระบบเหมือน global APP_KEY)

---

## 3. Onboarding ลูกหลาน — LIFF (ไม่ต้องพิมพ์ ID)

**ต้องเตรียมใน LINE console (สิ่งที่ผมทำแทนไม่ได้):**
- สร้าง **LINE Login channel** + **LIFF app** (endpoint = หน้าเว็บที่ deploy บน Cloudflare Pages/Worker) → ได้ `liffId`

**Flow:**
1. แอปคุณยาย/ผู้ตั้งค่า กด "เชิญลูกหลาน" → `POST /invite {device JWT}` → Worker คืน **invite link**:
   `https://liff.line.me/<liffId>?token=<inviteToken>`
2. แชร์ลิงก์ในกลุ่มไลน์ครอบครัว
3. ลูกหลานกดลิงก์ → เปิดใน LINE → LIFF ขอ consent → ได้ `userId` + displayName อัตโนมัติ
4. LIFF เรียก `POST /join {inviteToken, userId, displayName}` → Worker verify token → เพิ่ม caregiver เข้า household
5. เสร็จ — ไม่แตะมือถือคุณยาย ไม่พิมพ์ ID ทำ remote ได้

---

## 4. Endpoints (Worker เฟส 1)

| Method | Path | auth | ทำอะไร |
|--------|------|------|--------|
| POST | `/device/register` | — (ครั้งแรก) | สร้าง household + device → คืน JWT |
| POST | `/invite` | device JWT | สร้าง invite link |
| POST | `/join` | invite token | LIFF ผูก caregiver เข้าบ้าน |
| POST | `/alert` | device JWT | แจ้งเตือน (severity) → fan-out + escalation |
| POST | `/ack` | LINE webhook (postback) | caregiver กดรับทราบ → หยุด escalation |
| POST | `/heartbeat` | device JWT | "วันนี้ปกติดี" → feed |
| POST | `/webhook` | LINE signature | follow/postback events |

---

## 5. Trust layer (สิ่งที่ทำให้ใช้จริงได้)

- **Escalation:** `/alert` urgent → push primary caregiver ก่อน → ไม่ ack ใน N นาที → push member ทุกคน
- **Acknowledgement:** ข้อความ LINE มีปุ่ม (postback) "รับทราบ/กำลังไปดู" → `/ack` → บันทึก + หยุดไล่
- **Severity:** ง่วง=info · ระยะจอ=info · (อนาคต) ล้ม/ไม่ตอบสนอง=urgent
- **Quiet hours:** เช็ค `quiet_start/end` ต่อ caregiver ก่อน push (urgent ข้ามได้)
- **Heartbeat/feed:** ส่งสรุปรายวัน — เงียบ ≠ สบายใจ
- **Consent:** แอปบันทึก `consent_at` (ผู้สูงอายุยินยอม/ลูกกดแทนตอน setup)

---

## 6. Migration จากเฟส 0

| เฟส 0 (ตอนนี้) | เฟส 1 |
|---------------|-------|
| global `APP_KEY` | device JWT ต่อเครื่อง |
| `/broadcast` (ทุก friend) | `/alert` → push เฉพาะ caregiver ในบ้าน |
| ผูกด้วย "แอด OA" | invite link + LIFF |
| KV `USERS` | D1 (households/caregivers/events/invites) |
| ไม่มี ack/escalation | มีครบ |

โค้ดแอปที่ carry ต่อได้: หน้าเชื่อม LINE (เปลี่ยน QR add-OA → invite link), LineService (เปลี่ยน endpoint), drowsiness trigger (เปลี่ยน broadcast → alert)

---

## 7. สิ่งที่ต้องเตรียมฝั่ง LINE (ผู้ใช้ทำเอง)
1. LINE Login channel (นอกเหนือจาก Messaging API channel)
2. LIFF app (endpoint = หน้าเว็บ join) → ได้ liffId
3. เปิด Cloudflare D1 database (`wrangler d1 create demenish`)
