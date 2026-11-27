# 交接文档：portwatch 卡片 + 鸿蒙 HAP 签名安装

> 建立于 2026-11-27。整合三部分：① 106 上的《HAP 签名安装手册》实战 ② 手机侧（卓易通/DSH）踩坑 ③ 项目复盘。
> 给下一个接手的 AI / 未来的自己：**先读完本文件再动手**。

---

## 0. 一句话状态

- ✅ 数据中继已上线：GitHub Actions 每 30 分钟抓取 + 翻译 + 更新 `card.json`
- ✅ 卡片源码已写完，HAP 已编译（94 KB，unsigned）
- ✅ **dsh-go 鸿蒙版**（`ccchimneyyy.dsh.go`）已签名并安装成功
- ❌ **portwatch 卡片（`com.portwatch.card`）尚未安装** —— 卡在「包名被改 + 需要为它单独生成 Profile」
- ⚠️ 106 上的 portwatch 工程可能残留 dsh-go 的 bundleName（见 P8），**先检查再构建**

---

## 1. 资产清单

| 项 | 值 |
|---|---|
| 数据仓库 | https://github.com/xinlei199/portwatch-card |
| 卡片源码 | 仓库 `harmony-src/`（bundleName 应为 `com.portwatch.card`） |
| 卡片 HAP（unsigned） | 手机 `/sdcard/Download/DSH-Go/portwatch-card.hap`；或 Actions 的 `portwatch-hap` artifact |
| 数据文件 | 仓库 `relay/card.json`（约 1.5 KB，中文） |
| Actions | `relay`（每 30 分钟）+ `build-hap`（手动/推送触发） |
| 目标设备 | VYG-AL00 · OpenHarmony 7.0.0.111 · API 26 |
| 设备 UDID | `AFD71C147BA133F7CF48698B6FF1639993B3C52D3A7207D50D0533CDD27267D9` |
| 签名机器 | 106 · Windows 10 · DevEco Studio 26.0.1.290（`D:\DevEco Studio`） |
| SDK | 26.0.1（`sdk\default`，hvigor 插件 6.26.20，JBR 25.0.2，node 24.14.1） |
| 签名材料 | 106 `C:\Users\Lenovo\.ohos\config\` 的 `.p12/.cer/.p7b`；**密码已加密存 `.sign/sign-config.json5`，明文见原手册/安全位置，勿外传** |

---

## 2. 已完成

1. **数据层**：`relay/relay.mjs` 抓 portwatch `tracker.json` → 复用 `scoring.js` 算分 → MyMemory 增量翻译 → `card.json`；GitHub Actions 每 30 分钟提交。翻译不耗 token。
2. **卡片源码**：4×4 动态卡（进度、榜首、3 条新闻、刷新按钮）+ 详情页；数据双地址兜底（raw + gh-proxy）。
3. **HAP 编译**：GitHub Actions 的 ubuntu 环境用 `ErBWs/ohos-sdk` 编译通过，产物 artifact 可下载。
4. **dsh-go**：106 上重签 unsigned HAP → `hdc install` 成功。

---

## 3. 待办（接手第一件事）

### 3.1 纠正 portwatch 工程包名（P8 教训）

106 上的 portwatch 源码工程，`AppScope/app.json5` 的 `bundleName` 可能已被改成 `ccchimneyyy.dsh.go`（配置 dsh-go 签名时改的）。

**最干净的做法**：从 GitHub 重新 clone `harmony-src`，确认 `bundleName = com.portwatch.card`，不要复用被改过的副本。

### 3.2 为 com.portwatch.card 生成签名材料

现有 p12/cer 可复用，但 **Profile（p7b）按包名绑定**，必须为 `com.portwatch.card` 新生成一个：

1. DevEco 打开重新 clone 的 `harmony-src`（bundleName 确认是 `com.portwatch.card`）
2. `File → Project Structure → Signing Configs` → 勾选 **Automatically generate signature** → 登录华为账号
3. 自动签名会写入 `build-profile.json5` 的 `signingConfigs` 和 `.sign/sign-config.json5`

### 3.3 构建 + 安装

见第 4 节。安装后：

- 桌面长按空白 → 服务卡片 → 「GTA6 进度」→ 选 **4×4**
- 验证：显示百分比、榜首、中文新闻；点「刷新」能更新

### 3.4 收尾

- 备份签名材料（p12/cer/p7b + 密码）到手机/网盘
- 清理 106（见第 7 节）

---

## 4. 构建 / 签名 / 安装流程（106 实测）

### 4.1 工程配置（一次配好，之后不再报 SDK 错）

`hvigor/hvigor-config.json5` —— **dependencies 必须为空**（用 IDE 内置 6.26.20）：

```json5
{
  "modelVersion": "6.0.0",
  "dependencies": {},
  "execution": {},
  "logging": {},
  "debugging": {},
  "nodeOptions": {}
}
```

`build-profile.json5` —— 三段版本号组合：

```json5
{
  "app": {
    "signingConfigs": [ /* DevEco 自动签名写入 */ ],
    "products": [{
      "name": "default",
      "compileSdkVersion": "26.0.1",
      "compatibleSdkVersion": "26.0.0",
      "targetSdkVersion": "26.0.0",
      "signingConfig": "default",
      "runtimeOS": "HarmonyOS"
    }]
  }
}
```

### 4.2 构建

```powershell
$env:JAVA_HOME = "D:\DevEco Studio\jbr"
$env:DEVECO_SDK_HOME = "D:\DevEco Studio\sdk"
$env:PATH = "D:\DevEco Studio\jbr\bin;D:\DevEco Studio\tools\node;" + $env:PATH
Set-Location <工程目录>
& "D:\DevEco Studio\tools\node\node.exe" "D:\DevEco Studio\tools\hvigor\bin\hvigorw.js" assembleHap --mode module -p product=default --no-daemon
```

产物：`entry\build\default\outputs\default\entry-default-signed.hap`

### 4.3 重签外部 unsigned HAP（dsh-go 这类）

1. **解密密码**（DevEco 自动签名密码是加密存的，hap-sign-tool 只认明文）——用原手册第四节的 `decrypt-pwd.js`，输入 `.sign/sign-config.json5` 和 `~/.ohos/config/material`。
2. 用明文密码签：

```powershell
$jar = "D:\DevEco Studio\sdk\default\openharmony\toolchains\lib\hap-sign-tool.jar"
$java = "D:\DevEco Studio\jbr\bin\java.exe"
& $java -jar $jar sign-app -keyAlias debugKey -signAlg SHA256withECDSA -mode localSign `
  -appCertFile <cer> -profileFile <p7b> `
  -inFile dsh-go-unsigned.hap -outFile dsh-go-signed.hap `
  -keystoreFile <p12> -keyPwd <明文密码> -keystorePwd <明文密码>
```

