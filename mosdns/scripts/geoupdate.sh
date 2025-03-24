#!/bin/sh

# 定义颜色变量
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
RESET="\033[0m"

# 定义日志函数
log() {
    local color="$1"
    local message="$2"
    printf "%b%s%b\n" "$color" "$message" "$RESET"
}

log "$GREEN" "运行 GEO 数据更新程序..."

# 设置下载 URL
CN_IP="https://ispip.clang.cn/all_cn.txt"
DIRECT_URL="https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/direct-list.txt"
GFW_URL="https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/proxy-list.txt"
PROXY_URL="https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/gfw.txt"

# 设置存放路径
TMP="/tmp/mosdns_up"
IPS="/usr/local/etc/mosdns/ips"
DOMAINS="/usr/local/etc/mosdns/domains"

# 创建临时目录和目标目录
mkdir -p "$TMP"

log "$YELLOW" "下载文件..."
# 下载文件（带错误检查）
fetch -o "$TMP/all_cn.txt" "$CN_IP" || { log "$RED" "下载 all_cn.txt 失败"; exit 1; }
fetch -o "$TMP/direct-list.txt" "$DIRECT_URL" || { log "$RED" "下载 direct-list.txt 失败"; exit 1; }
fetch -o "$TMP/proxy-list.txt" "$GFW_URL" || { log "$RED" "下载 proxy-list.txt 失败"; exit 1; }
fetch -o "$TMP/gfw.txt" "$PROXY_URL" || { log "$RED" "下载 gfw.txt 失败"; exit 1; }


log "$YELLOW" "复制文件..."
# 复制文件
cp -f "$TMP/all_cn.txt" "$IPS/" || log "$RED" "复制 all_cn.txt 失败！"
cp -f "$TMP/direct-list.txt" "$DOMAINS/" || log "$RED" "复制 direct-list.txt 失败！"
cp -f "$TMP/proxy-list.txt" "$DOMAINS/" || log "$RED" "复制 proxy-list.txt 失败！"
cp -f "$TMP/gfw.txt" "$DOMAINS/" || log "$RED" "复制 gfw.txt 失败！"

log "$YELLOW" "清理临时文件..."
rm -rf "$TMP"

log "$GREEN" "GEO 数据更新完成！"
log "$GREEN" "重启mosdns服务！"
service mosdns restart