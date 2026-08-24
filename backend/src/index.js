/**
 * Demenish AI — Worker (multi-tenant, เฟส 1) + phase-0 broadcast (back-compat)
 *
 * Storage: KV "DEMENISH" (D1 เต็มโควตาบัญชี จึงใช้ KV)
 *   hh:{hid}          → { name, seniorName, createdAt }
 *   cg:{hid}:{userId} → { displayName, role, quietStart, quietEnd, createdAt }
 *   inv:{token}       → { hid, createdAt }   (TTL 7 วัน)
 *   ev:{hid}:{id}     → { type, severity, message, ts, ackBy }  (TTL 30 วัน)
 *
 * Auth: device JWT (HS256, secret=JWT_SECRET) — payload { hid, did, iat }
 *
 * Endpoints:
 *   POST /device/register  {householdName,seniorName}      → { deviceToken, householdId }
 *   POST /invite           (Bearer JWT)                    → { inviteToken, liffUrl }
 *   POST /join             {token,userId,displayName}      → { ok, householdName }
 *   POST /alert            (Bearer JWT) {type,severity,message} → { pushed, eventId }
 *   GET  /household        (Bearer JWT)                    → { householdName, caregivers[] }
 *   POST /webhook          (LINE)  ← ปุ่มรับทราบ (postback) + reply userId (เทสต์)
 *   POST /broadcast        (x-app-key)  ← เฟส 0 (OA เดียว)
 *   POST /push             (x-app-key)  ← เฟส 0
 *
 * Secrets: CHANNEL_SECRET, CHANNEL_ACCESS_TOKEN, APP_KEY, JWT_SECRET
 * Vars (ไม่บังคับ): LIFF_ID
 */

const LINE_API = 'https://api.line.me/v2/bot/message';
const LINE_PROFILE = 'https://api.line.me/v2/bot/profile';

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const p = url.pathname;
    const m = request.method;
    try {
      if (m === 'POST' && p === '/device/register') return registerDevice(request, env);
      if (m === 'POST' && p === '/invite') return withAuth(request, env, (pl) => createInvite(pl, env));
      if (m === 'POST' && p === '/join') return joinHousehold(request, env);
      if (m === 'POST' && p === '/alert') return withAuth(request, env, (pl) => sendAlert(pl, request, env));
      if (m === 'GET' && p === '/household') return withAuth(request, env, (pl) => listHousehold(pl, env));
      if (m === 'POST' && p === '/caregiver/add') return withAuth(request, env, (pl) => addCaregiver(pl, request, env));
      if (m === 'POST' && p === '/caregiver/remove') return withAuth(request, env, (pl) => removeCaregiver(pl, request, env));
      if (m === 'POST' && p === '/heartbeat') return withAuth(request, env, (pl) => heartbeat(pl, request, env));
      if (m === 'GET' && p === '/liff') return liffPage(env);
      if (m === 'POST' && p === '/webhook') return handleWebhook(request, env);
      if (m === 'POST' && p === '/broadcast') return handleBroadcast(request, env);
      if (m === 'POST' && p === '/push') return handlePush(request, env);
      return new Response('Demenish AI worker (multi-tenant) is running', { status: 200 });
    } catch (e) {
      return new Response('error: ' + e.message, { status: 500 });
    }
  },

  // Cron (ทุก 1 นาที) — ไล่ระดับการแจ้งเตือนที่ยังไม่มีใครรับทราบ
  async scheduled(event, env, ctx) {
    ctx.waitUntil(escalatePending(env));
  },
};