成功标志：`Sign Hap success!`

### 4.4 安装

```powershell
& "D:\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe" install -r <signed.hap>
```

成功标志：`install bundle successfully.`

---

## 5. 踩坑全集

### 5.1 手机侧（卓易通 / DSH 环境）

| # | 现象 | 根因 | 解决 |
|---|---|---|---|
| M1 | 直接抓 portwatch 偶发超时 | Cloudflare 链路抖动 | 重试 5 次 + 20s 超时 |
| M2 | raw.githubusercontent.com 不稳 | 国内网络 | 镜像 `gh-proxy.com`；GitHub API 比 raw 稳 |
| M3 | 网站无中文 | i18n 仅 en/pt-BR/es | MyMemory 增量翻译，按句切分 |
| M4 | 本机编不了 HAP | 无鸿蒙工具链（aarch64） | 用 GitHub Actions ubuntu 编 |
| M5 | hvigor 找不到插件 | 包不在 npmjs | `~/.npmrc` 只对 `@ohos` 指 `repo.harmonyos.com/npm` |
| M6 | hvigor「project structure needs upgrade」 | 键写成 `hvigorVersion` | 改 `modelVersion` + 加 `compileSdkVersion` |
| M7 | `$media:app_icon` 未定义 | 缺图标 | 生成 PNG |
| M8 | ArkTS：`postCardAction` 不在 @kit.ArkUI | 卡片内是全局函数 | 删除 import |
| M9 | ArkTS：`FormExtensionContext` 无 formId | API 设计 | 从 `want.parameters['ohos.extra.param.key.form_identity']` 取 |
| M10 | ArkTS：对象字面量不能当类型 | arkts-no-obj-literals-as-types | 嵌套对象单独 interface |
| M11 | **卓易通连不上鸿蒙 hdc 端口** | 两套网络命名空间 | `127.0.0.1` 也不通，手机内 hdc 路线不可行（除非 DSH 跑在鸿蒙原生） |
| M12 | aarch64 跑 hdc 缺 3 个符号 | 标准 musl 缺 OpenHarmony 扩展 | `@h4xor/hdc-openharmony-arm64` + Alpine musl 1.2.5 + 自写垫片（在鸿蒙原生环境则无需垫片） |

