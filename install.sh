#!/bin/bash

##############  代理安装脚本  #################
echo -e ''
echo -e "\033[32m========Clash for OPNsense 代理全家桶一键安装脚本=========\033[0m"
echo -e ''

# 定义颜色变量
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# 定义目录变量
ROOT="/usr/local"
BIN_DIR="$ROOT/bin"
WWW_DIR="$ROOT/www"
CONF_DIR="$ROOT/etc"
MENU_DIR="$ROOT/opnsense/mvc/app/models/OPNsense"
RC_DIR="$ROOT/etc/rc.d"
PLUGINS="$ROOT/etc/inc/plugins.inc.d"
ACTIONS="$ROOT/opnsense/service/conf/actions.d"
RC_CONF="/etc/rc.conf.d/"
CONFIG_FILE="/conf/config.xml"
TMP_FILE="/tmp/config.xml.tmp"
TIMESTAMP=$(date +%F-%H%M%S)
BACKUP_FILE="/conf/config.xml.bak.$TIMESTAMP"

# 定义日志函数
log() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${RESET}"
}

# 创建目录
log "$YELLOW" "创建目录..."
mkdir -p "$CONF_DIR/clash" "$CONF_DIR/clash/sub" "$CONF_DIR/clash/ui" "$CONF_DIR/tun2socks" "$CONF_DIR/mosdns" || log "$RED" "目录创建失败！"

