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

PROXY="socks5h://127.0.0.1:7891"
WORKDIR="/tmp/opnsense_update"
UI_DIR="/usr/local/etc/clash/ui"
BIN_DIR="/usr/local/bin"
IPS="/usr/local/etc/mosdns/ips"
DOMAINS="/usr/local/etc/mosdns/domains"

mkdir -p "$WORKDIR" "$UI_DIR"
cd "$WORKDIR" || exit_with_error "无法进入工作目录 $WORKDIR"



download() {
    local url="$1"
    local output="$2"
    local retries=3
    local count=0
    while [ $count -lt $retries ]; do
        curl -L --socks5-hostname 127.0.0.1:7891 --connect-timeout 10 --max-time 60 -A "Mozilla/5.0 (compatible; UpdateScript/1.0)" -o "$output" "$url" && break
        count=$((count + 1))
        log "$YELLOW" "下载失败，重试 $count/$retries: $url"
        sleep 2
    done
    if [ ! -s "$output" ]; then
        exit_with_error "下载失败或文件为空：$url"
    fi
}

get_current_version_mosdns() {
    [ -x "$BIN_DIR/mosdns" ] && "$BIN_DIR/mosdns" -version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo ""
}

get_current_version_mihomo() {
    [ -x "$BIN_DIR/clash" ] && "$BIN_DIR/clash" -v 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo ""
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

version=$(curl -s --proxy "$PROXY" https://api.github.com/repos/Vincent-Loeng/mihomo/releases/latest | awk -F '"' '/tag_name/ {print $4; exit}')
current=$(get_current_version_mihomo)
if [ "$version" = "$current" ]; then
    log "$YELLOW" "Mihomo 已是最新版本（$version），跳过更新"
else
    log "$YELLOW" "正在更新 Mihomo（当前版本：$current -> $version）"
    filename="mihomo-freebsd-amd64"
    download "https://github.com/Vincent-Loeng/mihomo/releases/download/${version}/${filename}" "$filename"
    mv -f "mihomo-freebsd-amd64" "$BIN_DIR/clash"
    chmod +x "$BIN_DIR/clash"
    if ! "$BIN_DIR/clash" -v >/dev/null 2>&1; then
        exit_with_error "Mihomo 执行校验失败，更新终止"
    fi
    log "$GREEN" "Mihomo 已更新"
fi
echo ""

rm -rf "$WORKDIR"

log "$YELLOW" "重启代理服务..."
[ -x "$BIN_DIR/clash" ] && service clash restart || log "$RED" "clash 重启失败"
log "$GREEN" "所有组件已更新完成"
echo ""