/// escalation: อ่าน index "pending" (key เดียว — ไม่ใช้ list KV เพื่อประหยัด quota)
/// event ที่ยังค้างเกิน 3 นาที → เตือนซ้ำผู้ดูแล (ครั้งเดียว) แล้วเอาออกจาก pending
async function escalatePending(env) {
  const pend = await getPending(env);
  if (pend.length === 0) return; // ปกติ: อ่าน 1 ครั้งแล้วจบ
  const now = Date.now();
  const keep = [];
  let changed = false;
  for (const e of pend) {
    const age = now - (e.ts || 0);
    if (age > 60 * 60 * 1000) { changed = true; continue; } // ทิ้งของค้างเกิน 1 ชม.
    if (age > 3 * 60 * 1000) {
      // escalate: push หาผู้ดูแลในบ้านนั้น (list cg: เฉพาะตอนมี escalation จริง — เกิดไม่บ่อย)
      const cgs = await env.DEMENISH.list({ prefix: `cg:${e.hid}:` });
      for (const ck of cgs.keys) {
        const uid = ck.name.split(':')[2];
        await linePush(env, uid, `⚠️ ${e.message || ''}`, `ack:${e.hid}:${e.eventId}`);
      }
      changed = true; // เอาออกจาก pending (เตือนซ้ำแล้ว)
      continue;
    }
    keep.push(e); // ยังไม่ถึง 3 นาที เก็บไว้รอ
  }
  if (changed) await setPending(env, keep);
}

// ─── helpers: response / KV ───────────────────────────────────
function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });
}
async function getJson(env, key) {
  const v = await env.DEMENISH.get(key);
  return v ? JSON.parse(v) : null;
}
async function putJson(env, key, obj, ttl) {
  await env.DEMENISH.put(key, JSON.stringify(obj), ttl ? { expirationTtl: ttl } : undefined);
}

