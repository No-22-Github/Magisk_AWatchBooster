# AWatchBooster v1.0
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
CONFIG_FILE="/storage/emulated/0/Android/AWatchBooster/config.yaml"
LOG_FILE="/storage/emulated/0/Android/AWatchBooster/config.yaml.log"
# 定义 module_log 输出日志函数
module_log() {
  echo "[$(date '+%m-%d %H:%M:%S.%3N')] $1" >> $LOG_FILE
  echo "[$(date '+%m-%d %H:%M:%S.%3N')] $1" # for debug
}
# 定义 read_config 读取配置函数，若找不到匹配项，则返回默认值
read_config() {
  result=$(awk -v start="$1" '
    $0 ~ "^" start {
      sub("^" start, "");
      print;
      exit
    }
  ' "$CONFIG_FILE")
  if [ -z "$result" ]; then
    echo "$2"
  else
    echo "$result"
  fi
}

# 检查日志文件大小
if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -gt 524288 ]
then
  # 删除文件
  rm "$LOG_FILE"
  module_log "日志文件达到 512KB 重新创建"
fi
# 读取 config.yaml 配置

# 获取性能模式
# 0: 性能优先
# 1: 省电优先
PERFORMANCE=$(read_config "性能模式_" "0")
# 获取温控阈值
TEMP_THRESHOLD=$(read_config "温度控制_" "60")
# 获取 CPU 应用分配
BACKGROUND=$(read_config "用户后台应用_" "0")
SYSTEM_BACKGROUND=$(read_config "系统后台应用_" "0")
FOREGROUND=$(read_config "前台应用_" "0-3")
SYSTEM_FOREGROUND=$(read_config "上层应用_" "0-3")

# CPU 调度模式 SCALING
CPU_SCALING="performance"

# 其他选项
# TCP 网络优化
OPTIMIZE_TCP=$(read_config "TCP网络优化_" "0")
# 模块日志输出
OPTIMIZE_MODULE=$(read_config "模块日志输出_" "0")
# 无线 ADB 调试
WIRELESS_ADB=$(read_config "无线ADB调试_" "0")
# ZRAM 设置
ZRAM_STATUS=$(read_config "ZRAM状态_" "0")
# 息屏降频省电功能
POWER_SAVE=$(read_config "息屏降频_" "0")

# 调整模块日志输出
if [ "$OPTIMIZE_MODULE" == "0" ]; then
  # 判断日志文件是否为已创建
  # 已创建则在文件末尾添加换行
  [ -f $LOG_FILE ] && echo "" >> $LOG_FILE
else
  LOG_FILE = "/dev/null"
fi

# 输出日志
module_log "开机完成，正在读取 config.yaml 配置..."


if [ "$PERFORMANCE" == "0" ]; then
  # 设置 CPU 应用分配
  # 用户后台应用
  echo $BACKGROUND > /dev/cpuset/background/cpus
  # 系统后台应用
  echo $SYSTEM_BACKGROUND > /dev/cpuset/system-background/cpus
  # 前台应用
  echo $FOREGROUND > /dev/cpuset/foreground/cpus
  # 上层应用
  echo $SYSTEM_FOREGROUND > /dev/cpuset/top-app/cpus
  module_log "性能模式，启动！"
  module_log "正在设置 CPU 应用分配"
  module_log "- 用户的后台应用: $BACKGROUND"
  module_log "- 系统的后台应用: $SYSTEM_BACKGROUND"
  module_log "- 前台应用: $FOREGROUND"
  module_log "- 上层应用: $SYSTEM_FOREGROUND"

  # 温控
  # 60 度开始降频，保护电池
  echo $TEMP_THRESHOLD > /sys/class/thermal/thermal_zone0/trip_point_0_temp
  # CPU 温控 修改为99度
  echo $TEMP_THRESHOLD > /sys/class/thermal/thermal_zone1/trip_point_0_temp
  module_log "- 核心分配优化已开启"
  module_log "- CPU/GPU 温控优化已开启"
  # CPU 调度
  chmod 644 /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
  echo $CPU_SCALING > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
  # 将 CPU_SCALING 模式转换为大写字符串并输出
  CPU_SCALING_UPPERCASE=$(echo "$CPU_SCALING" | tr '[:lower:]' '[:upper:]')
  module_log "CPU 调度模式为 ${CPU_SCALING_UPPERCASE} 性能模式"
