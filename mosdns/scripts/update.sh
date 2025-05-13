#!/bin/sh

echo ""
echo -e "\033[32m==================代理程序和GeoIP数据更新脚本=============\033[0m"
echo ""

set -e

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

log() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${RESET}"
}

exit_with_error() {
    log "$RED" "$1"
    exit 1
}

PROXY="socks5://127.0.0.1:7891"
WORKDIR="/tmp/opnsense_update"
UI_DIR="/usr/local/etc/clash/ui"
BIN_DIR="/usr/local/bin"
IPS="/usr/local/etc/mosdns/ips"
DOMAINS="/usr/local/etc/mosdns/domains"

mkdir -p "$WORKDIR" "$UI_DIR"
cd "$WORKDIR" || exit_with_error "无法进入工作目录 $WORKDIR"

get_latest_version() {
    curl -s --proxy "$PROXY" "$1" | awk -F '"' '/tag_name/ {print $4; exit}' | sed 's/^v//'
}

download() {
    local url="$1"
    local output="$2"
    curl -L --proxy "$PROXY" -o "$output" "$url" || exit_with_error "下载失败：$url"
}

get_current_version_mosdns() {
    [ -x "$BIN_DIR/mosdns" ] && "$BIN_DIR/mosdns" -version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo ""
}

get_current_version_mihomo() {
    [ -x "$BIN_DIR/clash" ] && "$BIN_DIR/clash" -v 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo ""
}

get_current_version_tun2socks() {
    [ -x "$BIN_DIR/tun2socks" ] && "$BIN_DIR/tun2socks" -v 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo ""
}

log "$YELLOW" "正在更新 GeoIP 数据..."
download "https://ispip.clang.cn/all_cn.txt" "$WORKDIR/all_cn.txt"
download "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/direct-list.txt" "$WORKDIR/direct-list.txt"
download "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/proxy-list.txt" "$WORKDIR/proxy-list.txt"
download "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/gfw.txt" "$WORKDIR/gfw.txt"

cp -f "$WORKDIR/all_cn.txt" "$IPS/" || log "$RED" "复制 all_cn.txt 失败！"
cp -f "$WORKDIR/direct-list.txt" "$DOMAINS/"
cp -f "$WORKDIR/proxy-list.txt" "$DOMAINS/"
cp -f "$WORKDIR/gfw.txt" "$DOMAINS/"

log "$GREEN" "GeoIP 已更新"
echo ""

log "$YELLOW" "正在更新 MetaCubeXD..."
version=$(get_latest_version "https://api.github.com/repos/MetaCubeX/metacubexd/releases/latest")
[ -z "$version" ] && exit_with_error "无法获取 MetaCubeXD 版本"
log "$GREEN" "最新版本：v$version"

download "https://github.com/MetaCubeX/metacubexd/releases/download/v${version}/compressed-dist.tgz" "metacubexd.tgz"
METACUBEXD_TMP="$WORKDIR/metacubexd_tmp"
mkdir -p "$METACUBEXD_TMP"
tar -xzf metacubexd.tgz -C "$METACUBEXD_TMP"
rm -rf "${UI_DIR:?}/"*
cp -rf "$METACUBEXD_TMP"/* "$UI_DIR/"
log "$GREEN" "MetaCubeXD 已更新"
echo ""

version=$(get_latest_version "https://api.github.com/repos/IrineSistiana/mosdns/releases/latest")
current=$(get_current_version_mosdns)
if [ "$version" = "$current" ]; then
    log "$YELLOW" "mosdns 已是最新版本（v$version），跳过更新"
else
    log "$YELLOW" "正在更新 mosdns（当前版本：$current -> v$version）"
    download "https://github.com/IrineSistiana/mosdns/releases/download/v${version}/mosdns-freebsd-amd64.zip" "mosdns.zip"
    unzip -o "mosdns.zip" -d "$WORKDIR/mosdns_extracted"
    mv -f "$WORKDIR/mosdns_extracted/mosdns" "$BIN_DIR/mosdns"
    chmod +x "$BIN_DIR/mosdns"
    log "$GREEN" "mosdns 已更新"
fi
echo ""

version=$(get_latest_version "https://api.github.com/repos/heiher/hev-socks5-tunnel/releases/latest")
current=$(get_current_version_tun2socks)
if [ "$version" = "$current" ]; then
    log "$YELLOW" "hev-socks5-tunnel 已是最新版本（v$version），跳过更新"
else
    log "$YELLOW" "正在更新 hev-socks5-tunnel（当前版本：$current -> v$version）"
    download "https://github.com/heiher/hev-socks5-tunnel/releases/download/${version}/hev-socks5-tunnel-freebsd-x86_64" "tun2socks"
    chmod +x "tun2socks"
    mv -f "tun2socks" "$BIN_DIR/tun2socks"
    log "$GREEN" "hev-socks5-tunnel 已更新"
fi
echo ""

version=$(get_latest_version "https://api.github.com/repos/MetaCubeX/mihomo/releases/latest")
current=$(get_current_version_mihomo)
if [ "$version" = "$current" ]; then
    log "$YELLOW" "Mihomo 已是最新版本（v$version），跳过更新"
else
    log "$YELLOW" "正在更新 Mihomo（当前版本：$current -> v$version）"
    filename="mihomo-freebsd-amd64-compatible-v${version}.gz"
    download "https://github.com/MetaCubeX/mihomo/releases/download/v${version}/${filename}" "$filename"
    gunzip -f "$filename"
    mv -f "mihomo-freebsd-amd64-compatible-v${version}" "$BIN_DIR/clash"
    chmod +x "$BIN_DIR/clash"
    log "$GREEN" "Mihomo 已更新"
fi
echo ""

rm -rf "$WORKDIR"

log "$YELLOW" "重启代理服务..."
[ -x "$BIN_DIR/tun2socks" ] && service tun2socks restart || log "$RED" "tun2socks 重启失败"
[ -x "$BIN_DIR/mosdns" ] && service mosdns restart || log "$RED" "mosdns 重启失败"
[ -x "$BIN_DIR/clash" ] && service clash restart || log "$RED" "clash 重启失败"
log "$GREEN" "所有组件已更新完成"
echo ""
