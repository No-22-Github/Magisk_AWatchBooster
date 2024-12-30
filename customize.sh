ui_print "################################################################"
ui_print "您正在安装的是 AWatchBooster 安卓手表通用优化模块"
    echo '   ___ _      __     __      __   ___                __         '
    echo '  / _ | | /| / /__ _/ /_____/ /  / _ )___  ___  ___ / /____ ____'
    echo ' / __ | |/ |/ / _ `/ __/ __/ _ \/ _  / _ \/ _ \(_-</ __/ -_) __/'
    echo '/_/ |_|__/|__/\_,_/\__/\__/_//_/____/\___/\___/___/\__/\__/_/   '                                                             
    echo '   ___         _  __       ___  ___ '
    echo '  / _ )__ __  / |/ /__    |_  ||_  |'
    echo ' / _  / // / /    / _ \_ / __// __/ '
    echo '/____/\_, / /_/|_/\___(_)____/____/ '
    echo '     /___/                          '
ui_print "博客：no22.top"
ui_print "################################################################"
echo -e "手表厂商：$(getprop ro.product.manufacturer)"
echo -e "系统版本：$(getprop ro.build.display.id)"
echo -e " 处理器 ：$(getprop ro.board.platform)"
ui_print "- 正在释放文件"

# 使用 -p 参数来确保目录已存在或成功创建
mkdir -p "/storage/emulated/0/Android/AWatchBooster"
ui_print "- 创建 AWatchBooster 文件夹"

ui_print "- 配置文件与日志位于 /storage/emulated/0/Android/AWatchBooster"
unzip -o "$ZIPFILE" 'config.yaml' -d "/storage/emulated/0/Android/AWatchBooster/" >&2

echo "[$(date '+%m-%d %H:%M:%S.%3N')] AWatchBooster 模块安装成功, 等待重启" >> "/storage/emulated/0/Android/AWatchBooster/config.yaml.log"
ui_print "- AWatchBooster 安卓手表通用优化模块"
ui_print "- 开启无线 ADB / 解除安装限制"
ui_print "- 针对手表 CPU / GPU / 内存深度优化"
ui_print "- 屏幕优化 触控增强 帧率更稳定"
ui_print "- 网络 TCP 优化 连接更稳定 速率增加"
ui_print "- QQ 交流群: 824923954 | 酷安@No_22"
ui_print "- 模块安装结束 重启生效"
