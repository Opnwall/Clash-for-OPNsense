#!/bin/sh

set -e  # 遇到错误即退出

#################### 初始化任务 ####################

# 获取脚本工作目录路径
Server_Dir=$(cd "$(dirname "$0")" && pwd)

# 加载环境变量
if [ -f "$Server_Dir/env" ]; then
    . "$Server_Dir/env"
fi

# 赋予必要权限
chmod +x "$Server_Dir/sub/subconverter"

#################### 变量设置 ####################

Conf_Dir="$Server_Dir/conf"
Temp_Dir="$Server_Dir/temp"
Log_Dir="$Server_Dir/logs"
Clash_Dir="/usr/local/etc/clash/"

# 获取Clash订阅地址
if [ -z "$CLASH_URL" ]; then
    echo "错误: CLASH订阅地址为空！"
    exit 1
fi
URL="$CLASH_URL"

# 生成Secret如果未定义）
Secret=${CLASH_SECRET:-$(openssl rand -hex 32)}

#################### 任务执行 ####################

echo "检测订阅地址..."
if curl -o /dev/null -L -k -sS --retry 5 -m 10 --connect-timeout 10 -w "%{http_code}" "$URL" | grep -E '^[23][0-9]{2}$' >/dev/null; then
    echo "Clash订阅地址可以访问！"
else
    echo "Clash订阅地址不可访问！"
    exit 1
fi
echo ""

# 下载配置文件
echo "正在下载Clash配置文件..."
if ! curl -L -k -sS --retry 5 -m 10 -o "$Temp_Dir/clash.yaml" "$URL"; then
    echo "curl 下载失败，尝试 wget..."
    if ! wget -q --no-check-certificate -O "$Temp_Dir/clash.yaml" "$URL"; then
        echo "配置文件下载失败，退出！"
        exit 1
    fi
fi
echo "文件下载成功！"
echo ""

# 复制配置文件
cp -a "$Temp_Dir/clash.yaml" "$Temp_Dir/clash_config.yaml"

# 判断订阅是否为Clash标准格式
raw_content=$(cat "$Temp_Dir/clash_config.yaml")
echo "$raw_content" > /tmp/raw_content.txt
if awk '/^proxies:/{p=1} /^proxy-groups:/{g=1} /^rules:/{r=1} p&&g&&r{exit} END{if(p&&g&&r) exit 0; else exit 1}' /tmp/raw_content.txt; then
    echo "订阅内容符合Clash标准格式！"
else
    echo "检测到非标准Clash配置，尝试解码..."
    if echo "$raw_content" | base64 -d 2>/dev/null > /tmp/decoded_content.txt; then
        decoded_content=$(cat /tmp/decoded_content.txt)
        if awk '/^proxies:/{p=1} /^proxy-groups:/{g=1} /^rules:/{r=1} p&&g&&r{exit} END{if(p&&g&&r) exit 0; else exit 1}' /tmp/decoded_content.txt; then
            echo "解码后的内容符合Clash标准格式！"
            echo "$decoded_content" > "$Temp_Dir/clash_config.yaml"
        else
            echo "解码失败，尝试转换..."
            "$Server_Dir/sub/subconverter" -g &>> "$Log_Dir/sub.log"
            if ! awk '/^proxies:/{p=1} /^proxy-groups:/{g=1} /^rules:/{r=1} p&&g&&r{exit} END{if(p&&g&&r) exit 0; else exit 1}' "$Temp_Dir/clash_config.yaml"; then
                echo "转换失败！无法生成Clash配置文件！"
                exit 1
            fi
        fi
    else
        echo "订阅内容不符合Clash标准，且无法解码！"
        exit 1
    fi
fi

# 生成最终Clash配置文件
sed -n '/^proxies:/,$p' "$Temp_Dir/clash_config.yaml" > "$Temp_Dir/proxy.txt"
sed -i '' '/socks-port: 7891/d' "$Temp_Dir/proxy.txt"
cat "$Temp_Dir/templete_config.yaml" > "$Temp_Dir/config.yaml"
cat "$Temp_Dir/proxy.txt" >> "$Temp_Dir/config.yaml"
cp "$Temp_Dir/config.yaml" "$Conf_Dir/"

# 配置Clash面板
Dashboard_Dir="${Server_Dir}/ui"
sed -i "" -e "s@^# external-ui:.*@external-ui: ${Dashboard_Dir}@g" "$Conf_Dir/config.yaml"
sed -E -i "" -e "/^secret: /s@(secret: ).*@\1${Secret}@g" "$Conf_Dir/config.yaml"

echo "订阅完成！"
echo ""

# 替换配置
cp "$Conf_Dir/config.yaml" "$Clash_Dir/"
echo "替换运行配置文件..."


# 重启Clash服务
echo "重启Clash服务..."
service clash restart
echo "Clash服务重启完成！"
echo ""

echo "Clash仪表盘访问地址: http://<LAN IP>:9090/ui"
echo "访问密钥: ${Secret}"
echo ""