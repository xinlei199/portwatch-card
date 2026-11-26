# portwatch-widget 经验复盘

> 完成时间：2026-11-26 · 状态：HAP 编译通过，待真机安装

## 结果

- 数据中继：GitHub Actions 每 30 分钟抓取 + 翻译，自动提交 `card.json`（约 1.5 KB）
- 鸿蒙工程：GitHub Actions Linux 环境编译通过，产出 `entry-default-unsigned.hap`（94 KB）
- 仓库：https://github.com/xinlei199/portwatch-card

## 踩过的坑（按出现顺序）

| # | 现象 | 原因 | 解决 |
|---|---|---|---|
| 1 | 直连 portwatch 偶发超时 | Cloudflare 链路抖动 | 重试 5 次 + 20s 超时 |
| 2 | raw.githubusercontent.com ECONNRESET | 国内网络不稳 | 重试；卡片端用 gh-proxy.com 兜底 |
| 3 | 网站无中文 | i18n 只有 en/pt-BR/es | MyMemory 翻译 + 增量缓存 |
| 4 | hvigor 找不到 @ohos/hvigor-ohos-plugin | 包不在 npmjs | `~/.npmrc` 只对 `@ohos` 指 `repo.harmonyos.com/npm` |
| 5 | `npm install pnpm` 失败 | 全局 registry 被改成鸿蒙源 | 全局 registry 保持 npmjs，只 scope 覆盖 |
| 6 | hvigor「project structure needs upgrade」 | 配置键写成 `hvigorVersion` | 改 `modelVersion` + 加 `compileSdkVersion` |
| 7 | `$media:app_icon` 未定义 | 缺图标资源 | Python 生成 216×216 PNG |
| 8 | ArkTS：`postCardAction` 不在 @kit.ArkUI | 卡片内是全局函数 | 删除 import |
| 9 | ArkTS：`FormExtensionContext` 无 `formId` | API 设计如此 | 从 `want.parameters['ohos.extra.param.key.form_identity']` 取 |
| 10 | ArkTS：对象字面量不能当类型 | arkts-no-obj-literals-as-types | 嵌套对象单独定义 interface |
| 11 | git push 连不上 github.com:443 | TLS/网络抖动 | 改用 GitHub Git Data API 提交（blobs→tree→commit→ref） |
| 12 | push 被拒（non-fast-forward） | Actions 自动提交 card.json | `git pull --rebase`，card.json 取远端 |

## 关键决策

- 数据源用官方 `tracker.json` 而非爬 HTML；评分直接复用 `scoring.js`
- 卡片只读一个 1.5 KB 的 `card.json`，不直接拉 304 KB 源数据
- 翻译在云端 Actions 做，不进卡片、不耗 token
- HAP 只编一次，数据更新走 GitHub，**之后完全不用碰电脑**

## 教训

- 鸿蒙工程配置的版本字段极易踩坑，**能抄官方模板就抄**，不要凭记忆写。
- 没有本地工具链时，**先用 GitHub Actions 的 Linux 环境验证编译**，比让用户在本地盲试快得多。
- 网络不稳时，**API 和 git 协议互为备份**。
