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

# 获取CPU核数
get_cpu_cores() {
  nproc
}

# 根据CPU核数动态分配省电模式的CPU
set_power_save_cpus() {
  cpu_cores=$(get_cpu_cores)
  echo "0-$(($cpu_cores - 1))"
}

# 修改权限为644
chmod 644 /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
chmod 644 /dev/cpuset/background/cpus
chmod 644 /dev/cpuset/system-background/cpus
chmod 644 /dev/cpuset/foreground/cpus
chmod 644 /dev/cpuset/top-app/cpus

module_log "正在启动息屏降频功能..."

# 读取设置的检测周期
BASE_CHECK_INTERVAL=$(read_config "检测周期_" "3")
MAX_CHECK_INTERVAL=$(($BASE_CHECK_INTERVAL * 30)) # 最大检测间隔时间，单位为秒
CHECK_INTERVAL=$BASE_CHECK_INTERVAL

# 读取是否开启渐进周期的设置
ENABLE_GRADUAL=$(read_config "渐进周期_" "0")

# 获取 CPU 当前状态信息
CPU_MAX_FREQ=$(cat "/sys/devices/system/cpu/cpu3/cpufreq/cpuinfo_max_freq")
CPU_MIN_FREQ=$(cat "/sys/devices/system/cpu/cpu3/cpufreq/cpuinfo_min_freq")
BACKGROUND=$(cat "/dev/cpuset/background/cpus")
SYSTEM_BACKGROUND=$(cat "/dev/cpuset/system-background/cpus")
FOREGROUND=$(cat "/dev/cpuset/foreground/cpus")
SYSTEM_FOREGROUND=$(cat "/dev/cpuset/top-app/cpus")

# 打印
module_log "检测周期: $BASE_CHECK_INTERVAL"
module_log "最大检测周期: $MAX_CHECK_INTERVAL"
module_log "渐进周期启用: $ENABLE_GRADUAL"
module_log "CPU最大频率: $CPU_MAX_FREQ"
module_log "CPU最小频率: $CPU_MIN_FREQ"
module_log "后台进程CPU集: $BACKGROUND"
module_log "系统后台进程CPU集: $SYSTEM_BACKGROUND"
module_log "前台进程CPU集: $FOREGROUND"
module_log "系统前台进程CPU集: $SYSTEM_FOREGROUND"

# 定义函数设置CPU频率和CPU集分配
set_cpu_freq_and_cpusets() {
  local freq=$1
  local cpusets=$2
  echo $freq > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
  echo $cpusets > /dev/cpuset/background/cpus
  echo $cpusets > /dev/cpuset/system-background/cpus
  echo $cpusets > /dev/cpuset/foreground/cpus
  echo $cpusets > /dev/cpuset/top-app/cpus
  module_log "已设置频率到 $freq ，CPU集分配到 $cpusets"
}

# 使用 trap 捕获信号，确保脚本终止时恢复原始状态
trap "set_cpu_freq_and_cpusets $CPU_MAX_FREQ '0-$(($(get_cpu_cores) - 1))'; settings put global low_power 1; module_log '脚本终止，已恢复原始状态'; exit" SIGHUP SIGINT SIGTERM

# 初始化检测次数计数器
CHECK_COUNT=0

# 动态获取省电模式的CPU集
POWER_SAVE_CPUS=$(set_power_save_cpus)

while true; do
  SCREEN_STATUS=$(dumpsys display | grep mScreenState | awk -F '=' '{print $2}')
  module_log "屏幕状态: $SCREEN_STATUS"
  if [ "$SCREEN_STATUS" = "OFF" ]; then
    # 启用省电模式
    settings put global low_power 0
    module_log "已启用省电模式"

    # 降频到最低
    set_cpu_freq_and_cpusets $CPU_MIN_FREQ "$POWER_SAVE_CPUS"
    sleep $CHECK_INTERVAL
    
    if [ "$ENABLE_GRADUAL" = "0" ]; then
      CHECK_COUNT=$((CHECK_COUNT + 1))
      # 每检测5次增加一次检测间隔，直到达到最大间隔
      if [ $CHECK_COUNT -ge 5 ] && [ $CHECK_INTERVAL -lt $MAX_CHECK_INTERVAL ]; then
        CHECK_INTERVAL=$((CHECK_INTERVAL + BASE_CHECK_INTERVAL))
        CHECK_COUNT=0
      fi
    fi
  else
    # 退出省电模式
    settings put global low_power 1
    module_log "已退出省电模式"

    # 恢复到最大频率和原始CPU集分配
    set_cpu_freq_and_cpusets $CPU_MAX_FREQ "$BACKGROUND"
    set_cpu_freq_and_cpusets $CPU_MAX_FREQ "$SYSTEM_BACKGROUND"
    set_cpu_freq_and_cpusets $CPU_MAX_FREQ "$FOREGROUND"
    set_cpu_freq_and_cpusets $CPU_MAX_FREQ "$SYSTEM_FOREGROUND"
    sleep $BASE_CHECK_INTERVAL
    
    # 重置检测间隔和检测次数
    CHECK_INTERVAL=$BASE_CHECK_INTERVAL
    CHECK_COUNT=0
  fi
done