### 5.2 106 侧（DevEco / hvigor / 签名）

| # | 现象 | 根因 | 解决 |
|---|---|---|---|
| P1 | Cannot find corresponding SDK version | `hvigor-config.json5` 写死旧插件 6.26.4 | **dependencies 留空**，用 IDE 内置 6.26.20 |
| P2 | compileSdkVersion 26.0.1 incompatible | 模板与 IDE 不一致 | 最终用 `compileSdk=26.0.1` + `compatible/target=26.0.0` |
| P3 | Specification Limit Violation | 版本写成 `"26"` | 必须三段 `26.0.0` / `26.0.1` |
| P4 | SDK 目录布局 default vs 版本目录 | 全量内置布局 | 不要手动改 `D:\DevEco Studio\sdk`；P1 修复后不需要动 |
| P5 | No signingConfig found | products 里缺 `"signingConfig": "default"` | 加上引用；与 `.sign/sign-config.json5` 保持一致 |
| P6 | 9568297 older sdk version in device | target 高于设备 | compatible/target 降到 26.0.0 |
| P7 | hap-sign-tool keystore password incorrect | 用了加密串 | 用第四节脚本解密成明文 |
| P8 | **装出来包名是 ccchimneyyy.dsh.go** | `AppScope/app.json5` 的 bundleName 被改 | **包名决定身份**；一个工程一个包名；p7b 的 bundle-name 必须与 HAP 一致 |
| P9 | GitHub release 直连超时 | 下载端点被阻断 | `gh-proxy.com` 镜像 |

---

## 6. 关键参数速查

| 项 | 值 |
|---|---|
| 卡片包名 | `com.portwatch.card` |
| dsh-go 包名 | `ccchimneyyy.dsh.go` |
| 设备 UDID | `AFD71C147BA133F7CF48698B6FF1639993B3C52D3A7207D50D0533CDD27267D9` |
| hdc | `D:\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe` |
| hap-sign-tool | `D:\DevEco Studio\sdk\default\openharmony\toolchains\lib\hap-sign-tool.jar` |
| hvigorw | `D:\DevEco Studio\tools\hvigor\bin\hvigorw.js` |
| 106 无 git | 源码用 SMB 传，或用 `gh-proxy.com` clone |
| 常用命令 | `hdc list targets` / `hdc shell bm get --udid` / `hdc shell bm dump -a` / `hdc uninstall <包名>` |

---

## 7. 安全与清理

- **密码明文是敏感信息**：不写进公开文档、不贴聊天；只存在本地安全位置。
- 签名材料（p12/cer/p7b + 密码）**务必备份**，以后换机/重装/Profile 过期复用；重新生成会换身份。
- 106 清理（用户确认后）：
  1. 备份 `C:\Users\Lenovo\.ohos\config\` 的 `.p12/.cer/.p7b`
  2. 删 `~\.ohos`、`~\.hvigor`、`~\AppData\Local\Huawei`、`~\AppData\Roaming\Huawei`
  3. 删 `D:\hap-sign-work`
  4. 卸载 DevEco Studio

---

## 8. 变更记录

- 2026-11-26：数据中继、卡片源码、HAP 编译、手机侧 hdc 探索（网络隔离确认）
- 2026-11-27：dsh-go 签名安装成功；本交接文档建立
- 待续：portwatch 卡片安装（包名纠正 + Profile 生成）
