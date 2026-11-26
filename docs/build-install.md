# 编译与安装（鸿蒙 7 / API 26）

> 目标：把卡片装进鸿蒙 7 手机桌面。**HAP 只需编译一次，之后数据更新完全自动，不用再碰电脑。**

## 前置

| 项 | 要求 |
|---|---|
| 鸿蒙设备 | HarmonyOS 7 / API 26，已开「开发者模式」+「USB 调试」 |
| 电脑 | 一次性用：Windows 10/11（DevEco Studio 6.x）或 Linux x86_64（命令行工具） |
| 账号 | unsigned 安装不需要华为账号；如果系统拒绝 unsigned，才需要 |

## 方式一：Windows + DevEco Studio（最省事，一次性）

1. 装 [DevEco Studio 6.x](https://developer.huawei.com/consumer/cn/download/)（选 API 26 版本）。
2. 新建工程：**Empty Ability**（Stage 模型），工程名 `portwatch-card`，bundleName `com.portwatch.card`，API 26。
3. 把 `harmony-src/` 里这些文件覆盖进新工程（路径一一对应）：

| 新工程里 | 用这里的文件覆盖 |
|---|---|
| `entry/src/main/ets/entryability/EntryAbility.ets` | `harmony-src/.../entryability/EntryAbility.ets` |
| `entry/src/main/ets/entryformability/EntryFormAbility.ets` | 新建，同名 |
| `entry/src/main/ets/common/CardData.ets` | 新建，同名 |
| `entry/src/main/ets/widget/pages/PortCard.ets` | 新建，同名 |
| `entry/src/main/ets/pages/Index.ets` | 覆盖 |
| `entry/src/main/resources/base/profile/form_config.json` | 新建 |
| `entry/src/main/resources/base/profile/main_pages.json` | 覆盖 |
| `entry/src/main/resources/base/element/string.json` | 合并（加入 form 相关几条） |
| `entry/src/main/module.json5` | 按模板补 `extensionAbilities` + `requestPermissions` 两段（不要整文件替换） |

4. 改 `CardData.ets` 里的 `CARD_URL`（见 `deploy.md` 拿到的地址）。
5. **Build → Build Hap(s)**，产物在 `entry/build/default/outputs/default/`。
6. 手机连 USB，执行：

```bash
hdc install entry-default-unsigned.hap
```

> API 26 真机通常允许 unsigned HAP 直接装。如果报 `no signature file`：
> DevEco → File → Project Structure → Signing Configs → 勾选「Automatically generate signature」（登录华为账号），重新 Build 后再 `hdc install`。

7. 回桌面长按空白 → 服务卡片 → 找到「GTA6 进度」→ 4×4 → 添加。

## 方式二：Linux x86_64 命令行（统信 UOS 可用）

官方 **Command Line Tools 只有 Windows/macOS 版**（缺 ARM 版，x86 Linux 有社区验证的用法）。这条路可行但更折腾：

1. 装 DevEco Command Line Tools（Linux x86_64，含 hvigor / ohpm / SDK / hdc）。
2. `hvigorw assembleHap` 编译出 unsigned HAP。
3. `hdc install xxx-unsigned.hap` 安装。

> 若这条链路在你的统信机上跑不通，退回方式一。**不要在 Linux 上死磕签名**——unsigned 能装就不需要签名。

## 数据更新（装好之后）

- GitHub Actions 每 30 分钟抓取 + 翻译 + 更新 `card.json`。
- 卡片每 30 分钟自动拉一次，点卡片上的「刷新」可立即拉取。
- 改文案/UI 才需要重新编译，**改数据不需要**。

## 排错

| 现象 | 处理 |
|---|---|
| 卡片空白 / 显示「加载中」 | 检查手机能否访问 `raw.githubusercontent.com`；点「刷新」重试 |
| `hdc install` 报 9568320 | unsigned 被拒 → 走自动签名 |
| 卡片列表里找不到 | 确认 module.json5 的 `extensionAbilities` 和 `form_config.json` 已生效 |
| 进度不更新 | Actions 是否启用、`card.json` 的 `updatedAt` 是否在变 |
