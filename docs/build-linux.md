# 统信 UOS（Linux x86_64）命令行编译

> 官方 DevEco 只有 Windows/macOS 版，但社区维护的 `ErBWs/ohos-sdk` 提供 Linux amd64 版 HarmonyOS 命令行工具（26.0.0.821 / API 26），可以直接编译 unsigned HAP。

## 1. 下载命令行工具

```bash
mkdir -p ~/ohos && cd ~/ohos
B="https://gh-proxy.com/https://github.com/ErBWs/ohos-sdk/releases/latest/download"
curl -fL "$B/ohos-sdk-linux-amd64.tar.gz.aa" -o a.aa
curl -fL "$B/ohos-sdk-linux-amd64.tar.gz.ab" -o a.ab
curl -fL "$B/ohos-sdk-linux-amd64.tar.gz.sha256" -o a.sha256
cat a.aa a.ab > ohos-sdk-linux-amd64.tar.gz
sha256sum -c a.sha256
tar -xzf ohos-sdk-linux-amd64.tar.gz
ls command-line-tools
```

> `gh-proxy.com` 是镜像；统信能直连 GitHub 的话把 `$B` 换成 `https://github.com/...` 原始地址也行。

## 2. 配置环境

```bash
export PATH="$HOME/ohos/command-line-tools/bin:$HOME/ohos/command-line-tools/tool/node/bin:$PATH"
export DEVECO_SDK_HOME="$HOME/ohos/command-line-tools/sdk"
hvigorw --version
```

## 3. 拉工程

```bash
cd ~ && git clone https://github.com/xinlei199/portwatch-card.git
cd portwatch-card/harmony-src
```

（raw 直连不稳的话：`git clone https://gh-proxy.com/https://github.com/xinlei199/portwatch-card.git`）

## 4. 编译

```bash
hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon
```

产物：

```
entry/build/default/outputs/default/entry-default-unsigned.hap
```

## 5. 安装到手机

手机开「开发者模式」+「USB 调试」，连上电脑：

```bash
hdc list targets
hdc install entry/build/default/outputs/default/entry-default-unsigned.hap
```

无线调试（手机和电脑同一 WiFi）：手机「无线调试」里看 IP:端口，然后 `hdc tconn IP:端口`。

## 排错

| 报错 | 处理 |
|---|---|
| `hvigor-config.json5` 版本不匹配 | 看 `hvigorw --version`，把 `hvigor/hvigor-config.json5` 的 `hvigorVersion` 改成同版本 |
| 找不到 node | 确认 PATH 里有 `command-line-tools/tool/node/bin` |
| `no signature file`（9568320） | unsigned 被拒 → 转 Windows DevEco 自动签名 |
| `hdc list targets` 为空 | 换数据线/换 USB 口，手机弹窗点「允许调试」 |

## 偷懒方案

如果你连这一步都不想跑：仓库的 **Actions → build-hap** 会在这个 Linux 环境里自动编译，跑完在页面底部下载 `portwatch-hap` 产物，拿到 `entry-default-unsigned.hap` 后只需一步：

```bash
hdc install entry-default-unsigned.hap
```
