#!/bin/bash

set -e  # 启用错误处理

#################### 脚本初始化任务 ####################

# 获取脚本工作目录绝对路径
export Server_Dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

# 加载.env变量文件
source $Server_Dir/env

# 给二进制启动程序、脚本等添加可执行权限
chmod +x $Server_Dir/sub/subconverter

# 判断系统类型
if [[ -f "/etc/os-release" ]]; then
    . /etc/os-release
    case "$ID" in
        "freebsd"|"openbsd")
            export isBSD=true
        ;;
        *)
            export isBSD=false
        ;;
    esac
fi

#################### 变量设置 ####################

Conf_Dir="$Server_Dir/conf"
Temp_Dir="$Server_Dir/temp"
Log_Dir="$Server_Dir/logs"
Clash_Dir="/usr/local/etc/clash/"

# 将 CLASH_URL 变量的值赋给 URL 变量，并检查 CLASH_URL 是否为空
URL=${CLASH_URL:?Error: CLASH订阅地址无效或为空}

# 获取 CLASH_SECRET 值，如果不存在则生成一个随机数
Secret=${CLASH_SECRET:-$(openssl rand -hex 32)}

#################### 函数定义 ####################

# 自定义action函数，实现通用action功能
success() {
    echo -en "  OK  \r"
    return 0
}

failure() {
    local rc=$?
    echo -en "FAILED\r"
    [ -x /bin/plymouth ] && /bin/plymouth --details
    return $rc
}

action() {
    local STRING rc
    STRING=$1
    echo -n "$STRING "
    shift
    "$@" && success $"$STRING" || failure $"$STRING"
    rc=$?
    echo
    return $rc
}

# 判断命令是否正常执行 函数
if_success() {
    local ReturnStatus=$3
    if [ $ReturnStatus -eq 0 ]; then
        action "$1" /usr/bin/true
    else
        action "$2" /usr/bin/false
        exit 1
    fi
}

#################### 任务执行 ####################

## Clash 订阅地址检测及配置文件下载
# 检查url是否有效
echo -e '\n正在检测订阅地址...'
Text1="Clash订阅地址可访问！"
Text2="Clash订阅地址不可访问！"
curl -o /dev/null -L -k -sS --retry 5 -m 10 --connect-timeout 10 -w "%{http_code}" $URL | grep -E '^[23][0-9]{2}$' &>/dev/null
ReturnStatus=$?
if_success $Text1 $Text2 $ReturnStatus

# 拉取更新config.yml文件
echo -e '\n正在下载Clash配置文件...'
Text3="配置文件config.yaml下载成功！"
Text4="配置文件config.yaml下载失败，退出启动！"
curl -L -k -sS --retry 5 -m 10 -o $Temp_Dir/clash.yaml $URL
ReturnStatus=$?
if [ $ReturnStatus -ne 0 ]; then
    # 如果使用curl下载失败，尝试使用wget进行下载
    for i in {1..10}; do
        wget -q --no-check-certificate -O $Temp_Dir/clash.yaml $URL
        ReturnStatus=$?
        if [ $ReturnStatus -eq 0 ]; then
            break
        else
            continue
        fi
    done
fi
if_success $Text3 $Text4 $ReturnStatus

# 重命名clash配置文件
\cp -a $Temp_Dir/clash.yaml $Temp_Dir/clash_config.yaml

## 判断订阅内容是否符合clash配置文件标准，并尝试进行转换
echo -e '\n判断订阅内容是否符合clash配置文件标准:'
raw_content=$(cat ${Server_Dir}/temp/clash.yaml)

# 判断订阅内容是否符合clash配置文件标准
    echo "$raw_content" > /tmp/raw_content.txt
    if awk '/^proxies:/{p=1} /^proxy-groups:/{g=1} /^rules:/{r=1} p&&g&&r{exit} END{if(p&&g&&r) exit 0; else exit 1}' /tmp/raw_content.txt; then
    echo -e "订阅内容符合clash标准！"
    echo "$raw_content" > ${Server_Dir}/temp/clash_config.yaml
else
    # 判断订阅内容是否为base64编码
    if echo "$raw_content" | base64 -d &>/dev/null; then
        # 订阅内容为base64编码，进行解码
        decoded_content=$(echo "$raw_content" | base64 -d)

        # 判断解码后的内容是否符合clash配置文件标准
            echo "$decoded_content" > /tmp/decoded_content.txt
         if awk '/^proxies:/{p=1} /^proxy-groups:/{g=1} /^rules:/{r=1} p&&g&&r{exit} END{if(p&&g&&r) exit 0; else exit 1}' /tmp/decoded_content.txt; then
            echo "解码后的内容符合clash标准"
            echo "$decoded_content" > ${Server_Dir}/temp/clash_config.yaml
        else
            echo "解码后的内容不符合clash标准，尝试将其转换为标准格式"
            ${Server_Dir}/sub/subconverter -g &>> ${Server_Dir}/logs/sub.log
            converted_file=${Server_Dir}/temp/clash_config.yaml
            if awk '/^proxies:/{p=1} /^proxy-groups:/{g=1} /^rules:/{r=1} p&&g&&r{exit} END{if(p&&g&&r) exit 0; else exit 1}' $converted_file; then
                echo "配置文件已成功转换成clash标准格式"
            else
                echo -e "配置文件转换标准格式失败！"
                exit 1
            fi
        fi
    else
        echo -e "订阅内容不符合clash标准，无法转换为配置文件！"
        exit 1
    fi
fi

## Clash 配置文件重新格式化及配置
sed -n '/^proxies:/,$p' $Temp_Dir/clash_config.yaml > $Temp_Dir/proxy.txt
sed -i '' '/socks-port: 7891/d' $Temp_Dir/proxy.txt
cat $Temp_Dir/templete_config.yaml > $Temp_Dir/config.yaml
cat $Temp_Dir/proxy.txt >> $Temp_Dir/config.yaml
\cp $Temp_Dir/config.yaml $Conf_Dir/

# 配置Clash面板
Work_Dir=$(cd $(dirname $0); pwd)
Dashboard_Dir="${Work_Dir}/ui"
if [[ $isBSD == false ]]; then
    sed -ri "s@^# external-ui:.*@external-ui: ${Dashboard_Dir}@g" $Conf_Dir/config.yaml
    sed -r -i '/^secret: /s@(secret: ).*@\1'${Secret}'@g' $Conf_Dir/config.yaml
else
    sed -i "" -e "s@^# external-ui:.*@external-ui: ${Dashboard_Dir}@g" "$Conf_Dir/config.yaml"
    sed -E -i "" -e '/^secret: /s@(secret: ).*@\1'"${Secret}"'@g' "$Conf_Dir/config.yaml"
fi

## 订阅完成
echo -e '订阅完成！'

# 显示clash面板访问地址
echo ''
echo -e "Clash面板访问地址: http://<LAN IP>:9090/ui"
echo -e "Secret: ${Secret}"
echo ''

## 复制配置
\cp $Conf_Dir/config.yaml $Clash_Dir/
echo -e '复制配置完成！'

## 重启服务
echo -e '重启clash...'
service clash restart
echo -e 'clash服务重启完成！'
echo ''
