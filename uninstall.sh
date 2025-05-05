#!/bin/bash

echo -e ''
echo -e "\033[32m========Clash for OPNsense 代理全家桶一键卸载脚本=========\033[0m"
echo -e ''

# 定义颜色变量
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# 定义日志函数
log() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${RESET}"
}

# 删除程序和配置
log "$YELLOW" "删除代理程序和配置，请稍等..."
# 删除配置
rm -rf /usr/local/etc/clash
rm -rf /usr/local/etc/mosdns
rm -rf /usr/local/etc/tun2socks

# 删除rc.d
rm -f /usr/local/etc/rc.d/clash
rm -f /usr/local/etc/rc.d/tun2socks
rm -f /usr/local/etc/rc.d/mosdns

# 删除rc.conf
rm -f /etc/rc.conf.d/tun2socks
rm -f /etc/rc.conf.d/clash
rm -f /etc/rc.conf.d/mosdns

# 删除action
rm -f /usr/local/opnsense/service/conf/actions.d/actions_clash.conf
rm -f /usr/local/opnsense/service/conf/actions.d/actions_tun2socks.conf
rm -f /usr/local/opnsense/service/conf/actions.d/actions_mosdns.conf

# 删除菜单和缓存
rm -rf /usr/local/opnsense/mvc/app/models/OPNsense/Magic
rm -f /tmp/opnsense_menu_cache.xml
rm -f /tmp/opnsense_acl_cache.json

# 删除inc
rm -f /usr/local/etc/inc/plugins.inc.d/clash.inc
rm -f /usr/local/etc/inc/plugins.inc.d/mosdns.inc
rm -f /usr/local/etc/inc/plugins.inc.d/tun2socks.inc

# 删除php
rm -f /usr/local/www/services_clash.php
rm -f /usr/local/www/services_mosdns.php
rm -f /usr/local/www/services_tun2socks.php
rm -f /usr/local/www/status_clash_logs.php
rm -f /usr/local/www/status_clash.php
rm -f /usr/local/www/status_mosdns_logs.php
rm -f /usr/local/www/status_mosdns.php
rm -f /usr/local/www/status_tun2socks_logs.php
rm -f /usr/local/www/status_tun2socks.php
rm -f /usr/local/www/sub.php

# 删除程序
rm -f /usr/local/bin/clash
rm -f /usr/local/bin/tun2socks
rm -f /usr/local/bin/mosdns
echo ""

# 重启所有服务
log "$YELLOW" "重新应用所有更改，请稍等..."
/usr/local/etc/rc.reload_all >/dev/null 2>&1
service configd restart > /dev/null 2>&1
echo ""

# 完成提示
log "$GREEN" "卸载完成，请手动删除TUN接口、别名和浮动防火墙分流规则，并将Unbound DNS端口更改为53。"
echo ""