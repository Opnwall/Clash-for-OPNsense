#!/bin/sh
# 在线订阅转换脚本

#################### 初始化 ####################
Server_Dir=$(cd "$(dirname "$0")" && pwd)
[ -f "$Server_Dir/env" ] && . "$Server_Dir/env"

API_BASE="https://subconverters.com/sub"

Conf_Dir="$Server_Dir/conf"
Temp_Dir="$Server_Dir/temp"
Clash_Dir="/usr/local/etc/clash"
Dashboard_Dir="${Server_Dir}/ui"
mkdir -p "$Conf_Dir" "$Temp_Dir"

TMP_RAW=$(mktemp "$Temp_Dir/clash_config.yaml")
TMP_PROXIES=$(mktemp "$Temp_Dir/proxies.txt")
TMP_FINAL=$(mktemp "$Temp_Dir/config.yaml")
TEMPLATE_FILE="$Temp_Dir/templete_config.yaml"

# Clash订阅地址校验
[ -z "$CLASH_URL" ] && {
    echo "错误：未设置 CLASH_URL 环境变量"
    exit 1
}

# Secret
Secret=${CLASH_SECRET:-$(openssl rand -hex 32)}

#################### 下载配置 ####################
ENCODED_URL=$(printf "%s" "$CLASH_URL" | jq -s -R -r @uri)
API_URL="${API_BASE}?target=clash&url=${ENCODED_URL}&udp=true&clash.dns=true&list=false"
echo ""
echo "下载配置..."
echo ""

if curl -L -k -sS --retry 3 -m 15 -o "$TMP_RAW" "$API_URL"; then
    echo "下载成功：$TMP_RAW"
else
    echo "下载失败！"
    exit 1
fi
echo ""

#################### 合成配置 ####################
[ ! -f "$TEMPLATE_FILE" ] && {
    echo "缺少模板文件：$TEMPLATE_FILE"
    exit 1
}

# 提取代理部分
sed -n '/^proxies:/,$p' "$TMP_RAW" > "$TMP_PROXIES"

# 合成配置
echo "合成配置..."
sleep 1
cat "$TEMPLATE_FILE" > "$TMP_FINAL"
cat "$TMP_PROXIES" >> "$TMP_FINAL"
cp "$TMP_FINAL" "$Conf_Dir/config.yaml"

# 替换 dashboard 路径与 secret
sed -i '' "s@^# external-ui:.*@external-ui: ${Dashboard_Dir}@" "$Conf_Dir/config.yaml"
sed -i '' -E "s@^secret:.*@secret: ${Secret}@" "$Conf_Dir/config.yaml"
echo "合成完成!"
echo ""

#################### 应用配置并重启 ####################
echo "替换配置..."
sleep 1
cp "$Conf_Dir/config.yaml" "$Clash_Dir/config.yaml"
echo "重启服务..."
service clash restart >/dev/null 2>&1
sleep 1
echo "重启完成！"
echo ""
#################### 输出仪表盘信息 ####################
sleep 1
LAN_IP=$(ifconfig | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}')
echo "仪表盘访问地址: http://${LAN_IP}:9090/ui"
echo "仪表盘访问密钥: ${Secret}"
echo ""

#################### 清理临时文件 ####################
rm -f "$TMP_RAW" "$TMP_PROXIES" "$TMP_FINAL"
