# 等有网络条件时的安装指南

> 现状：HAP 已编好（`/sdcard/Download/DSH-Go/portwatch-card.hap`，94 KB，unsigned），数据中继已在 GitHub 自动运行。只差「装进手机」。

## 前置条件（二选一）

| 条件 | 能做什么 |
|---|---|
| 手机和统信电脑在**同一 WiFi** | 统信跑 hdc，完整走通「连设备 → 拿 UDID → 签名 → 安装」 |
| 手机连 **Windows 电脑**（Win10 也够） | DevEco Studio 一键自动签名 + 安装，最省事 |

## 方案 A：统信 + hdc（推荐，全程 Linux）

### 1. 统信上装命令行工具

```bash
mkdir -p ~/ohos && cd ~/ohos
B="https://gh-proxy.com/https://github.com/ErBWs/ohos-sdk/releases/latest/download"
curl -fL "$B/ohos-sdk-linux-amd64.tar.gz.aa" -o a.aa
curl -fL "$B/ohos-sdk-linux-amd64.tar.gz.ab" -o a.ab
curl -fL "$B/ohos-sdk-linux-amd64.tar.gz.sha256" -o a.sha256
cat a.aa a.ab > ohos-sdk-linux-amd64.tar.gz
sha256sum -c a.sha256 && tar -xzf ohos-sdk-linux-amd64.tar.gz
export PATH="$HOME/ohos/command-line-tools/bin:$HOME/ohos/command-line-tools/tool/node/bin:$PATH"
export DEVECO_SDK_HOME="$HOME/ohos/command-line-tools/sdk"
hdc -v
```

### 2. 连手机（手机开无线调试，看 IP:端口）

```bash
hdc tconn <手机IP>:<端口>      # 例如 192.168.78.195:37269
hdc list targets
hdc shell bm get --udid        # 记下 UDID，签名要用
```

### 3. 签名材料

需要 **Java**（`sudo apt install openjdk-17-jre-headless`）和 `hap-sign-tool.jar`（command-line-tools 的 SDK 里，搜 `find ~/ohos -name 'hap-sign-tool.jar'`）。

1. 生成私钥和 CSR：

```bash
openssl genrsa -out key.pem 2048
openssl req -new -key key.pem -out csr.csr -subj "/C=CN/O=PortWatch/CN=portwatch-card"
```

2. 手机浏览器登录 [AGC](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)：
   - 证书管理 → 新增证书 → **调试证书** → 上传 `csr.csr` → 下载 `.cer`（改名为 `cert.cer`）
   - Profile 管理 → 添加 → 选该证书、包名 `com.portwatch.card`、设备（填 UDID）→ 下载 `.p7b`（改名为 `profile.p7b`）
3. 打包 p12 + 签名：

```bash
openssl pkcs12 -export -in cert.cer -inkey key.pem -out cert.p12 -name "portwatch" -passout pass:123456

java -jar hap-sign-tool.jar sign-app \
  -keyAlias "portwatch" -signAlg "SHA256withECDSA" -mode "localSign" \
  -appCertFile cert.cer -profileFile profile.p7b \
  -inFile portwatch-card.hap -outFile portwatch-card-signed.hap \
  -keystoreFile cert.p12 -keyPwd 123456 -keystorePwd 123456
```

### 4. 安装

```bash
hdc install -r portwatch-card-signed.hap
```

### 5. 桌面加卡片

长按桌面空白 → 服务卡片 → 找到「GTA6 进度」→ 选 **4×4** → 添加。

## 方案 B：Windows + DevEco（最省事）

1. DevEco Studio 打开 `harmony-src` 工程（或按 `build-install.md` 新建工程放源码）。
2. File → Project Structure → Signing Configs → 勾选 **Automatically generate signature**（登录华为账号）。
3. Build → Build Hap(s)。
4. USB 连手机，`hdc install -r entry-default-signed.hap`。

> unsigned HAP 在 API 26 有可能直接装（`hdc install entry-default-unsigned.hap`），先试一次，成了就不用签名。

## UDID 怎么找

- 有 hdc 时：`hdc shell bm get --udid`
- 没有 hdc 时：设置里通常没有，只能走 hdc 或 DevEco。

## 装好之后的维护

- 数据每 30 分钟自动更新（GitHub Actions），不用碰电脑。
- 卡片点「刷新」立即拉。
- 改数据不用重编；改 UI 才需要重编。