fi

# 省电模式
if [ "$PERFORMANCE" == "1" ]; then
  # 设置 CPU 应用分配
  echo "0" > /dev/cpuset/background/cpus
  # 系统后台应用
  echo "0" > /dev/cpuset/system-background/cpus
  # 前台应用
  echo "0-3" > /dev/cpuset/foreground/cpus
  # 上层应用
  echo "2-3" > /dev/cpuset/top-app/cpus
  module_log "省电模式，启动！"
  module_log "正在设置 CPU 应用分配"
  module_log "- 用户的后台应用: 0"
  module_log "- 系统的后台应用: 0"
  module_log "- 前台应用: 0-3"
  module_log "- 上层应用: 2-3"
  
  # CPU 调度
  chmod 644 /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
  echo "sprdemand" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
  module_log "CPU 调度模式为 SPRDEMAND 节电模式"
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
if [ "$ZRAM_STATUS" == "0" ]; then
  swapoff /dev/block/zram0 2>/dev/null
  swapoff /dev/block/zram1 2>/dev/null
  swapoff /dev/block/zram2 2>/dev/null
  echo "1" > /sys/block/zram0/reset
  module_log "已禁用 ZRAM 压缩内存"
fi
# 不关闭 ZRAM
if [ "$ZRAM_STATUS" == "1" ]; then
  module_log "未禁用 ZRAM 压缩内存"
  module_log "当前由系统默认配置"
fi

# 无线 ADB
if [ "$WIRELESS_ADB" == "0" ]; then
  setprop persist.adb.enable 1 && setprop persist.service.adb.enable 1 && setprop service.adb.tcp.port 5555 && stop adbd && start adbd
  module_log "已开启 ADB 在 5555 端口"
fi

if [ "$WIRELESS_ADB" == "1" ]; then
  module_log "未开启无线 ADB"
fi

# 快充优化
chmod 755 /sys/class/*/*/*
chmod 755 /sys/module/*/*/*
echo '1' > /sys/kernel/fast_charge/force_fast_charge
echo '1' > /sys/kernel/fast_charge/failsafe
echo '1' > /sys/class/power_supply/battery/allow_hvdcp3
echo '0' > /sys/class/power_supply/battery/restricted_charging
echo '0' > /sys/class/power_supply/battery/system_temp_level
echo '0' > /sys/class/power_supply/battery/input_current_limited
echo '1' >/sys/class/power_supply/battery/subsystem/usb/pd_allowed
echo '1' > /sys/class/power_supply/battery/input_current_settled
echo '100' >/sys/class/power_supply/bms/temp_cool
echo '600' >/sys/class/power_supply/bms/temp_warm
echo '4000' > /sys/module/qpnp_smbcharger/parameters/default_hvdcp_icl_ma
echo '4000' > /sys/module/qpnp_smbcharger/parameters/default_dcp_icl_ma
echo '4000' > /sys/module/qpnp_smbcharger/parameters/default_hvdcp3_icl_ma
echo '4000' > /sys/module/dwc3_msm/parameters/dcp_max_current
echo '4000' > /sys/module/dwc3_msm/parameters/hvdcp_max_current
echo '4000' > /sys/module/phy_msm_usb/parameters/dcp_max_current
echo '4000' > /sys/module/phy_msm_usb/parameters/hvdcp_max_current
echo '4000' > /sys/module/phy_msm_usb/parameters/lpm_disconnect_thresh
echo '4000000' > /sys/class/power_supply/dc/current_max
echo '4000000' > /sys/class/power_supply/main/current_max
echo '4000000' > /sys/class/power_supply/parallel/current_max
echo '4000000' > /sys/class/power_supply/pc_port/current_max
echo '4000000' > /sys/class/power_supply/qpnp-dc/current_max
echo '4000000' > /sys/class/power_supply/battery/current_max
echo '4000000' > /sys/class/power_supply/battery/input_current_max
echo '4000000' > /sys/class/power_supply/usb/current_max
echo '4100000' > /sys/class/power_supply/usb/hw_current_max
echo '4000000' > /sys/class/power_supply/usb/pd_current_max
echo '4000000' > /sys/class/power_supply/usb/ctm_current_max
echo '4000000' > /sys/class/power_supply/usb/sdp_current_max
echo '4100000' > /sys/class/power_supply/main/constant_charge_current_max
echo '4100000' > /sys/class/power_supply/parallel/constant_charge_current_max
echo '4100000' > /sys/class/power_supply/battery/constant_charge_current_max
echo '5000000' > /sys/class/qcom-battery/restricted_current
echo '1' > /sys/class/power_supply/usb/boost_current
sleep 1
module_log "已开启快充优化"