# 复制文件
log "$YELLOW" "复制文件..."
log "$YELLOW" "生成菜单..."
# 删除菜单缓存
rm -f /tmp/opnsense_menu_cache.xml
rm -f /tmp/opnsense_acl_cache.json
sleep 1
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
cp -R -f menu/* "$MENU_DIR/" || log "$RED" "menu 文件复制失败！"
cp rc.d/* "$RC_DIR/" || log "$RED" "rc.d 文件复制失败！"
cp geo/* "$CONF_DIR/clash/" || log "$RED" "geo 文件复制失败！"
cp conf/config_clash.yaml "$CONF_DIR/clash/config.yaml" || log "$RED" "clash 配置文件复制失败！"
cp conf/config_tun2socks.yaml "$CONF_DIR/tun2socks/config.yaml" || log "$RED" "tun2socks 配置文件复制失败！"
sleep 1

# 新建订阅程序
log "$YELLOW" "添加订阅..."
cat>/usr/bin/sub<<EOF
# 启动clash订阅程序
bash /usr/local/etc/clash/sub/sub.sh
EOF
chmod +x /usr/bin/sub

# 安装bash
log "$GREEN" "安装bash..."
if ! pkg info -q bash > /dev/null 2>&1; then
  pkg install -y bash > /dev/null 2>&1
fi

# 添加服务启动项
log "$YELLOW" "配置系统服务..."
cp -f rc.conf/* "$RC_CONF/" || log "$RED" "rc.conf 文件复制失败！"
# 启动Tun接口
log "$YELLOW" "启动tun2socks..."
service tun2socks start > /dev/null 2>&1
echo ""

# 备份配置文件
cp "$CONFIG_FILE" "$BACKUP_FILE" || {
  echo "配置备份失败，终止操作！"
  echo ""
  exit 1
}

# 添加tun接口
log "$YELLOW" "添加tun接口..."
sleep 1
if grep -q "<if>tun_3000</if>" "$CONFIG_FILE"; then
  echo "存在同名接口，忽略"
  echo ""
else
  awk '
  BEGIN { inserted = 0 }
  /<interfaces>/ { print; next }
  /<\/interfaces>/ && inserted == 0 {
    print "    <tun_3000>"
    print "      <if>tun_3000</if>"
    print "      <descr>TUN</descr>"
    print "      <enable>1</enable>"
    print "      <spoofmac/>"
    print "      <gateway_interface>1</gateway_interface>"
    print "      <ipaddr>10.10.0.1</ipaddr>"
    print "      <subnet>32</subnet>"
    print "    </tun_3000>"
    inserted = 1
  }
  { print }
  ' "$CONFIG_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$CONFIG_FILE"
  echo "接口添加完成"
  echo ""
fi

# 添加CN_IP别名
log "$YELLOW" "添加CN_IP别名..."
if grep -q "<content>https://ispip.clang.cn/all_cn.txt</content>" "$CONFIG_FILE"; then
  echo "存在相同别名，忽略"
  echo ""	
else
  awk '
  BEGIN { inserted = 0 }
  /<aliases\/>/ && inserted == 0 {
    print "        <aliases>"
    print "          <alias uuid=\"315eb669-41ef-48c2-90bb-d5c9d99a00eb\">"
    print "            <enabled>1</enabled>"
    print "            <name>CN_IP</name>"
    print "            <type>urltable</type>"
    print "            <path_expression/>"
    print "            <proto/>"
    print "            <interface/>"
    print "            <counters>0</counters>"
    print "            <updatefreq>1</updatefreq>"
    print "            <content>https://ispip.clang.cn/all_cn.txt</content>"
    print "            <password/>"
    print "            <username/>"
    print "            <authtype/>"
    print "            <categories/>"
    print "            <description>&#x4E2D;&#x56FD;IP&#x5217;&#x8868;</description>"
    print "          </alias>"
    print "        </aliases>"
    inserted = 1
    next
  }
  /<alias .*?>/ && inserted == 0 {
    print "          <alias uuid=\"315eb669-41ef-48c2-90bb-d5c9d99a00eb\">"
    print "            <enabled>1</enabled>"
    print "            <name>CN_IP</name>"
    print "            <type>urltable</type>"
    print "            <path_expression/>"
    print "            <proto/>"
    print "            <interface/>"
    print "            <counters>0</counters>"
    print "            <updatefreq>1</updatefreq>"
    print "            <content>https://ispip.clang.cn/all_cn.txt</content>"
    print "            <password/>"
    print "            <username/>"
    print "            <authtype/>"
    print "            <categories/>"
    print "            <description>&#x4E2D;&#x56FD;IP&#x5217;&#x8868;</description>"
    print "          </alias>"
    inserted = 1
  }
  { print }
  ' "$CONFIG_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$CONFIG_FILE"
    echo "别名添加完成"
    echo ""	
fi

# 添加防火墙规则（非中国IP走透明网关TUN_GW）
log "$YELLOW" "添加防火墙规则..."
sleep 1
if grep -q "<gateway>TUN_GW</gateway>" "$CONFIG_FILE"; then
  echo "存在同名规则，忽略"
  echo ""
else
  awk '
  /<filter>/ {
    print
    print "    <rule uuid=\"c0398153-597b-403b-9069-734734b46497\">"
    print "      <type>pass</type>"
    print "      <interface>lan</interface>"
    print "      <ipprotocol>inet</ipprotocol>"
    print "      <statetype>keep state</statetype>"
    print "      <descr>&#x56FD;&#x5916;IP&#x8D70;&#x900F;&#x660E;&#x7F51;&#x5173;</descr>"
    print "      <gateway>TUN_GW</gateway>"
    print "      <direction>in</direction>"
    print "      <floating>yes</floating>"
    print "      <quick>1</quick>"
    print "      <source>"
    print "        <network>lan</network>"
    print "      </source>"
    print "      <destination>"
    print "        <address>CN_IP</address>"
    print "        <not>1</not>"
    print "      </destination>"
    print "    </rule>"
    next
  }
  { print }
  ' "$CONFIG_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$CONFIG_FILE"
  echo "规则添加完成"
  echo ""
fi

# 更改Unbound端口为 5355
sleep 1
log "$YELLOW" "更改Unbound端口..."

PORT_OK=$(awk '
BEGIN {
  in_unbound = 0
  in_general = 0
}
/<unboundplus[^>]*>/ { in_unbound = 1 }
/<\/unboundplus>/ { in_unbound = 0 }
{
  if (in_unbound && /<general>/) {
    in_general = 1
  }
  if (in_unbound && /<\/general>/) {
    in_general = 0
  }
  if (in_unbound && in_general && /<port>5355<\/port>/) {
    print "yes"
    exit
  }
}
' "$CONFIG_FILE")

if [ "$PORT_OK" = "yes" ]; then
  echo "端口已经为5355，跳过"
else
  awk '
  BEGIN {
    in_unbound = 0
    in_general = 0
    port_handled = 0
  }
  {
    if ($0 ~ /<unboundplus[^>]*>/) {
      in_unbound = 1
    }
    if ($0 ~ /<\/unboundplus>/) {
      in_unbound = 0
    }

    if (in_unbound && $0 ~ /<general>/) {
      in_general = 1
      print
      next
    }

    if (in_unbound && in_general && $0 ~ /<\/general>/) {
      if (port_handled == 0) {
        print "        <port>5355</port>"
        port_handled = 1
      }
      in_general = 0
      print
      next
    }

    if (in_unbound && in_general && $0 ~ /<port>.*<\/port>/ && port_handled == 0) {
      sub(/<port>.*<\/port>/, "<port>5355</port>")
      port_handled = 1
      print
      next
    }

    print
  }
  ' "$CONFIG_FILE" > "$TMP_FILE"

  if [ -s "$TMP_FILE" ]; then
    mv "$TMP_FILE" "$CONFIG_FILE"
    echo "端口已设置为5355"
  else
    log "$RED" "修改失败，请检查配置文件"
  fi
fi
echo ""

# 重启服务Unbound
log "$YELLOW" "重启Unbound服务..."
/usr/local/etc/rc.d/unbound restart > /dev/null 2>&1
echo ""

# 重新载入防火墙规则
log "$YELLOW" "重新载入防火墙规则..."
configctl filter reload > /dev/null 2>&1
echo ""

# 重新载入configd
log "$YELLOW" "重新载入configd..."
service configd restart > /dev/null 2>&1
echo ""

# 重启所有服务
# log "$YELLOW" "应用所有更改，请稍等..."
# /usr/local/etc/rc.reload_all >/dev/null 2>&1
# echo "所有服务已重新加载！"
# echo ""

# 完成提示
log "$GREEN" "安装完毕，请刷新浏览器，导航到VPN > Proxy Suite 进行配置。"
echo ""
