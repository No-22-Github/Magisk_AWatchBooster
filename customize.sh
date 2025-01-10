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
ui_print "正在获取获取 CPU 可用频率档位"
# 获取 CPU 可用频率挡，单位为 kHz
frequencies_khz=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies)
# 创建或清空临时文件
temp_yaml=$(mktemp)
# 将频率值转换为 MHz 并输出到临时文件
for freq in $frequencies_khz; do
  freq_mhz=$((freq / 1000))
  echo "  - ${freq_mhz} MHz" >> "$temp_yaml"
done
# 将频率信息插入到目标 YAML 文件的 frequencies 字段
sed -i '/可用频率档位:/r '"$temp_yaml"'' /storage/emulated/0/Android/AWatchBooster/config.yaml
# 删除临时文件
rm "$temp_yaml"
echo "[$(date '+%m-%d %H:%M:%S.%3N')] AWatchBooster 模块安装成功, 等待重启" >> "/storage/emulated/0/Android/AWatchBooster/config.yaml.log"
ui_print "- AWatchBooster 安卓手表通用优化模块"
ui_print "- Ver 1.6 已安装！"
ui_print "- 🎉新功能"
ui_print "- 1. 抬腕延迟唤醒，适合开抬腕亮屏的小伙伴"
ui_print "- 2. 新增更多性能预设"
ui_print "- 3. CPU 频率压制功能"
ui_print "- 🛠️bug修复"
UI_print "- 修复了性能模式调度过于激进的问题"
ui_print "- 修改了省电模式的 CPU 核心分配，避免 0 核占用过高"
ui_print "- ⚠️配置文件已更新，请重新配置⚠️"
ui_print "- QQ 交流群: 824923954 | 酷安@No_22"
ui_print "- 模块安装结束 重启生效"
