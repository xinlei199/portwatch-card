#!/usr/bin/env node
// portwatch 数据 → 算分 → 中文翻译 → 卡片数据 card.json
// 数据源: https://portwatch-vi.xyz/data/tracker.json （每 3 小时更新）
// 用法: node relay.mjs [输出路径] [本地 tracker.json（可选，测试用）]
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SRC = 'https://portwatch-vi.xyz/data/tracker.json';
const OUT = process.argv[2] || path.join(__dirname, 'card.json');
const LOCAL = process.argv[3];
const CACHE_FILE = path.join(__dirname, '.cache', 'translations.json');

const { overall } = await import(path.join(__dirname, 'lib', 'scoring.mjs'));

const MILESTONE_ZH = {
  groundwork: '基础铺垫', loads: '可执行文件运行', boots: '首帧画面',
  menu: '主菜单', world: '进入游戏世界', playable: '可游玩', complete: '完整通关',
};
const CATEGORY_ZH = {
  Port: '移植进展', Leak: '泄露', Legal: '法律', Scam: '诈骗',
  Official: '官方', Takedown: '下架', DMCA: '版权', Community: '社区',
};

function loadCache() {
  try { return JSON.parse(fs.readFileSync(CACHE_FILE, 'utf8')); } catch { return {}; }
}
function saveCache(c) {
  fs.mkdirSync(path.dirname(CACHE_FILE), { recursive: true });
  fs.writeFileSync(CACHE_FILE, JSON.stringify(c, null, 1));
}
const sha1 = (s) => crypto.createHash('sha1').update(s).digest('hex').slice(0, 20);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function fetchJson(url, tries = 5) {
  for (let i = 1; i <= tries; i++) {
    try {
      const r = await fetch(url, { headers: { 'user-agent': 'Mozilla/5.0' }, signal: AbortSignal.timeout(25000) });
      if (r.ok) return await r.json();
    } catch { /* retry */ }
    await sleep(1200 * i);
  }
  throw new Error('fetch failed: ' + url);
}

// 按句子切分，单段不超过 max 字符（MyMemory 的 q 上限约 500 字节）
function splitChunks(text, max = 420) {
  const sentences = text.match(/[^.!?]+[.!?]+["')\]]?\s*|[^.!?]+$/g) || [text];
  const out = [];
  let cur = '';
  for (const s of sentences) {
    if ((cur + s).length > max) { if (cur) out.push(cur); cur = s; }
    else cur += s;
  }
  if (cur) out.push(cur);
  return out;
}

const cache = loadCache();
async function translateChunk(chunk) {
  const key = sha1(chunk);
  if (cache[key]) return cache[key];
  const url = 'https://api.mymemory.translated.net/get?q=' + encodeURIComponent(chunk) + '&langpair=en|zh-CN';
  for (let i = 1; i <= 3; i++) {
    try {
      const r = await fetch(url, { signal: AbortSignal.timeout(15000) });
      const j = await r.json();
      const t = j?.responseData?.translatedText;
      if (t && j.responseStatus === 200) {
        cache[key] = t;
        saveCache(cache);
        return t;
      }
    } catch { /* retry */ }
    await sleep(900 * i);
  }
  return chunk; // 翻译失败保留原文，不阻塞发布
}
// 机器翻译常见错译修正（MyMemory 对游戏/榜单术语不稳定）
const POST_FIX = [
  [/我们主板上的/g, '我们在榜单上追踪的'],
  [/主板上的/g, '榜单上的'],
  [/构建了/g, '版本'],
  [/清晰序幕/g, '序章'],
  [/全AMD配置/g, '全 AMD 平台'],
  [/AMD配置/g, 'AMD 平台'],
];

async function translate(text) {
  if (!text) return '';
  const parts = [];
  for (const c of splitChunks(text)) {
    parts.push(await translateChunk(c));
    await sleep(600); // MyMemory 限速，逐段串行
  }
  let out = parts.join('');
  for (const [re, rep] of POST_FIX) out = out.replace(re, rep);
  return out;
}

// ---- 主流程 ----
const data = LOCAL ? JSON.parse(fs.readFileSync(LOCAL, 'utf8')) : await fetchJson(SRC);
const efforts = (data.efforts || []).filter((e) => e.tier === 'tracked');
const ov = overall(efforts);
const leader = ov.leader;

const news = [...(data.news || [])]
  .sort((a, b) => new Date(b.publishedAt || b.date) - new Date(a.publishedAt || a.date))
  .slice(0, 3);

const newsZh = [];
for (const n of news) {
  newsZh.push({
    date: n.date,
    categoryZh: CATEGORY_ZH[n.category] || n.category,
    titleZh: await translate(n.title),
    dekZh: await translate(n.dek || ''),
    link: `https://portwatch-vi.xyz/news/${n.id}`,
  });
}

const card = {
  updatedAt: data.updated,
  builtAt: new Date().toISOString(),
  top: leader ? {
    name: leader.effort.name,
    score: leader.score,
    reachedZh: MILESTONE_ZH[leader.reached] || leader.reached,
    fps: leader.effort.gta?.fps ?? null,
    repo: leader.effort.repo || null,
  } : null,
  top3: ov.top3,
  news: newsZh,
  exe: data.exe ? {
    status: data.exe.status,
    releasedAt: data.exe.releasedAt || null,
  } : null,
  source: 'https://portwatch-vi.xyz',
};

fs.writeFileSync(OUT, JSON.stringify(card, null, 1));
console.log('OK ->', OUT, '| leader:', card.top?.name, card.top?.score + '%');
console.log('news:', newsZh.map((n) => n.titleZh).join(' | ').slice(0, 200));
