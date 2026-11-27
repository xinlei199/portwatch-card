// 触发 GitHub Actions 跑 relay（token 存在手机本地，不进仓库）
// token 文件：entry/src/main/resources/rawfile/relay-token.txt
import { http } from '@kit.NetworkKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';

const DISPATCH_URL: string =
  'https://api.github.com/repos/xinlei199/portwatch-card/actions/workflows/relay.yml/dispatches';
const PREF_NAME: string = 'portwatch_cache';
const KEY_LAST: string = 'lastTriggerAt';
const MIN_GAP: number = 20 * 60 * 1000;

async function readToken(context: common.Context): Promise<string> {
  try {
    const bytes: Uint8Array = await context.resourceManager.getRawFileContent('relay-token.txt');
    const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
    const text: string = decoder.decodeToString(bytes);
    return text.trim();
  } catch (e) {
    // 文件不存在 = 用户没配置，静默跳过
    return '';
  }
}

export async function maybeTriggerRelay(context: common.Context): Promise<boolean> {
  const token: string = await readToken(context);
  if (token.length < 20) {
    return false;
  }
  try {
    const p = await preferences.getPreferences(context, PREF_NAME);
    const last: number = await p.get(KEY_LAST, 0) as number;
    const now: number = Date.now();
    if (now - last < MIN_GAP) {
      return false;
    }
    const req = http.createHttp();
    try {
      const resp = await req.request(DISPATCH_URL, {
        method: http.RequestMethod.POST,
        header: {
          'Authorization': 'Bearer ' + token,
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
          'User-Agent': 'PortWatchCard',
          'Content-Type': 'application/json'
        },
        extraData: '{"ref":"main"}',
        connectTimeout: 6000,
        readTimeout: 6000,
      });
      if (resp.responseCode === 204) {
        await p.put(KEY_LAST, now);
        await p.flush();
        return true;
      }
      return false;
    } finally {
      req.destroy();
    }
  } catch (e) {
    return false;
  }
}
