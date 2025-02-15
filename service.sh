# AWatchBooster
# 基于 Magisk-All-In-One v1.3
# 延迟执行 service.sh 脚本
# All-In-One v1.0 的 sleep 1m 在某些设备上不太实际
# 从 v1.2 版本开始采用监测文件方案判断是否开机
# while true 嵌套 sleep 1 并不会造成开机卡死
# 参考如何有效降低死循环的 CPU 占用 - sebastia - 博客园
# https://www.cnblogs.com/memoryLost/p/10907654.html
# 获取脚本路径
MODDIR=${0%/*}
# 循环判断是否开机
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 3
done
# 创建用于文件权限测试的文件
test_file="/sdcard/Android/.PERMISSION_TEST"
# 写入 true 到文件
true >"$test_file"
# 判断是否有权限
while [ ! -f "$test_file" ]; do
    true > "$test_file"
    sleep 1
done
# 删除测试文件
rm "$test_file"

# 定义配置文件路径和日志文件路径
CONFIG_FILE="/storage/emulated/0/AWatchBooster/config.yaml"
LOG_FILE="/storage/emulated/0/AWatchBooster/config.yaml.log"

# 定义 read_config 读取配置函数，若找不到匹配项，则返回默认值
read_config() {
  local result=$(sed -n "s/^$1//p" "$CONFIG_FILE")
  echo ${result:-$2}
}
DEBUG_STATUS=$(read_config "开启Debug输出_" "1" )
# 定义 module_log 输出日志函数
module_log() {
  echo "[$(date '+%m-%d %H:%M:%S')] $1" >> $LOG_FILE
  if [ "$DEBUG_STATUS" = "0" ]; then
    echo "[$(date '+%m-%d %H:%M:%S.%3N')] $1" # for debug
  fi
}
# 检查日志文件大小
if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -gt 524288 ]
then
  # 删除文件
  rm "$LOG_FILE"
  module_log "日志文件达到 512KB 及以上 已重新创建"
fi

# 读取 config.yaml 配置
# 获取 CPU 最大频率值
CPU_MAX_FREQ=$(read_config "频率限制_" "1")
# 获取性能模式
# 0: 性能优先
# 1: 均衡模式
# 2: 省电模式
PERFORMANCE=$(read_config "性能模式_" "1")
# 获取温控阈值
TEMP_THRESHOLD=$(read_config "温度控制_" "60")
# 获取 CPU 应用分配
BACKGROUND=$(read_config "用户后台应用_" "0")
SYSTEM_BACKGROUND=$(read_config "系统后台应用_" "0")
FOREGROUND=$(read_config "前台应用_" "0-3")
SYSTEM_FOREGROUND=$(read_config "上层应用_" "0-3")
# 模块日志输出
OPTIMIZE_MODULE=$(read_config "模块日志输出_" "0")
# 无线 ADB 调试
WIRELESS_ADB=$(read_config "无线ADB调试_" "0")
# ZRAM 设置
ZRAM_STATUS=$(read_config "ZRAM状态_" "0")
# 息屏降频省电功能
POWER_SAVE=$(read_config "息屏降频_" "0")
# 设置USB为MTP协议
USB_MTP=$(read_config "设置USB为MTP_" "1")
# 调整模块日志输出
if [ "$OPTIMIZE_MODULE" = "0" ]; then
  # 判断日志文件是否为已创建
  # 已创建则在文件末尾添加换行
  [ -f $LOG_FILE ] && echo "" >> $LOG_FILE
else
  LOG_FILE="/dev/null"
fi

# 输出日志
module_log "开机完成，已获取到 config.yaml 配置..."

# 选择 CPU 调速器
if [ "PERFORMANCE" = "0" ]; then
  CPU_SCALING="performance"
else
  CPU_SCALING="sprdemand"
fi

chmod 644 /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
chmod 644 /dev/cpuset/background/cpus
chmod 644 /dev/cpuset/system-background/cpus
chmod 644 /dev/cpuset/foreground/cpus
chmod 644 /dev/cpuset/top-app/cpus

if [ "$CPU_MAX_FREQ" != "1" ]; then
  # 将 CPU 最大频率转换为 kHz
  max_freq_khz=$(echo "$CPU_MAX_FREQ" | awk '{gsub(/[^0-9]/, ""); print $1 * 1000}')
  # 设置 CPU 最大频率
  echo $max_freq_khz > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
  module_log "CPU 频率限制已启动，当前 CPU 最大频率：${max_freq_khz} kHz"
fi

if [ "$PERFORMANCE" = "0" ] || [ "$PERFORMANCE" = "1" ]; then
  # 设置 CPU 应用分配
  # 用户后台应用
  echo $BACKGROUND > /dev/cpuset/background/cpus
  # 系统后台应用
  echo $SYSTEM_BACKGROUND > /dev/cpuset/system-background/cpus
  # 前台应用
  echo $FOREGROUND > /dev/cpuset/foreground/cpus
  # 上层应用
  echo $SYSTEM_FOREGROUND > /dev/cpuset/top-app/cpus
  module_log "性能/均衡模式，启动！"
  module_log "正在设置 CPU 应用分配"
  module_log "- 用户的后台应用: $BACKGROUND"
  module_log "- 系统的后台应用: $SYSTEM_BACKGROUND"
  module_log "- 前台应用: $FOREGROUND"
  module_log "- 上层应用: $SYSTEM_FOREGROUND"
  # 温控
  # 60 度开始降频，保护电池
  echo $TEMP_THRESHOLD > /sys/class/thermal/thermal_zone0/trip_point_0_temp
  echo $TEMP_THRESHOLD > /sys/class/thermal/thermal_zone1/trip_point_0_temp
  module_log "- 核心分配优化已开启"
  module_log "- CPU/GPU 温控优化已开启"
  # CPU 调度
  chmod 644 /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
  echo "$CPU_SCALING" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
  CPU_SCALING_UPPERCASE=$(echo "$CPU_SCALING" | tr '[:lower:]' '[:upper:]')
  module_log "CPU 调度模式为 ${CPU_SCALING_UPPERCASE} 模式"
fi

# 省电模式
if [ "$PERFORMANCE" = "2" ]; then
  # 设置 CPU 应用分配
  echo "0" > /dev/cpuset/background/cpus
  # 系统后台应用
  echo "1" > /dev/cpuset/system-background/cpus
  # 前台应用
  echo "0-3" > /dev/cpuset/foreground/cpus
  # 上层应用
  echo "3" > /dev/cpuset/top-app/cpus
  module_log "省电模式，启动！"
  module_log "正在设置 CPU 应用分配"
  module_log "- 用户的后台应用: 0"
  module_log "- 系统的后台应用: 1"
  module_log "- 前台应用: 0-3"
  module_log "- 上层应用: 3"
  # 温控
  # 60 度开始降频，保护电池
  echo $TEMP_THRESHOLD > /sys/class/thermal/thermal_zone0/trip_point_0_temp
  echo $TEMP_THRESHOLD > /sys/class/thermal/thermal_zone1/trip_point_0_temp
  module_log "- 核心分配优化已开启"
  module_log "- CPU/GPU 温控优化已开启"
  # CPU 调度
  chmod 644 /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
  echo "$CPU_SCALING" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
  CPU_SCALING_UPPERCASE=$(echo "$CPU_SCALING" | tr '[:lower:]' '[:upper:]')
  module_log "CPU 调度模式为 ${CPU_SCALING_UPPERCASE} 模式"
fi

# I/O STATS 优化
echo "0" > /sys/block/dm-0/queue/iostats
# 页面簇优化
echo "0" > /proc/sys/vm/page-cluster
# 内核堆优化
echo "0" > /proc/sys/kernel/randomize_va_space
# 禁止压缩不可压缩的进程
echo "0" > /proc/sys/vm/compact_unevictable_allowed
module_log "已开启固态&内存优化"


# 关闭 ZRAM 减少性能/磁盘损耗
if [ "$ZRAM_STATUS" = "0" ]; then
  swapoff /dev/block/zram0 2>/dev/null
  swapoff /dev/block/zram1 2>/dev/null
  swapoff /dev/block/zram2 2>/dev/null
  echo "1" > /sys/block/zram0/reset
  module_log "已禁用 ZRAM 压缩内存"
fi
# 不关闭 ZRAM
if [ "$ZRAM_STATUS" = "1" ]; then
  module_log "未禁用 ZRAM 压缩内存"
  module_log "当前由系统默认配置"
fi

# 无线 ADB
if [ "$WIRELESS_ADB" = "0" ]; then
  setprop persist.adb.enable 1 && setprop persist.service.adb.enable 1 && setprop service.adb.tcp.port 5555 && stop adbd && start adbd
  module_log "已开启 ADB 在 5555 端口"
fi

if [ "$WIRELESS_ADB" = "1" ]; then
  module_log "未开启无线 ADB"
fi

# 快充优化
chmod 755 /sys/class/power_supply/*/*
chmod 755 /sys/module/qpnp_smbcharger/*/*
chmod 755 /sys/module/dwc3_msm/*/*
chmod 755 /sys/module/phy_msm_usb/*/*
echo "1" > /sys/kernel/fast_charge/force_fast_charge
echo "1" > /sys/kernel/fast_charge/failsafe
echo "1" > /sys/class/power_supply/battery/allow_hvdcp3
echo "0" > /sys/class/power_supply/battery/restricted_charging
echo "0" > /sys/class/power_supply/battery/system_temp_level
echo "0" > /sys/class/power_supply/battery/input_current_limited
echo "1" > /sys/class/power_supply/battery/subsystem/usb/pd_allowed
echo "1" > /sys/class/power_supply/battery/input_current_settled
echo "0" > /sys/class/power_supply/battery/input_suspend
echo "1" > /sys/class/power_supply/battery/battery_charging_enabled
echo "1" > /sys/class/power_supply/usb/boost_current
echo "100" >/sys/class/power_supply/bms/temp_cool
echo "600" >/sys/class/power_supply/bms/temp_warm
echo "30000" > /sys/module/qpnp_smbcharger/parameters/default_hvdcp_icl_ma
echo "30000" > /sys/module/qpnp_smbcharger/parameters/default_dcp_icl_ma
echo "30000" > /sys/module/qpnp_smbcharger/parameters/default_hvdcp3_icl_ma
echo "30000" > /sys/module/dwc3_msm/parameters/dcp_max_current
echo "30000" > /sys/module/dwc3_msm/parameters/hvdcp_max_current
echo "30000" > /sys/module/phy_msm_usb/parameters/dcp_max_current
echo "30000" > /sys/module/phy_msm_usb/parameters/hvdcp_max_current
echo "30000" > /sys/module/phy_msm_usb/parameters/lpm_disconnect_thresh
echo "12000000" > /sys/class/power_supply/battery/fast_charge_current
echo "12000000" > /sys/class/power_supply/battery/thermal_input_current
echo "30000000" > /sys/class/power_supply/dc/current_max
echo "30000000" > /sys/class/power_supply/main/current_max
echo "30000000" > /sys/class/power_supply/parallel/current_max
echo "30000000" > /sys/class/power_supply/pc_port/current_max
echo "30000000" > /sys/class/power_supply/qpnp-dc/current_max
echo "30000000" > /sys/class/power_supply/battery/current_max
echo "30000000" > /sys/class/power_supply/battery/input_current_max
echo "30000000" > /sys/class/power_supply/usb/current_max
echo "30000000" > /sys/class/power_supply/usb/hw_current_max
echo "30000000" > /sys/class/power_supply/usb/pd_current_max
echo "30000000" > /sys/class/power_supply/usb/ctm_current_max
echo "30000000" > /sys/class/power_supply/usb/sdp_current_max
echo "30100000" > /sys/class/power_supply/main/constant_charge_current_max
echo "30100000" > /sys/class/power_supply/parallel/constant_charge_current_max
echo "30100000" > /sys/class/power_supply/battery/constant_charge_current_max
echo "31000000" > /sys/class/qcom-battery/restricted_current
module_log "已开启快充优化"

# 息屏降频省电
if [ "$POWER_SAVE" = "0" ]; then
  sh "$MODDIR/power_save.sh" &
  module_log "已开启息屏降频省电功能"
fi

# 设置USB为MTP
if [ "$USB_MTP" = "0" ]; then
  sh "$MODDIR/set_mtp.sh" &
  module_log "已开启设置 USB 为 MTP 协议功能"
fi
# 通过DEBUG模式开启GPU加速
settings put global enable_gpu_debug_layers 0
settings put system debug.composition.type dyn
module_log "已通过DEBUG模式开启GPU加速"
# 通过UBWC降低屏幕功耗
settings put global debug.gralloc.enable_fb_ubwc 1
module_log "已通过UBWC降低屏幕功耗"

module_log "模块 service.sh 已结束"
module_log "𝘼𝙒𝙖𝙩𝙘𝙝𝘽𝙤𝙤𝙨𝙩𝙚𝙧 优化结束 🚀🚀🚀"

# 获取当前时间
current_time=$(date "+%m-%d %H:%M")
# 在模块启动时删除之前的标记
sed -i "s/ \[.*🚀优化完毕\]//" "$MODDIR/module.prop"
# 修改description，添加结束时间
sed -i "s/^description=.*/& \[${current_time}🚀优化完毕\]/" "$MODDIR/module.prop"