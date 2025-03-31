#!/bin/bash

##############  代理安装脚本  #################
echo -e ''
echo -e "\033[32m============ OPNsense 代理全家桶一键安装脚本 ==============\033[0m"
echo -e ''

# 定义颜色变量
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
RESET="\033[0m"

# 定义目录变量
ROOT="/usr/local"
BIN_DIR="$ROOT/bin"
WWW_DIR="$ROOT/www"
CONF_DIR="$ROOT/etc"
MODELS_DIR="$ROOT/opnsense/mvc/app/models/OPNsense"
RC_DIR="$ROOT/etc/rc.d"
SYS_HOOK_START="$ROOT/etc/rc.syshook.d/start"
SYS_HOOK_EARLY="$ROOT/etc/rc.syshook.d/early"
PLUGINS="$ROOT/etc/inc/plugins.inc.d"
ACTIONS="$ROOT//opnsense/service/conf/actions.d"


# 定义日志函数
log() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${RESET}"
}

# 创建目录
log "$YELLOW" "创建目录..."
mkdir -p "$CONF_DIR/sing-box" "$CONF_DIR/clash" "$CONF_DIR/clash/sub" "$CONF_DIR/clash/ui" "$CONF_DIR/tun2socks" "$CONF_DIR/mosdns" || log "$RED" "目录创建失败！"

# 复制文件
log "$YELLOW" "复制文件..."
log "$YELLOW" "生成菜单..."
log "$YELLOW" "生成服务..."
log "$YELLOW" "添加权限..."
chmod +x bin/*
chmod +x rc.d/*
cp -f bin/* "$BIN_DIR/" || log "$RED" "bin 文件复制失败！"
cp -f www/* "$WWW_DIR/" || log "$RED" "www 文件复制失败！"
cp -R -f sub/* "$CONF_DIR/clash/sub/" || log "$RED" "sub 文件复制失败！"
cp -R -f ui/* "$CONF_DIR/clash/ui/" || log "$RED" "ui 文件复制失败！"
cp -R -f mosdns/* "$CONF_DIR/mosdns/" || log "$RED" "mosdns 文件复制失败！"
cp -f plugins/* "$PLUGINS/" || log "$RED" "plugins 文件复制失败！"
cp -f actions/* "$ACTIONS/" || log "$RED" "actions 文件复制失败！"
cp -R -f menu/* "$MODELS_DIR/" || log "$RED" "menu 文件复制失败！"
cp rc.d/* "$RC_DIR/" || log "$RED" "rc.d 文件复制失败！"
cp geo/* "$CONF_DIR/clash/" || log "$RED" "geo 文件复制失败！"
cp conf/config_clash.yaml "$CONF_DIR/clash/config.yaml" || log "$RED" "clash 配置文件复制失败！"
cp conf/config_sing-box.json "$CONF_DIR/sing-box/config.json" || log "$RED" "sing-box 配置文件复制失败！"
cp conf/config_tun2socks.yaml "$CONF_DIR/tun2socks/config.yaml" || log "$RED" "tun2socks 配置文件复制失败！"

# 新建订阅程序
log "$YELLOW" "添加订阅程序..."
cat>/usr/bin/sub<<EOF
# 启动clash订阅程序
bash /usr/local/etc/clash/sub/sub.sh
EOF
chmod +x /usr/bin/sub

# 安装bash
log "$GREEN" "安装 bash"
pkg install -y bash
log "$GREEN" "bash安装完成！"
echo ""

# 添加服务启动项
log "$YELLOW" "配置系统服务..."
sysrc singbox_enable="YES"
sysrc mosdns_enable="YES"
sysrc clash_enable="YES"
sysrc tun2socks_enable="YES"
echo ""
log "$GREEN" "注意：请备份/etc/rc.conf文件，以便在系统升级或重置后恢复插件功能。"
echo ""

# 显示运行命令
log "$YELLOW" "服务运行命令..."
for service in singbox clash mosdns tun2socks; do
    log "$CYAN" "启动:   service $service start"
    log "$CYAN" "停止:   service $service stop"
    log "$CYAN" "重启:   service $service restart"
	log "$CYAN" "状态:   service $service status"
    echo ""
done

# 删除菜单缓存
rm -f /tmp/opnsense_menu_cache.xml
rm -f /tmp/opnsense_acl_cache.json

# 完成提示
log "$GREEN" "安装完成，请刷新浏览器，然后进入Web界面，导航到服务 > 代理面板进行操作。"
echo ""
