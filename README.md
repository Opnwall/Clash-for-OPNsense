## OPNsense 代理全家桶
代理工具一键安装脚本，用于在OPNsense上运行Clash、MosDNS和Mosdns。支持Clash订阅转换、透明代理和DNS分流。带Web控制界面，可以进行配置修改、程序控制、日志查看。在OPNsense 25.1.4上测试通过。

![](images/proxy.png)

## 项目源代码
该项目集成了以下工具：

[Clash (mihomo)](https://github.com/MetaCubeX/mihomo/releases) 

[hev-socks5-tunnel](https://github.com/heiher/hev-socks5-tunnel)

[Mosdns](https://github.com/IrineSistiana/mosdns) 

[YACD](https://github.com/haishanh/yacd) 

[Subconverter](https://github.com/tindy2013/subconverter)


## 注意事项
1. 当前仅支持x86_64 平台。
2. 脚本不提供任何订阅信息，请准备好自己的Clash订阅URL。
4. 脚本会自动添加tun接口、china_ip别名、分流规则，可以根据需要进行手动修改。
5. 脚本已集成了可用的默认配置，只需替换clash的proxy和rule部分的内容即可使用。
7. 为减少长期运行保存的日志数量，在调试完成后，请将所有配置的日志类型修改为error或warn。

## 安装方法
下载并解压压缩包，上传到防火墙中，进入目录后运行以下命令：

```bash
sh install.sh
```

如下图所示：

![](images/install.png)

## 使用方法
请参考以下文章：
[OPNsense代理全家桶安装配置教程](https://pfchina.org/?p=14148)

## 常见问题
如果订阅转换不起作用，可以使用[SublinkX](https://github.com/gooaclok819/sublinkX)工具搭建自己的订阅转换平台。

## 参考资料
- [pfSense、OPNsense配置MosDNS教程](https://pfchina.org/?p=14088)  
- [pfSense、OPNsense配置Clash代理教程](https://pfchina.org/?p=10526)   
- [pfSense、OPNsense设置http透明代理教程](https://pfchina.org/?p=13572)  
- [pfSense、OPNsense配置hev-socks5-tunnel透明代理教程](https://pfchina.org/?p=14551)
