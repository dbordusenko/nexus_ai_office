import { createServer } from 'http';
import { readFileSync, existsSync } from 'fs';
import Groq from 'groq-sdk';

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

const SYSTEM = 'You are FlyPDF AI Assistant — a helpful PDF analysis tool. Be concise and use markdown formatting. When analyzing documents, highlight key numbers with **bold**.';

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
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

  // 404
  json(res, { error: 'Not found' }, 404);
});

server.listen(PORT, () => {
  console.log(`FlyPDF API running on http://localhost:${PORT}`);
  console.log(`Model: ${MODEL}`);
  console.log(`Groq API: ${groq ? 'connected' : 'NOT configured'}`);
});
