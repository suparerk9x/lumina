/**
 * Demenish AI — LINE push proxy (Cloudflare Worker)
 * ข้อ 6: แจ้งเตือนอาการง่วงไปยัง LINE ของครอบครัว
 *
 * 2 endpoint:
 *   POST /webhook  — LINE เรียกเมื่อมีคนแอด OA/ส่งข้อความ → ตอบกลับ userId
 *                    (เพื่อให้ผู้ใช้เอา userId ไปกรอกในแอป) + เก็บลง KV
 *   POST /push     — แอปเรียกเพื่อส่งข้อความ (auth ด้วย header x-app-key)
 *
 * Secrets ที่ต้องตั้ง (wrangler secret put ...):
 *   CHANNEL_SECRET         — LINE channel secret (ใช้ verify webhook)
 *   CHANNEL_ACCESS_TOKEN   — LINE channel access token (ใช้ push/reply)
 *   APP_KEY                — คีย์ลับที่แชร์กับแอป (กันคนอื่นยิง push)
 * Binding (ไม่บังคับ): KV namespace ชื่อ USERS สำหรับเก็บรายชื่อผู้ติดตาม
 */

const LINE_API = 'https://api.line.me/v2/bot/message';

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === 'POST' && url.pathname === '/webhook') {
      return handleWebhook(request, env);
    }
    if (request.method === 'POST' && url.pathname === '/push') {
      return handlePush(request, env);
    }
    return new Response('Demenish AI LINE worker is running', { status: 200 });
  },
};

// ── /webhook : รับ event จาก LINE ───────────────────────────────
async function handleWebhook(request, env) {
  const body = await request.text();

  // ตรวจลายเซ็นว่ามาจาก LINE จริง
  const signature = request.headers.get('x-line-signature') || '';
  const valid = await verifySignature(env.CHANNEL_SECRET, body, signature);
  if (!valid) return new Response('bad signature', { status: 401 });

  const data = JSON.parse(body);
  const events = data.events || [];
  for (const ev of events) {
    const userId = ev.source && ev.source.userId;
    if (!userId) continue;

    // เก็บ userId ลง KV (ถ้าผูก namespace USERS ไว้)
    if (env.USERS) {
      await env.USERS.put(userId, new Date().toISOString());
    }

    // ตอบกลับ userId ให้ผู้ใช้เอาไปกรอกในแอป
    if ((ev.type === 'follow' || ev.type === 'message') && ev.replyToken) {
      const text =
        'LINE User ID ของคุณคือ:\n' +
        userId +
        '\n\nนำรหัสนี้ไปกรอกในแอป Demenish AI (หน้าแก้ไขสมาชิกครอบครัว) ' +
        'เพื่อรับแจ้งเตือน';
      await lineReply(env.CHANNEL_ACCESS_TOKEN, ev.replyToken, text);
    }
  }
  return new Response('ok', { status: 200 });
}

// ── /push : แอปเรียกเพื่อส่งข้อความหา LINE ───────────────────────
async function handlePush(request, env) {
  if (request.headers.get('x-app-key') !== env.APP_KEY) {
    return new Response('unauthorized', { status: 401 });
  }
  let payload;
  try {
    payload = await request.json();
  } catch {
    return new Response('bad json', { status: 400 });
  }
  const { to, message } = payload || {};
  if (!to || !message) return new Response('missing to/message', { status: 400 });

  const resp = await fetch(`${LINE_API}/push`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${env.CHANNEL_ACCESS_TOKEN}`,
    },
    body: JSON.stringify({ to, messages: [{ type: 'text', text: message }] }),
  });
  return new Response(await resp.text(), { status: resp.status });
}

// ── helpers ─────────────────────────────────────────────────────
async function lineReply(accessToken, replyToken, text) {
  await fetch(`${LINE_API}/reply`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({
      replyToken,
      messages: [{ type: 'text', text }],
    }),
  });
}

async function verifySignature(channelSecret, body, signature) {
  try {
    const key = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(channelSecret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign'],
    );
    const mac = await crypto.subtle.sign(
      'HMAC',
      key,
      new TextEncoder().encode(body),
    );
    const expected = btoa(String.fromCharCode(...new Uint8Array(mac)));
    return expected === signature;
  } catch {
    return false;
  }
}
