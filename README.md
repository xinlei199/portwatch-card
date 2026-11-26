# portwatch-widget

GTA6 PC 移植进度鸿蒙桌面卡片（4×4，约半屏）。

## 结构

```
portwatch-widget/
├── relay/                      # 数据中继（Node）
│   ├── relay.mjs               # 抓取 + 算分 + 翻译 → card.json
│   ├── lib/scoring.mjs         # 复用 portwatch 官方评分算法
│   ├── card.json               # 产出（自动更新，约 1.5 KB）
│   └── .cache/                 # 翻译缓存（增量）
├── .github/workflows/relay.yml # 每 30 分钟自动跑
├── harmony-src/                # 鸿蒙工程源码（API 26 / 鸿蒙 7）
│   └── entry/src/main/ets/     # EntryAbility / FormExtensionAbility / 卡片 / 详情页
└── docs/
    ├── build-install.md        # 编译与安装
    └── deploy.md               # GitHub 部署
```

## 三步跑起来

1. **部署中继**：按 [deploy.md](docs/deploy.md) 建 GitHub 仓库，拿到 `card.json` 的 raw 地址。
2. **填地址**：把地址填进 `harmony-src/.../common/CardData.ets` 的 `CARD_URL`。
3. **编译安装**：按 [build-install.md](docs/build-install.md) 在 PC 上编出 HAP，`hdc install` 到手机。

## 当前状态

- [x] 中继跑通（本机实测，输出中文 `card.json`，1.5 KB）
- [x] GitHub Actions 定时任务配置
- [x] 鸿蒙卡片源码（4×4 动态卡 + 详情页）
- [x] GitHub 仓库部署（xinlei199/portwatch-card，Actions 自动更新 card.json）
- [x] HAP 编译通过（GitHub Actions Linux 环境，产物 94 KB）
- [ ] 真机安装 + 桌面添加卡片（需要手机操作）

## 设计要点

- **数据**：portwatch `tracker.json`，源站每 3 小时更新
- **刷新**：卡片 30 分钟定时（鸿蒙系统最小值）+ 点「刷新」立即拉
- **翻译**：MyMemory 免费接口，按句切分、增量缓存，不消耗 token
- **评分**：直接复用 `scoring.js`，与官网 0–100 分一致
