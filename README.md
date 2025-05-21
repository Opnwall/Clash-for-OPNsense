## Clash for OPNsense
Clash安装工具，运行Clash、Mosdns，在OPNsense上实现透明代理。支持Clash订阅、DNS分流。带Web控制界面，可以进行配置修改、程序控制、日志查看。在OPNsense 25.1.7上测试通过。

![](images/proxy.png)

## 集成程序

[Mosdns](https://github.com/IrineSistiana/mosdns) 

[Mihomo_tun](https://github.com/Vincent-Loeng/mihomo) 


## 注意事项
1. 当前仅支持x86_64 平台。
2. 脚本不提供任何订阅信息，请准备好自己的Clash订阅URL。
3. 脚本会自动添加tun接口、china_ip别名、分流规则，可以根据需要进行手动修改。
4. 脚本已集成了可用的默认配置，只需替换clash的proxies和rule部分配置即可使用。
5. 为减少长期运行保存的日志数量，在调试完成后，请将所有配置的日志类型修改为error或warn。

## 安装方法
下载后解压，上传到防火墙根目录，进入安装目录，运行以下命令安装：

```bash
sh install.sh
```
![](images/install.png)

## 卸载方法
运行以下命令卸载：

```bash
sh uninstall.sh
```

## 使用方法
请参考以下文章：

[pfSense、OPNsense安装配置Clash透明代理教程](https://pfchina.org/?p=14148)
