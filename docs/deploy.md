# GitHub 中继部署（方案 A）

> 目的：让 GitHub Actions 每 30 分钟自动抓取 portwatch 数据、翻译成中文、发布 `card.json`，手机卡片直接读。

## 1. 建仓库

- GitHub 新建 **public** 仓库，例如 `portwatch-card`（public 的 Actions 免费不限量）。
- 把本项目这些内容推上去：

```
relay/relay.mjs
relay/lib/scoring.mjs
.github/workflows/relay.yml
```

（`relay/.cache/translations.json` 第一次运行后自动生成，会一起提交，用于增量翻译。）

## 2. 启用 Actions

- 仓库 → Settings → Actions → General → 允许 workflows。
- 打开 Actions → `relay` → **Run workflow** 手动跑一次。
- 等 1–2 分钟，检查 `relay/card.json` 是否生成、内容是不是中文。

## 3. 拿到卡片数据地址

```
https://raw.githubusercontent.com/<你的用户名>/portwatch-card/main/relay/card.json
```

把这个地址填进鸿蒙工程 `CardData.ets` 的 `CARD_URL`，然后重新编译 HAP。

## 4. 验证

浏览器直接打开上面的地址，应返回 JSON（`top.score`、`news[].titleZh` 都是中文）。

## 5. 调整频率

`.github/workflows/relay.yml` 里：

```yaml
schedule:
  - cron: '*/30 * * * *'   # 每 30 分钟
```

源站每 3 小时才更新，30 分钟已经足够；想省额度可以改成 `0 */3 * * *`。

## 依赖与限额

| 项 | 说明 |
|---|---|
| Actions 免费额度 | public 仓库不限；private 2000 分钟/月（30 分钟/次约 480 分钟/月，也够） |
| MyMemory 翻译 | 匿名每天约 5000 字符，增量更新后每天只翻 1–2 条，够用 |
| 网络 | 本机实测 GitHub raw、MyMemory 均可直连 |
