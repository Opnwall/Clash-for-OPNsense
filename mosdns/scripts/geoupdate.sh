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
GEOIP_URL="https://github.com/techprober/v2ray-rules-dat/raw/release/geoip.zip"
GEOSITE_URL="https://github.com/techprober/v2ray-rules-dat/raw/release/geosite.zip"

# 设置存放路径
TMP="/tmp/mosdns_update"
GEOIP="/usr/local/etc/mosdns/ips"
GEOSITE="/usr/local/etc/mosdns/domains"

# 创建临时目录和目标目录
mkdir -p "$TMP" "$GEOIP" "$GEOSITE"

log "$YELLOW" "下载文件..."
# 下载文件（带错误检查）
fetch -o "$TMP/geoip.zip" "$GEOIP_URL" || { log "$RED" "下载 geoip.zip 失败"; exit 1; }
fetch -o "$TMP/geosite.zip" "$GEOSITE_URL" || { log "$RED" "下载 geosite.zip 失败"; exit 1; }

log "$YELLOW" "解压文件..."
# 解压文件（带错误检查）
unzip -o "$TMP/geoip.zip" -d "$TMP/geoip" || { log "$RED" "解压 geoip.zip 失败"; exit 1; }
unzip -o "$TMP/geosite.zip" -d "$TMP/geosite" || { log "$RED" "解压 geosite.zip 失败"; exit 1; }

log "$YELLOW" "复制文件..."
# 复制 geosite 相关文件
cp -f "$TMP/geosite/"*.txt "$GEOSITE/" || log "$RED" "复制 geosite 文件失败"

# 复制 geoip 相关文件
cp -f "$TMP/geoip/cn.txt" "$GEOIP/" || log "$RED" "复制 geoip 失败！"

log "$YELLOW" "清理临时文件..."
rm -f "$TMP/geoip.zip"
rm -f "$TMP/geosite.zip"
rm -rf "$TMP/geoip"
rm -rf "$TMP/geosite"

log "$GREEN" "GEO 数据更新完成！"

