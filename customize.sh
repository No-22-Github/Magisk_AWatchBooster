ui_print "#############################################"
ui_print "您正在安装的是 ZT_Boosted 子腾系统通用优化模块"
ui_print "模块版本：v1.0-dev"
echo '   ___         _  __       ___  ___ '
echo '  / _ )__ __  / |/ /__    |_  ||_  |'
echo ' / _  / // / /    / _ \_ / __// __/ '
echo '/____/\_, / /_/|_/\___(_)____/____/ '
echo '     /___/                          '
ui_print "博客：no22.top"
ui_print "#############################################"
echo -e "系统版本：$(getprop ro.build.display.id)"
ui_print "- 正在释放文件"
mkdir "/storage/emulated/0/Android/ZT_boost"
ui_print "- 创建 ZT_Boosted 文件夹"
ui_print "- 配置文件与日志位于 /storage/emulated/0/Android/ZT_boost"
unzip -o "$ZIPFILE" 'config.yaml' -d "/storage/emulated/0/Android/ZT_Boosted/" >&2
echo "[$(date '+%m-%d %H:%M:%S.%3N')] ZT_Boosted v1.0-dev 模块安装成功, 等待重启" >> "/storage/emulated/0/Android/ZT_Boosted/config.yaml.log"
ui_print "- ZT_Boosted v1.0-dev 子腾系统通用优化模块"
ui_print "- 开启无线 ADB 解除安装限制"
ui_print "- 针对手表 CPU / GPU / 内存深度优化"
ui_print "- 屏幕优化 触控增强 帧率更稳定"
ui_print "- 网络 TCP 优化 连接更稳定 速率增加"
ui_print "- QQ 交流群: 824923954 | 酷安@No_22"
ui_print "- 模块安装结束 重启生效"