# TCP 优化
if [ "$OPTIMIZE_TCP" == "0" ]; then
  echo "
net.ipv4.conf.all.route_localnet=1
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.default.forwarding = 1
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1
net.ipv6.conf.lo.forwarding = 1
net.ipv6.conf.all.accept_ra = 2
net.ipv6.conf.default.accept_ra = 2
net.core.netdev_max_backlog = 100000
net.core.netdev_budget = 50000
net.core.netdev_budget_usecs = 5000
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 67108864
net.core.wmem_default = 67108864
net.core.optmem_max = 65536
net.core.somaxconn = 10000
net.ipv4.icmp_echo_ignore_all = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.tcp_keepalive_time = 8
net.ipv4.tcp_keepalive_intvl = 8
net.ipv4.tcp_keepalive_probes = 1
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syncookies = 0
net.ipv4.tcp_rfc1337 = 0
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 8
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.tcp_mtu_probing = 0
net.ipv4.tcp_autocorking = 0
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_max_syn_backlog = 30000
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_frto = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.neigh.default.gc_thresh3=8192
net.ipv4.neigh.default.gc_thresh2=4096
net.ipv4.neigh.default.gc_thresh1=2048
net.ipv6.neigh.default.gc_thresh3=8192
net.ipv6.neigh.default.gc_thresh2=4096
net.ipv6.neigh.default.gc_thresh1=2048
net.ipv4.tcp_max_syn_backlog = 262144
net.netfilter.nf_conntrack_max = 262144
net.nf_conntrack_max = 262144
" > /data/sysctl.conf
  # 给予 sysctl.conf 配置文件权限
  chmod 777 /data/sysctl.conf
  # 启用自定义配置文件
  sysctl -p /data/sysctl.conf
  # 启用 ip route 配置
  ip route | while read config; do
    ip route change $config initcwnd 20;
  done
  # 删除 wlan_logs 网络日志
  rm -rf /data/vendor/wlan_logs
  module_log "已开启 TCP 网络优化"
fi
# 息屏降频省电
if ["$POWER_SAVE" = "0"]; then
  sh "$MODDIR/power_save.sh"
  module_log "已开启息屏降频省电功能"
if
module_log "模块 service.sh 已结束"
module_log "𝘼𝙒𝙖𝙩𝙘𝙝𝘽𝙤𝙤𝙨𝙩𝙚𝙧 优化结束 🚀🚀🚀"

# 获取当前时间
current_time=$(date "+%m-%d %H:%M")
# 在模块启动时删除之前的标记
sed -i "s/ \[.*🚀优化完毕\]//" "$MODDIR/module.prop"
# 修改description，添加结束时间
sed -i "s/^description=.*/& \[${current_time}🚀优化完毕\]/" "$MODDIR/module.prop"
