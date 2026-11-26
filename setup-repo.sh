#!/usr/bin/env bash
# 用 GitHub token 创建 public 仓库并推送中继代码，然后触发一次 Actions。
# 用法: GH_TOKEN=ghp_xxx REPO=portwatch-card bash setup-repo.sh
set -euo pipefail

: "${GH_TOKEN:?需要 GH_TOKEN（classic token，勾 repo + workflow）}"
REPO="${REPO:-portwatch-card}"
API="https://api.github.com"
AUTH=(-H "Authorization: Bearer ${GH_TOKEN}" -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28")

# 1. 拿用户名
GH_USER=$(curl -sS "${AUTH[@]}" "$API/user" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).login))')
[ -n "$GH_USER" ] || { echo "token 无效"; exit 1; }
echo "账号: $GH_USER"

# 2. 创建仓库（已存在则跳过）
code=$(curl -sS -o /tmp/gh-create.json -w '%{http_code}' -X POST "${AUTH[@]}" \
  "$API/user/repos" -d "{\"name\":\"$REPO\",\"private\":false,\"auto_init\":false}")
if [ "$code" = "201" ]; then echo "仓库已创建: $GH_USER/$REPO"
elif [ "$code" = "422" ]; then echo "仓库已存在，继续"
else echo "创建失败 HTTP $code"; cat /tmp/gh-create.json; exit 1; fi

# 3. 推送（token 只出现在本次命令参数里，不写入 git config）
cd "$(dirname "$0")/.."
if [ ! -d .git ]; then
  git init -b main
  git config user.name "relay-bot"
  git config user.email "relay@users.noreply.github.com"
fi
git add -A
git diff --cached --quiet || git commit -m "init: portwatch card relay"
git push "https://x-access-token:${GH_TOKEN}@github.com/${GH_USER}/${REPO}.git" main

# 4. 触发 Actions（仓库创建后默认启用，workflow 文件在 main 上）
sleep 5
curl -sS -X POST "${AUTH[@]}" -H "Content-Type: application/json" \
  "$API/repos/${GH_USER}/${REPO}/actions/workflows/relay.yml/dispatches" \
  -d '{"ref":"main"}' && echo "已触发 relay workflow"

echo
echo "raw 地址: https://raw.githubusercontent.com/${GH_USER}/${REPO}/main/relay/card.json"
