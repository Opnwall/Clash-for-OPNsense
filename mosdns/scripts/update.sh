#!/bin/sh

echo -e ''
echo -e "\033[32m==================代理程序和GEO数据更新脚本=============\033[0m"
echo -e ''

set -e

# 颜色定义
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# 打印日志
log() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${RESET}"
}

exit_with_error() {
    log "$RED" "$1"
    exit 1
}

# 变量定义
PROXY="socks5://127.0.0.1:7891"
WORKDIR="/tmp/opnsense_update"
UI_DIR="/usr/local/etc/clash/ui"
BIN_DIR="/usr/local/bin"
IPS="/usr/local/etc/mosdns/ips"
DOMAINS="/usr/local/etc/mosdns/domains"

mkdir -p "$WORKDIR" "$UI_DIR"
cd "$WORKDIR" || exit_with_error "无法进入工作目录 $WORKDIR"

# 获取最新版本
get_latest_version() {
    repo_api_url="$1"
    curl -s --proxy "$PROXY" "$repo_api_url" | awk -F '"' '/tag_name/ {print $4; exit}' | sed 's/^v//'
}

# 统一下载 + 检查函数
download() {
    local url="$1"
    local output="$2"
    curl -L --proxy "$PROXY" -o "$output" "$url" || exit_with_error "下载失败：$url"
}

echo -e ''
log "$GREEN" "使用SOCKS5代理进行更新，代理地址: $PROXY"
echo -e ''

# ========== 1. 更新 GEO 数据 ==========
log "$YELLOW" "正在更新GEO数据..."

download "https://ispip.clang.cn/all_cn.txt" "$WORKDIR/all_cn.txt"
download "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/direct-list.txt" "$WORKDIR/direct-list.txt"
download "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/proxy-list.txt" "$WORKDIR/proxy-list.txt"
download "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/gfw.txt" "$WORKDIR/gfw.txt"

cp -f "$WORKDIR/all_cn.txt" "$IPS/" || log "$RED" "复制 all_cn.txt 失败！"
cp -f "$WORKDIR/direct-list.txt" "$DOMAINS/"
cp -f "$WORKDIR/proxy-list.txt" "$DOMAINS/"
cp -f "$WORKDIR/gfw.txt" "$DOMAINS/"

log "$GREEN" "GEO数据更新完成"
echo -e ''

# ========== 2. 更新 metacubexd ==========
log "$YELLOW" "正在更新MetaCubeXD..."

version=$(get_latest_version "https://api.github.com/repos/MetaCubeX/metacubexd/releases/latest")
[ -z "$version" ] && exit_with_error "无法获取 MetaCubeXD 版本"
log "$GREEN" "最新版本：v$version"

download "https://github.com/MetaCubeX/metacubexd/releases/download/v${version}/compressed-dist.tgz" "metacubexd.tgz"

METACUBEXD_TMP="$WORKDIR/metacubexd_tmp"
mkdir -p "$METACUBEXD_TMP"
tar -xzf metacubexd.tgz -C "$METACUBEXD_TMP"

rm -rf "${UI_DIR:?}/"*
cp -rf "$METACUBEXD_TMP"/* "$UI_DIR/"

log "$GREEN" "MetaCubeXD已更新"
echo -e ''

# ========== 3. 更新 mosdns ==========
log "$YELLOW" "正在更新mosdns..."

version=$(get_latest_version "https://api.github.com/repos/IrineSistiana/mosdns/releases/latest")
[ -z "$version" ] && exit_with_error "无法获取 mosdns 版本"
log "$GREEN" "最新版本：v$version"

download "https://github.com/IrineSistiana/mosdns/releases/download/v${version}/mosdns-freebsd-amd64.zip" "mosdns.zip"
unzip -o "mosdns.zip" -d "$WORKDIR/mosdns_extracted"
mv -f "$WORKDIR/mosdns_extracted/mosdns" "$BIN_DIR/mosdns"
chmod +x "$BIN_DIR/mosdns"
log "$GREEN" "mosdns已更新"
echo -e ''

# ========== 4. 更新 hev-socks5-tunnel ==========
log "$YELLOW" "正在更新 hev-socks5-tunnel..."

version=$(get_latest_version "https://api.github.com/repos/heiher/hev-socks5-tunnel/releases/latest")
[ -z "$version" ] && exit_with_error "无法获取 hev-socks5-tunnel 版本"
log "$GREEN" "最新版本：$version"

download "https://github.com/heiher/hev-socks5-tunnel/releases/download/${version}/hev-socks5-tunnel-freebsd-x86_64" "tun2socks"
chmod +x tun2socks
mv -f tun2socks "$BIN_DIR/tun2socks"
log "$GREEN" "hev-socks5-tunnel已更新"
echo -e ''

# ========== 5. 更新 Mihomo ==========
log "$YELLOW" "正在更新 Mihomo..."

version=$(get_latest_version "https://api.github.com/repos/MetaCubeX/mihomo/releases/latest")
[ -z "$version" ] && exit_with_error "无法获取 Mihomo 版本"
log "$GREEN" "最新版本：v$version"

filename="mihomo-freebsd-amd64-compatible-v${version}.gz"
download "https://github.com/MetaCubeX/mihomo/releases/download/v${version}/${filename}" "$filename"
gunzip -f "$filename"
mv -f "mihomo-freebsd-amd64-compatible-v${version}" "$BIN_DIR/clash"
chmod +x "$BIN_DIR/clash"
log "$GREEN" "Mihomo已更新"
echo -e ''

# 清理
rm -rf "$WORKDIR"

log "$YELLOW" "重启代理服务！"
service tun2socks restart || log "$RED" "tun2socks 重启失败"
service mosdns restart || log "$RED" "mosdns 重启失败"
service clash restart || log "$RED" "clash 重启失败"
echo -e ''

log "$GREEN" "所有组件已更新完毕！"
echo -e ''
