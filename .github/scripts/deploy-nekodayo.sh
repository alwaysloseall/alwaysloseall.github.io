#!/usr/bin/env bash
# 把本次生成的 public/ 同步到服务器 /var/www/blog。
# 私钥只来自环境变量 NEKODAYO_SSH_KEY（GitHub Actions secret），不要写进仓库。
set -euo pipefail

HOST="${NEKODAYO_HOST:-}"
SSH_USER="${NEKODAYO_USER:-}"
HOST="${HOST:-nekodayo.com}"
SSH_USER="${SSH_USER:-root}"
DEST="/var/www/blog"
KEY_FILE="${HOME}/.ssh/nekodayo_key"
# 单独的 known_hosts，避免盖掉运行环境里原有的 ~/.ssh/known_hosts。
KNOWN_HOSTS="${HOME}/.ssh/nekodayo_known_hosts"
RSYNC_SSH="${HOME}/.ssh/rsync-ssh"

cleanup() {
  rm -f "${KEY_FILE}" "${RSYNC_SSH}" "${KNOWN_HOSTS}"
}
trap cleanup EXIT

fail_missing_key() {
  echo "::error title=缺少 NEKODAYO_SSH_KEY::服务器部署需要 repository secret NEKODAYO_SSH_KEY。deploy-pages 不依赖它，GitHub Pages 可以已经发布成功。添加密钥后重跑本任务。详见 README「自动部署」。"
  cat <<EOF
未配置 Actions secret NEKODAYO_SSH_KEY，已停止同步 ${SSH_USER}@${HOST}:${DEST}。

仓库 Settings → Secrets and variables → Actions，添加：
  NEKODAYO_SSH_KEY       必填。登录 ${SSH_USER}@${HOST} 的私钥（OpenSSH，无口令）
  NEKODAYO_KNOWN_HOSTS   建议。ssh-keyscan 结果，用来固定主机密钥
  NEKODAYO_HOST          可选，默认 nekodayo.com
  NEKODAYO_USER          可选，默认 root

  gh secret set NEKODAYO_SSH_KEY < /path/to/deploy_key
  gh secret set NEKODAYO_KNOWN_HOSTS < <(ssh-keyscan -t ed25519,ecdsa,rsa ${HOST})

密钥写入仓库 secrets 后，在 Actions 里重跑失败的 deploy-nekodayo
（构建产物保留 14 天），或再推一次 hexo / 手动 Run workflow。
说明见 README「自动部署」。
EOF
  exit 1
}

key_trimmed=$(printf '%s' "${NEKODAYO_SSH_KEY:-}" | tr -d '[:space:]')
if [ -z "${key_trimmed}" ]; then
  fail_missing_key
fi
unset key_trimmed

if ! printf '%s' "${HOST}" | grep -Eq '^[A-Za-z0-9._-]+$'; then
  echo "::error title=NEKODAYO_HOST 无效::NEKODAYO_HOST 只能包含字母、数字、点、下划线和连字符。"
  exit 1
fi
if ! printf '%s' "${SSH_USER}" | grep -Eq '^[A-Za-z0-9._-]+$'; then
  echo "::error title=NEKODAYO_USER 无效::NEKODAYO_USER 只能包含字母、数字、点、下划线和连字符。"
  exit 1
fi

if [ ! -s public/index.html ]; then
  echo "::error title=缺少 public/index.html::构建产物里没有 public/index.html，已停止同步服务器。"
  exit 1
fi

umask 077
mkdir -p "${HOME}/.ssh"
printf '%s\n' "${NEKODAYO_SSH_KEY}" > "${KEY_FILE}"
chmod 600 "${KEY_FILE}"

if [ -n "${NEKODAYO_KNOWN_HOSTS:-}" ]; then
  printf '%s\n' "${NEKODAYO_KNOWN_HOSTS}" > "${KNOWN_HOSTS}"
  echo "使用 secret NEKODAYO_KNOWN_HOSTS 校验 ${HOST} 的主机密钥。"
else
  echo "::warning title=未设置 NEKODAYO_KNOWN_HOSTS::本次用 ssh-keyscan 获取 ${HOST} 的主机密钥（首次信任）。若这次连接被劫持，记下的可能是攻击者的密钥。请核对指纹后把 ssh-keyscan 结果写入 NEKODAYO_KNOWN_HOSTS。见 README。"
  ssh-keyscan -T 15 -t ed25519,ecdsa,rsa "${HOST}" > "${KNOWN_HOSTS}" || true
fi
chmod 644 "${KNOWN_HOSTS}"

if ! grep -Eq '^[^#[:space:]]' "${KNOWN_HOSTS}"; then
  echo "::error title=没有主机密钥::known_hosts 里没有 ${HOST} 的主机密钥，已停止连接。"
  exit 1
fi

cat > "${RSYNC_SSH}" <<EOF
#!/bin/sh
exec ssh -i "${KEY_FILE}" -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile="${KNOWN_HOSTS}" -o GlobalKnownHostsFile=/dev/null "\$@"
EOF
chmod 700 "${RSYNC_SSH}"

remote="${SSH_USER}@${HOST}"

set +e
"${RSYNC_SSH}" "${remote}" "command -v rsync >/dev/null 2>&1"
status=$?
set -e
if [ "${status}" -ne 0 ]; then
  if [ "${status}" -eq 255 ]; then
    echo "::error title=SSH 连接失败::无法以 ${remote} 登录。检查 NEKODAYO_SSH_KEY、服务器 authorized_keys 里的公钥，以及 NEKODAYO_KNOWN_HOSTS 是否对应该主机。"
  else
    echo "::error title=服务器没有 rsync::${remote} 上没有 rsync（远程命令退出码 ${status}）。请先安装 rsync，再重跑 deploy-nekodayo。"
  fi
  exit 1
fi

"${RSYNC_SSH}" "${remote}" "mkdir -p ${DEST}"

# /var/www/blog 与本次 public/ 对齐。该目录里多出来的文件会被删掉。
# hexo 分支上的文章原文不在这台服务器的同步范围内。
rsync -az --delete --chmod=D755,F644 \
  -e "${RSYNC_SSH}" \
  public/ "${remote}:${DEST}/"

"${RSYNC_SSH}" "${remote}" "test -s ${DEST}/index.html"
echo "已将 public/ 同步到 ${remote}:${DEST}/"
