// 卡片数据模型 + 拉取/缓存逻辑
import { http } from '@kit.NetworkKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

// 卡片数据地址：直连 + 国内镜像兜底
export const CARD_URLS: string[] = [
  'https://raw.githubusercontent.com/xinlei199/portwatch-card/main/relay/card.json',
  'https://gh-proxy.com/https://raw.githubusercontent.com/xinlei199/portwatch-card/main/relay/card.json',
];

const PREF_NAME = 'portwatch_cache';
const KEY = 'cardJson';

export interface NewsItem {
  date: string;
  categoryZh: string;
  titleZh: string;
  dekZh: string;
  link: string;
}

export interface TopItem {
  name: string;
  score: number;
  reachedZh: string;
  fps: number | null;
  repo: string | null;
}

export interface CardData {
  updatedAt: string;
  builtAt: string;
  top: TopItem | null;
  top3: number;
  news: NewsItem[];
  exe: { status: string; releasedAt: string | null } | null;
  source: string;
}

export const EMPTY_CARD: CardData = {
  updatedAt: '',
  builtAt: '',
  top: null,
  top3: 0,
  news: [],
  exe: null,
  source: 'https://portwatch-vi.xyz',
};

export function parseCard(json: string): CardData {
  try {
    const obj = JSON.parse(json) as CardData;
    if (obj && typeof obj === 'object' && obj.news) {
      return obj;
    }
  } catch (e) {
    // ignore
  }
  return EMPTY_CARD;
}

// 相对时间：3 分钟前 / 2 小时前
export function relTime(iso: string): string {
  if (!iso) return '加载中';
  const t = Date.parse(iso);
  if (isNaN(t)) return '';
  const diff = Math.max(0, Date.now() - t);
  const min = Math.floor(diff / 60000);
  if (min < 1) return '刚刚';
  if (min < 60) return `${min} 分钟前`;
  const h = Math.floor(min / 60);
  if (h < 24) return `${h} 小时前`;
  return `${Math.floor(h / 24)} 天前`;
}

export async function fetchCard(): Promise<string | null> {
  for (const url of CARD_URLS) {
    const req = http.createHttp();
    try {
      const resp = await req.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 8000,
        readTimeout: 8000,
        header: { 'User-Agent': 'Mozilla/5.0 PortWatchCard' },
      });
      if (resp.responseCode === 200 && typeof resp.result === 'string') {
        return resp.result as string;
      }
    } catch (e) {
      // 换下一个地址
    } finally {
      req.destroy();
    }
  }
  return null;
}

export async function loadCache(context: common.Context): Promise<string | null> {
  try {
    const p = await preferences.getPreferences(context, PREF_NAME);
    const v = await p.get(KEY, '');
    if (typeof v === 'string' && v.length > 10) return v;
    return null;
  } catch (e) {
    return null;
  }
}

export async function saveCache(context: common.Context, json: string): Promise<void> {
  try {
    const p = await preferences.getPreferences(context, PREF_NAME);
    await p.put(KEY, json);
    await p.flush();
  } catch (e) {
    // ignore
  }
}
