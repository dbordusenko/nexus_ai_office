import { createServer } from 'http';
import { readFileSync, writeFileSync, existsSync } from 'fs';
import { randomBytes, scryptSync, timingSafeEqual, createHmac } from 'crypto';
import Groq from 'groq-sdk';
import nodemailer from 'nodemailer';

// Load .env
if (existsSync('.env')) {
  for (const line of readFileSync('.env', 'utf-8').split('\n')) {
    const [k, ...v] = line.split('=');
    if (k && v.length) process.env[k.trim()] = v.join('=').trim();
  }
}

const PORT = process.env.PORT || 8001;
const MODEL = process.env.GROQ_MODEL || 'llama-3.3-70b-versatile';
const API_KEY = process.env.GROQ_API_KEY;

const groq = API_KEY ? new Groq({ apiKey: API_KEY }) : null;
const documents = new Map();

// ─── Auth & user storage ─────────────────────────────────────
const USERS_FILE = 'users.json';
const SECRET_FILE = '.auth_secret';

// Persistent signing secret (survives restarts so tokens stay valid)
let AUTH_SECRET;
if (process.env.AUTH_SECRET) {
  AUTH_SECRET = process.env.AUTH_SECRET;
} else if (existsSync(SECRET_FILE)) {
  AUTH_SECRET = readFileSync(SECRET_FILE, 'utf-8').trim();
} else {
  AUTH_SECRET = randomBytes(32).toString('hex');
  writeFileSync(SECRET_FILE, AUTH_SECRET);
}

function loadUsers() {
  if (!existsSync(USERS_FILE)) return {};
  try { return JSON.parse(readFileSync(USERS_FILE, 'utf-8')); } catch { return {}; }
}
function saveUsers(users) {
  writeFileSync(USERS_FILE, JSON.stringify(users, null, 2));
}

function hashPassword(password, salt) {
  return scryptSync(password, salt, 64).toString('hex');
}
function verifyPassword(password, salt, expectedHash) {
  const actual = Buffer.from(hashPassword(password, salt), 'hex');
  const expected = Buffer.from(expectedHash, 'hex');
  return actual.length === expected.length && timingSafeEqual(actual, expected);
}

function makeToken(email) {
  const payload = Buffer.from(JSON.stringify({ email, ts: Date.now() })).toString('base64url');
  const sig = createHmac('sha256', AUTH_SECRET).update(payload).digest('base64url');
  return payload + '.' + sig;
}
function verifyToken(token) {
  if (!token) return null;
  const [payload, sig] = token.split('.');
  if (!payload || !sig) return null;
  const expected = createHmac('sha256', AUTH_SECRET).update(payload).digest('base64url');
  if (sig.length !== expected.length || !timingSafeEqual(Buffer.from(sig), Buffer.from(expected))) return null;
  try { return JSON.parse(Buffer.from(payload, 'base64url').toString()); } catch { return null; }
}

// Returns the user record (minus secrets) for a request's bearer token, or null
function authUser(req) {
  const auth = req.headers['authorization'] || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
  const claim = verifyToken(token);
  if (!claim) return null;
  const users = loadUsers();
  const u = users[claim.email];
  if (!u) return null;
  return { email: claim.email, ...u };
}

// Strip sensitive fields before returning a user to the client
function publicUser(email, u) {
  return {
    email,
    name: u.name || '',
    subscription: u.subscription || { plan: 'free', status: 'active', since: u.createdAt },
    createdAt: u.createdAt,
  };
}

// ─── Email (share via email with attachment) ─────────────────
// Build a transport. Uses real SMTP from .env if configured, otherwise
// falls back to an Ethereal test account (delivers to a preview URL).
let cachedTransport = null;
async function getMailTransport() {
  if (cachedTransport) return cachedTransport;
  if (process.env.SMTP_HOST && process.env.SMTP_USER && process.env.SMTP_PASS) {
    cachedTransport = {
      transport: nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: Number(process.env.SMTP_PORT) || 587,
        secure: String(process.env.SMTP_SECURE) === 'true',
        auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
      }),
      from: process.env.SMTP_FROM || process.env.SMTP_USER,
      mode: 'smtp',
    };
  } else {
    // No real SMTP — create a throwaway Ethereal account for testing
    const testAccount = await nodemailer.createTestAccount();
    cachedTransport = {
      transport: nodemailer.createTransport({
        host: 'smtp.ethereal.email', port: 587, secure: false,
        auth: { user: testAccount.user, pass: testAccount.pass },
      }),
      from: 'FlyPDF <no-reply@flypdf.app>',
      mode: 'ethereal',
    };
  }
  return cachedTransport;
}