// ─── JWT (HS256) ──────────────────────────────────────────────
function b64url(buf) {
  return btoa(String.fromCharCode(...new Uint8Array(buf)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}
function b64urlStr(str) {
  return b64url(new TextEncoder().encode(str));
}
function b64urlToStr(b) {
  let s = b.replace(/-/g, '+').replace(/_/g, '/');
  while (s.length % 4) s += '=';
  return atob(s);
}
async function hmacRaw(secret, data) {
  const key = await crypto.subtle.importKey(
    'raw', new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  return crypto.subtle.sign('HMAC', key, new TextEncoder().encode(data));
}
async function signJwt(payload, secret) {
  const h = b64urlStr(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const p = b64urlStr(JSON.stringify(payload));
  const s = b64url(await hmacRaw(secret, `${h}.${p}`));
  return `${h}.${p}.${s}`;
}
async function verifyJwt(token, secret) {
  try {
    const [h, p, s] = token.split('.');
    if (!h || !p || !s) return null;
    const expected = b64url(await hmacRaw(secret, `${h}.${p}`));
    if (expected !== s) return null;
    return JSON.parse(b64urlToStr(p));
  } catch {
    return null;
  }
}
async function withAuth(request, env, fn) {
  const token = (request.headers.get('authorization') || '').replace(/^Bearer /, '');
  const payload = await verifyJwt(token, env.JWT_SECRET);
  if (!payload) return json({ error: 'unauthorized' }, 401);
  return fn(payload);
}

// ─── multi-tenant handlers ────────────────────────────────────
async function registerDevice(request, env) {
  const body = await request.json().catch(() => ({}));
  const householdName = String(body.householdName || 'บ้านของฉัน').slice(0, 60);
  const seniorName = String(body.seniorName || '').slice(0, 60);
  const hid = crypto.randomUUID();
  const did = crypto.randomUUID();
  await putJson(env, `hh:${hid}`, { name: householdName, seniorName, createdAt: Date.now() });
  const deviceToken = await signJwt({ hid, did, iat: Date.now() }, env.JWT_SECRET);
  return json({ deviceToken, householdId: hid });
}

async function createInvite(payload, env) {
  const token = crypto.randomUUID().replace(/-/g, '');
  await putJson(env, `inv:${token}`, { hid: payload.hid, createdAt: Date.now() }, 60 * 60 * 24 * 7);
  const liffId = env.LIFF_ID || '';
  const liffUrl = liffId ? `https://liff.line.me/${liffId}?token=${token}` : null;
  return json({ inviteToken: token, liffUrl, expiresInDays: 7 });
}

// หน้า LIFF สำหรับ onboarding ลูกหลาน (กดลิงก์เดียวเข้า ไม่ต้อง copy userId)
// ต้องสร้าง LINE Login channel + LIFF app แล้วตั้ง var LIFF_ID (ดู docs/backend)
function liffPage(env) {
  const liffId = env.LIFF_ID || '';
  const html = `<!DOCTYPE html>
<html lang="th"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Demenish AI</title>
<script src="https://static.line-scdn.net/liff/edge/2/sdk.js"></script>
<style>
  body{font-family:sans-serif;display:flex;min-height:90vh;align-items:center;justify-content:center;text-align:center;padding:24px;color:#2D3436}
  .card{max-width:360px}.big{font-size:22px;font-weight:700;margin:12px 0}
  .ok{color:#1B7A3D}.err{color:#C0392B}.muted{color:#6B7B8A;font-size:15px}
  .spin{width:36px;height:36px;border:4px solid #ddd;border-top-color:#3D7F80;border-radius:50%;animation:s 1s linear infinite;margin:0 auto}
  @keyframes s{to{transform:rotate(360deg)}}
</style></head>
<body><div class="card" id="app">
  <div class="spin"></div><div class="big">Connecting…</div>
</div>
<script>
  var LIFF_ID = ${JSON.stringify(liffId)};
  var app = document.getElementById('app');
  function show(cls, big, sub){
    while(app.firstChild) app.removeChild(app.firstChild);
    var b=document.createElement('div'); b.className='big '+cls; b.textContent=big; app.appendChild(b);
    if(sub){ var s=document.createElement('div'); s.className='muted'; s.textContent=sub; app.appendChild(s); }
  }
  if(!LIFF_ID){ show('err','ยังไม่ได้ตั้งค่า LIFF','LIFF is not configured yet'); }
  else {
    var token = new URLSearchParams(location.search).get('token');
    liff.init({liffId: LIFF_ID}).then(function(){
      if(!liff.isLoggedIn()){ liff.login(); return null; }
      return liff.getProfile();
    }).then(function(profile){
      if(!profile) return null;
      return fetch('/join', {method:'POST', headers:{'content-type':'application/json'},
        body: JSON.stringify({token: token, userId: profile.userId, displayName: profile.displayName})})
        .then(function(r){ return r.ok ? r.json() : r.json().then(function(e){ throw new Error(e.error||'error'); }); });
    }).then(function(res){
      if(!res) return;
      show('ok','✅ เชื่อมต่อสำเร็จ / Connected', 'คุณจะได้รับแจ้งเตือนจาก '+(res.householdName||'')+' • You will now receive alerts');
    }).catch(function(err){
      show('err','เชื่อมต่อไม่สำเร็จ / Failed', String(err.message||err));
    });
  }
</script></body></html>`;
  return new Response(html, { headers: { 'content-type': 'text/html; charset=utf-8' } });
}

async function joinHousehold(request, env) {
  const body = await request.json().catch(() => ({}));
  const { token, userId, displayName } = body || {};
  if (!token || !userId) return json({ error: 'missing token/userId' }, 400);
  const inv = await getJson(env, `inv:${token}`);
  if (!inv) return json({ error: 'invite invalid or expired' }, 404);
  await putJson(env, `cg:${inv.hid}:${userId}`, {
    displayName: displayName || '', role: 'member', createdAt: Date.now(),
  });
  const hh = await getJson(env, `hh:${inv.hid}`);
  return json({ ok: true, householdName: hh ? hh.name : '' });
}

function inQuietHours(cg) {
  if (cg.quietStart == null || cg.quietEnd == null) return false;
  const h = (new Date().getUTCHours() + 7) % 24; // Asia/Bangkok
  const s = cg.quietStart, e = cg.quietEnd;
  return s <= e ? (h >= s && h < e) : (h >= s || h < e);
}

async function sendAlert(payload, request, env) {
  const hid = payload.hid;
  const body = await request.json().catch(() => ({}));
  const type = body.type || 'alert';
  const severity = body.severity || 'info';
  const message = body.message;
  if (!message) return json({ error: 'missing message' }, 400);

  const eventId = crypto.randomUUID();
  const list = await env.DEMENISH.list({ prefix: `cg:${hid}:` });
  let pushed = 0;
  for (const k of list.keys) {
    const cg = await getJson(env, k.name);
    if (!cg) continue;
    if (severity !== 'urgent' && inQuietHours(cg)) continue;
    const userId = k.name.split(':')[2];
    const r = await linePush(env, userId, message, `ack:${hid}:${eventId}`);
    if (r.ok) pushed++;
  }
  const ts = Date.now();
  await putJson(env, `ev:${hid}:${eventId}`,
    { type, severity, message, ts, ackBy: null, escalated: false },
    60 * 60 * 24 * 30);
  // เก็บลง index "pending" (key เดียว) เพื่อให้ cron ไม่ต้อง list KV
  const pend = await getPending(env);
  pend.push({ hid, eventId, ts, message });
  await setPending(env, pend);
  return json({ ok: true, pushed, eventId });
}

// index อีเวนต์ที่ยังไม่ acked (เก็บใน key เดียว — cron อ่านครั้งเดียว/รอบ ไม่ใช้ list)
async function getPending(env) {
  const v = await env.DEMENISH.get('pending');
  return v ? JSON.parse(v) : [];
}
async function setPending(env, arr) {
  await env.DEMENISH.put('pending', JSON.stringify(arr));
}
function removePending(pend, eventId) {
  return pend.filter((x) => x.eventId !== eventId);
}

// ── /heartbeat : ส่ง "วันนี้สบายดี" ให้ผู้ดูแล วันละครั้ง (เงียบ ≠ สบายใจ) ──
async function heartbeat(payload, request, env) {
  const hid = payload.hid;
  const body = await request.json().catch(() => ({}));
  const d = new Date();
  const dayKey = `${d.getUTCFullYear()}-${d.getUTCMonth() + 1}-${d.getUTCDate()}`;
  const flag = `hb:${hid}:${dayKey}`;
  if (await env.DEMENISH.get(flag)) return json({ ok: true, sent: 0 }); // ส่งไปแล้ววันนี้

  const list = await env.DEMENISH.list({ prefix: `cg:${hid}:` });
  if (list.keys.length === 0) return json({ ok: true, sent: 0 }); // ไม่มีผู้ดูแล
  await env.DEMENISH.put(flag, '1', { expirationTtl: 60 * 60 * 48 });

  const hh = await getJson(env, `hh:${hid}`);
  const who = (hh && hh.seniorName) || 'Someone at home';
  const message = body.message || `${who} is doing fine today`;
  let sent = 0;
  for (const k of list.keys) {
    const uid = k.name.split(':')[2];
    const r = await linePush(env, uid, message, null);
    if (r.ok) sent++;
  }
  return json({ ok: true, sent });
}

// เพิ่มผู้ดูแลเข้าบ้าน (ผูกด้วย LINE userId โดยตรง — ไม่ต้องใช้ LIFF)
async function addCaregiver(payload, request, env) {
  const body = await request.json().catch(() => ({}));
  const userId = String(body.userId || '').trim();
  const displayName = String(body.displayName || '').slice(0, 60);
  if (!userId.startsWith('U') || userId.length < 20) {
    return json({ error: 'invalid userId' }, 400);
  }
  await putJson(env, `cg:${payload.hid}:${userId}`, {
    displayName, role: 'member', createdAt: Date.now(),
  });
  return json({ ok: true });
}

// ลบผู้ดูแลออกจากบ้าน
async function removeCaregiver(payload, request, env) {
  const body = await request.json().catch(() => ({}));
  const userId = String(body.userId || '').trim();
  if (userId) await env.DEMENISH.delete(`cg:${payload.hid}:${userId}`);
  return json({ ok: true });
}

async function listHousehold(payload, env) {
  const hid = payload.hid;
  const hh = await getJson(env, `hh:${hid}`);
  const list = await env.DEMENISH.list({ prefix: `cg:${hid}:` });
  const caregivers = [];
  for (const k of list.keys) {
    const cg = await getJson(env, k.name);
    caregivers.push({
      userId: k.name.split(':')[2],
      displayName: cg ? cg.displayName : '',
      role: cg ? cg.role : 'member',
    });
  }
  return json({ householdName: hh ? hh.name : '', caregivers });
}

// ─── LINE helpers ─────────────────────────────────────────────
async function linePush(env, to, message, ackData) {
  const msg = ackData
    ? {
        type: 'template',
        altText: message.slice(0, 400),
        template: {
          type: 'buttons',
          text: message.slice(0, 160),
          actions: [{
            type: 'postback',
            label: 'รับทราบ / กำลังไปดู',
            data: ackData,
            displayText: 'รับทราบแล้ว',
          }],
        },
      }
    : { type: 'text', text: message };
  return fetch(`${LINE_API}/push`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${env.CHANNEL_ACCESS_TOKEN}` },
    body: JSON.stringify({ to, messages: [msg] }),
  });
}
async function lineReply(accessToken, replyToken, text) {
  await fetch(`${LINE_API}/reply`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${accessToken}` },
    body: JSON.stringify({ replyToken, messages: [{ type: 'text', text }] }),
  });
}
async function getProfile(env, userId) {
  try {
    const r = await fetch(`${LINE_PROFILE}/${userId}`, {
      headers: { authorization: `Bearer ${env.CHANNEL_ACCESS_TOKEN}` },
    });
    if (r.ok) return r.json();
  } catch {}
  return null;
}

// ─── /webhook ─────────────────────────────────────────────────
async function handleWebhook(request, env) {
  const body = await request.text();
  const signature = request.headers.get('x-line-signature') || '';
  if (!(await verifySignature(env.CHANNEL_SECRET, body, signature))) {
    return new Response('bad signature', { status: 401 });
  }
  const data = JSON.parse(body);
  for (const ev of data.events || []) {
    const userId = ev.source && ev.source.userId;

    // ปุ่มรับทราบ (postback)
    if (ev.type === 'postback' && ev.postback && ev.postback.data && ev.postback.data.startsWith('ack:')) {
      const parts = ev.postback.data.split(':');
      const key = `ev:${parts[1]}:${parts[2]}`;
      const e = await getJson(env, key);
      if (e && !e.ackBy) {
        e.ackBy = userId;
        await putJson(env, key, e, 60 * 60 * 24 * 30);
      }
      // เอาออกจาก pending (มีคนรับทราบแล้ว → ไม่ต้อง escalate)
      const pend = await getPending(env);
      const filtered = removePending(pend, parts[2]);
      if (filtered.length !== pend.length) await setPending(env, filtered);
      if (ev.replyToken) await lineReply(env.CHANNEL_ACCESS_TOKEN, ev.replyToken, 'รับทราบแล้ว ขอบคุณที่ดูแลกันนะ');
      continue;
    }

    // follow/message: เก็บ userId (เทสต์/fallback) + ตอบ userId
    if ((ev.type === 'follow' || ev.type === 'message') && userId) {
      const prof = await getProfile(env, userId);
      if (env.USERS) await env.USERS.put(userId, (prof && prof.displayName) || '');
      if (ev.replyToken) {
        await lineReply(env.CHANNEL_ACCESS_TOKEN, ev.replyToken,
          'LINE User ID ของคุณคือ:\n' + userId);
      }
    }
  }
  return new Response('ok', { status: 200 });
}

// ─── phase 0 (back-compat) ────────────────────────────────────
async function handleBroadcast(request, env) {
  if (request.headers.get('x-app-key') !== env.APP_KEY) return new Response('unauthorized', { status: 401 });
  const body = await request.json().catch(() => null);
  if (!body || !body.message) return new Response('missing message', { status: 400 });
  const resp = await fetch(`${LINE_API}/broadcast`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${env.CHANNEL_ACCESS_TOKEN}` },
    body: JSON.stringify({ messages: [{ type: 'text', text: body.message }] }),
  });
  return new Response(await resp.text(), { status: resp.status });
}
async function handlePush(request, env) {
  if (request.headers.get('x-app-key') !== env.APP_KEY) return new Response('unauthorized', { status: 401 });
  const body = await request.json().catch(() => null);
  if (!body || !body.to || !body.message) return new Response('missing to/message', { status: 400 });
  const resp = await fetch(`${LINE_API}/push`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${env.CHANNEL_ACCESS_TOKEN}` },
    body: JSON.stringify({ to: body.to, messages: [{ type: 'text', text: body.message }] }),
  });
  return new Response(await resp.text(), { status: resp.status });
}

// ─── signature ────────────────────────────────────────────────
async function verifySignature(channelSecret, body, signature) {
  try {
    const mac = await hmacRaw(channelSecret, body);
    const expected = btoa(String.fromCharCode(...new Uint8Array(mac)));
    return expected === signature;
  } catch {
    return false;
  }
}
