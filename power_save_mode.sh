# 息屏降频 省电模式
# 获取脚本路径
MODDIR=${0%/*}
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

module_log "正在启动息屏降频功能..."

# 读取设置的检测周期
CHECK_INTERVAL=$(read_config "检测周期_" "3")

# 获取 CPU 当前状态信息
CPU_MAX_FREQ=$(cat "/sys/devices/system/cpu/cpu3/cpufreq/cpuinfo_max_freq")
CPU_MIN_FREQ=$(cat "/sys/devices/system/cpu/cpu3/cpufreq/cpuinfo_min_freq")
BACKGROUND=$(cat "/dev/cpuset/background/cpus")
SYSTEM_BACKGROUND=$(cat "/dev/cpuset/system-background/cpus")
FOREGROUND=$(cat "/dev/cpuset/foreground/cpus")
SYSTEM_FOREGROUND=$(cat "/dev/cpuset/top-app/cpus")

# 打印
module_log "检测周期: $CHECK_INTERVAL"
module_log "CPU最大频率: $CPU_MAX_FREQ"
module_log "CPU最小频率: $CPU_MIN_FREQ"
module_log "后台进程CPU集: $BACKGROUND"
module_log "系统后台进程CPU集: $SYSTEM_BACKGROUND"
module_log "前台进程CPU集: $FOREGROUND"
module_log "系统前台进程CPU集: $SYSTEM_FOREGROUND"

while true; do
  SCREEN_STATUS=$(dumpsys display | grep mScreenState | awk -F '=' '{print $2}')
  if [ "$SCREEN_STATUS" = "ON" ]; then
    # 降频到最低
    echo $CPU_MIN_FREQ > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
    # 设置 CPU 应用分配
    echo "0-3" > /dev/cpuset/background/cpus
    echo "0-3" > /dev/cpuset/system-background/cpus
    echo "0-3" > /dev/cpuset/foreground/cpus
    echo "0-3" > /dev/cpuset/top-app/cpus
    module_log "已息屏并降频到 $CPU_MIN_FREQ "
    sleep $CHECK_INTERVAL
  else
    echo $CPU_MAX_FREQ > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
    # 设置 CPU 应用分配
    echo $BACKGROUND > /dev/cpuset/background/cpus
    echo $SYSTEM_BACKGROUND > /dev/cpuset/system-background/cpus
    echo $FOREGROUND > /dev/cpuset/foreground/cpus
    echo $SYSTEM_FOREGROUND > /dev/cpuset/top-app/cpus
    module_log "已息屏并降频到 $CPU_MAX_FREQ "
    sleep $CHECK_INTERVAL
  fi
done