const SYSTEM = 'You are FlyPDF AI Assistant — a helpful PDF analysis tool. Be concise and use markdown formatting. When analyzing documents, highlight key numbers with **bold**.';

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

function json(res, data, status = 200) {
  cors(res);
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(data));
}

function readBody(req) {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', c => body += c);
    req.on('end', () => resolve(body));
  });
}

function buildMessages(text, docId) {
  let content = text;
  if (docId && documents.has(docId)) {
    const doc = documents.get(docId);
    content = `<document>\n${doc.filename}\n\n${doc.text.slice(0, 20000)}\n</document>\n\n${text}`;
  }
  return [
    { role: 'system', content: SYSTEM },
    { role: 'user', content },
  ];
}

const server = createServer(async (req, res) => {
  cors(res);

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    return res.end();
  }

  const url = new URL(req.url, `http://localhost:${PORT}`);

  // Health
  if (url.pathname === '/health' && req.method === 'GET') {
    return json(res, { status: 'ok', model: MODEL, has_key: !!groq });
  }

  // ─── Auth ───────────────────────────────────────────────
  // Register a new user
  if (url.pathname === '/auth/register' && req.method === 'POST') {
    let body;
    try { body = JSON.parse(await readBody(req)); } catch { return json(res, { error: 'Invalid request' }, 400); }
    const email = (body.email || '').trim().toLowerCase();
    const password = body.password || '';
    const name = (body.name || '').trim();
    if (!email || !email.includes('@')) return json(res, { error: 'Valid email required' }, 400);
    if (password.length < 6) return json(res, { error: 'Password must be at least 6 characters' }, 400);

    const users = loadUsers();
    if (users[email]) return json(res, { error: 'An account with this email already exists' }, 409);

    const salt = randomBytes(16).toString('hex');
    users[email] = {
      name,
      salt,
      passwordHash: hashPassword(password, salt),
      subscription: { plan: 'free', status: 'active', since: new Date().toISOString() },
      createdAt: new Date().toISOString(),
    };
    saveUsers(users);
    return json(res, { token: makeToken(email), user: publicUser(email, users[email]) }, 201);
  }

  // Login an existing user
  if (url.pathname === '/auth/login' && req.method === 'POST') {
    let body;
    try { body = JSON.parse(await readBody(req)); } catch { return json(res, { error: 'Invalid request' }, 400); }
    const email = (body.email || '').trim().toLowerCase();
    const password = body.password || '';
    const users = loadUsers();
    const u = users[email];
    // Same generic error for missing user / wrong password (avoid enumeration)
    if (!u || !verifyPassword(password, u.salt, u.passwordHash)) {
      return json(res, { error: 'Invalid email or password' }, 401);
    }
    return json(res, { token: makeToken(email), user: publicUser(email, u) });
  }

  // Current user (from bearer token)
  if (url.pathname === '/auth/me' && req.method === 'GET') {
    const u = authUser(req);
    if (!u) return json(res, { error: 'Not authenticated' }, 401);
    return json(res, { user: publicUser(u.email, u) });
  }

  // Update the authenticated user's subscription
  if (url.pathname === '/auth/subscription' && req.method === 'POST') {
    const u = authUser(req);
    if (!u) return json(res, { error: 'Not authenticated' }, 401);
    let body;
    try { body = JSON.parse(await readBody(req)); } catch { return json(res, { error: 'Invalid request' }, 400); }
    const plan = body.plan === 'pro' ? 'pro' : 'free';
    const users = loadUsers();
    users[u.email].subscription = {
      plan,
      status: 'active',
      since: new Date().toISOString(),
    };
    saveUsers(users);
    return json(res, { user: publicUser(u.email, users[u.email]) });
  }

  // ─── Share via email (with PDF attachment) ──────────────
  if (url.pathname === '/share/email' && req.method === 'POST') {
    const sender = authUser(req);
    let body;
    try { body = JSON.parse(await readBody(req)); } catch { return json(res, { error: 'Invalid request' }, 400); }
    const to = (body.to || '').trim();
    const filename = (body.filename || 'Document.pdf').replace(/[\r\n]/g, '');
    const message = (body.message || '').toString().slice(0, 2000);
    const fileBase64 = body.fileBase64 || '';
    if (!to || !to.includes('@')) return json(res, { error: 'Valid recipient email required' }, 400);
    if (!fileBase64) return json(res, { error: 'No file to send' }, 400);

    // Limit attachment size (~10MB of base64)
    if (fileBase64.length > 14_000_000) return json(res, { error: 'File too large to email (max ~10MB)' }, 413);

    try {
      const { transport, from, mode } = await getMailTransport();
      const senderName = sender ? (sender.name || sender.email) : 'A FlyPDF user';
      const info = await transport.sendMail({
        from,
        to,
        subject: `${senderName} shared "${filename}" with you`,
        text: (message ? message + '\n\n' : '') + `${senderName} sent you a document via FlyPDF.`,
        html: `<div style="font-family:-apple-system,Segoe UI,Roboto,sans-serif;max-width:480px">
          <h2 style="color:#0A84FF;margin:0 0 8px">FlyPDF</h2>
          <p style="font-size:15px;color:#222">${senderName} shared a document with you:</p>
          ${message ? `<p style="font-size:14px;color:#444;background:#F5F5F7;padding:12px;border-radius:10px">${message.replace(/</g,'&lt;')}</p>` : ''}
          <p style="font-size:14px;color:#666">📎 <strong>${filename}</strong> is attached to this email.</p>
        </div>`,
        attachments: [{ filename, content: Buffer.from(fileBase64, 'base64'), contentType: 'application/pdf' }],
      });
      const preview = mode === 'ethereal' ? nodemailer.getTestMessageUrl(info) : null;
      return json(res, { ok: true, mode, messageId: info.messageId, preview });
    } catch (e) {
      return json(res, { error: 'Failed to send: ' + e.message }, 500);
    }
  }

  // Chat
  if (url.pathname === '/chat' && req.method === 'POST') {
    if (!groq) return json(res, { error: 'API key not configured' }, 503);
    const { message, document_id } = JSON.parse(await readBody(req));
    const messages = buildMessages(message, document_id);
    const completion = await groq.chat.completions.create({
      model: MODEL, messages, max_tokens: 1024,
    });
    return json(res, { response: completion.choices[0].message.content });
  }

  // Chat Stream
  if (url.pathname === '/chat/stream' && req.method === 'POST') {
    if (!groq) return json(res, { error: 'API key not configured' }, 503);
    const { message, document_id } = JSON.parse(await readBody(req));
    const messages = buildMessages(message, document_id);

    cors(res);
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    });

    const stream = await groq.chat.completions.create({
      model: MODEL, messages, max_tokens: 1024, stream: true,
    });

    for await (const chunk of stream) {
      const delta = chunk.choices[0]?.delta?.content;
      if (delta) res.write(`data: ${delta}\n\n`);
    }
    res.write('data: [DONE]\n\n');
    return res.end();
  }

  // Analyze
  if (url.pathname === '/analyze' && req.method === 'POST') {
    if (!groq) return json(res, { error: 'API key not configured' }, 503);
    const { document_id, task = 'summarize' } = JSON.parse(await readBody(req));
    if (!documents.has(document_id)) return json(res, { error: 'Document not found' }, 404);

    const prompts = {
      summarize: 'Summarize this document concisely. Highlight key figures with **bold**.',
      key_numbers: 'Extract all key numbers, metrics, and financial figures. Format as a bullet list.',
      red_flags: 'Identify any potential concerns, risks, or red flags in this document.',
      extract_tables: 'Identify and describe any tables found in this document.',
    };
    const messages = buildMessages(prompts[task] || task, document_id);
    const completion = await groq.chat.completions.create({
      model: MODEL, messages, max_tokens: 1024,
    });
    return json(res, { response: completion.choices[0].message.content, task });
  }

  // Upload document (text extracted client-side via PDF.js)
  if (url.pathname === '/documents/upload' && req.method === 'POST') {
    const { filename, text, pages } = JSON.parse(await readBody(req));
    const id = 'doc_' + Date.now();
    documents.set(id, { filename, text, pages, uploadedAt: new Date().toISOString() });
    return json(res, { document_id: id, filename, pages, chars: text.length });
  }

  // List documents
  if (url.pathname === '/documents' && req.method === 'GET') {
    const list = [...documents.entries()].map(([id, d]) => ({ id, filename: d.filename, pages: d.pages, uploadedAt: d.uploadedAt }));
    return json(res, { documents: list });
  }

  // 404
  json(res, { error: 'Not found' }, 404);
});

server.listen(PORT, () => {
  console.log(`FlyPDF API running on http://localhost:${PORT}`);
  console.log(`Model: ${MODEL}`);
  console.log(`Groq API: ${groq ? 'connected' : 'NOT configured'}`);
  console.log(`Auth: enabled · ${Object.keys(loadUsers()).length} user(s) registered`);
  const smtpReal = !!(process.env.SMTP_HOST && process.env.SMTP_USER && process.env.SMTP_PASS);
  console.log(`Email: ${smtpReal ? 'real SMTP (' + process.env.SMTP_HOST + ')' : 'test mode (Ethereal — preview URLs)'}`);
});
