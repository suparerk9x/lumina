# Backend LINE (Cloudflare Worker) — ข้อ 6 แจ้งเตือนอาการง่วงผ่าน LINE

Backend บางๆ ตัวนี้ทำหน้าที่เป็น **proxy** ระหว่างแอป Demenish AI กับ LINE Messaging API
เพราะห้ามฝัง channel access token ในแอป (ถูกถอดออกมาได้) → เก็บ token ไว้ฝั่ง server แทน

ฟรีทั้งหมด: Cloudflare Workers (100k req/วัน) + LINE Messaging API (free 300 ข้อความ/เดือน)

---

## ภาพรวม flow

```
ครอบครัวแอด LINE OA เป็นเพื่อน
        │
        ▼
LINE เรียก  POST /webhook  → Worker ตอบกลับ "LINE User ID ของคุณคือ Uxxxx"
        │
        ▼
กรอก Uxxxx ในแอป (หน้าแก้ไขสมาชิกครอบครัว → ช่อง LINE User ID)
        │
        ▼
เมื่อแอปพบอาการง่วง →  POST /push  → Worker → LINE push ไปหา Uxxxx
```

---

## ขั้นตอนติดตั้ง

### 1) สร้าง LINE Official Account + Messaging API channel
1. ไปที่ https://developers.line.biz/console/ → สร้าง Provider
2. สร้าง channel แบบ **Messaging API**
3. เก็บค่า 2 อย่าง:
   - **Channel secret** (แท็บ Basic settings)
   - **Channel access token (long-lived)** (แท็บ Messaging API → Issue)

### 2) Deploy Cloudflare Worker
ต้องมี Node.js + [wrangler](https://developers.cloudflare.com/workers/wrangler/)

```bash
npm create cloudflare@latest demenish-line
# เลือก "Hello World Worker" (JavaScript)
cd demenish-line
# แทนที่ src/index.js ด้วยไฟล์ cloudflare-worker.js ในโฟลเดอร์นี้

# ตั้ง secrets
npx wrangler secret put CHANNEL_SECRET
npx wrangler secret put CHANNEL_ACCESS_TOKEN
npx wrangler secret put APP_KEY          # ตั้งเองเป็นรหัสลับอะไรก็ได้

# (ไม่บังคับ) เก็บรายชื่อผู้ติดตามใน KV
npx wrangler kv namespace create USERS
# แล้วเพิ่ม binding ใน wrangler.toml:
#   [[kv_namespaces]]
#   binding = "USERS"
#   id = "<id ที่ได้>"

npx wrangler deploy
# ได้ URL เช่น https://demenish-line.<subdomain>.workers.dev
```

### 3) ตั้ง Webhook ใน LINE console
- แท็บ Messaging API → Webhook URL = `https://<worker>/webhook` → เปิด Use webhook
- ปิด auto-reply/greeting ของ OA (ไม่งั้นจะตอบทับ)

### 4) ผูกแอปกับ Worker
build แอปโดยส่งค่า 2 ตัวผ่าน `--dart-define`:

```bash
flutter build apk \
  --dart-define=LINE_WORKER_URL=https://demenish-line.<subdomain>.workers.dev \
  --dart-define=LINE_APP_KEY=<APP_KEY ที่ตั้งไว้>
```

> ถ้าไม่ส่งค่า 2 ตัวนี้ ฟีเจอร์ LINE จะปิดเงียบ (แอปยังทำงานปกติ แค่ไม่ส่ง LINE)

### 5) วิธีที่ครอบครัวรับ userId
1. สแกน QR ของ LINE OA (แท็บ Messaging API) → แอดเป็นเพื่อน
2. บอทจะตอบกลับ **LINE User ID** (ขึ้นต้นด้วย `U...`)
3. เอา userId ไปกรอกในแอปของผู้สูงอายุ: หน้า **โทรหาครอบครัว → แก้ไขสมาชิก → LINE User ID**

---

## ทดสอบ /push เอง (curl)

```bash
curl -X POST https://<worker>/push \
  -H "content-type: application/json" \
  -H "x-app-key: <APP_KEY>" \
  -d '{"to":"U0123...","message":"ทดสอบจาก Demenish AI"}'
```

## หมายเหตุ
- โควตา free LINE = 300 ข้อความ/เดือน เพียงพอสำหรับ alert
- `/webhook` ตรวจลายเซ็น `x-line-signature` ด้วย `CHANNEL_SECRET` เพื่อกันคนปลอม
- `/push` ต้องมี header `x-app-key` ตรงกับ `APP_KEY` เท่านั้น
