# 息屏降频 省电模式
# 获取脚本路径
MODDIR=${0%/*}
# 定义配置文件路径和日志文件路径
CONFIG_FILE="/storage/emulated/0/Android/AWatchBooster/config.yaml"
LOG_FILE="/storage/emulated/0/Android/AWatchBooster/config.yaml.log"

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

DEBUG_STATUS=$(read_config "开启Debug输出_" "1" )
# 定义 module_log 输出日志函数
module_log() {
  echo "[$(date '+%m-%d %H:%M:%S')] $1" >> $LOG_FILE
  if [ "$DEBUG_STATUS" = "0" ]; then
    echo "[$(date '+%m-%d %H:%M:%S')] $1" # for debug
  fi
}
module_log "正在启动息屏降频功能..."
sleep 30
# 获取CPU核数，设置省电模式CPU分配
POWER_SAVE_CPUS="0-$(($(grep -c ^processor /proc/cpuinfo) - 1))"

# 修改权限为644
chmod 644 /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
chmod 644 /dev/cpuset/background/cpus
chmod 644 /dev/cpuset/system-background/cpus
chmod 644 /dev/cpuset/foreground/cpus
chmod 644 /dev/cpuset/top-app/cpus

# 读取是否开启渐进周期的设置
ENABLE_GRADUAL=$(read_config "渐进增加_" "0")

# 读取是否开启延迟唤醒和延迟的时间
DELAYED_WEAKUP=$(read_config "延迟唤醒_" "1")
DELAY_TIME=$(read_config "延迟时间_" "5")

# 读取设置的检测周期
BASE_CHECK_INTERVAL=$(read_config "检测周期_" "5")
MAGNIFICATION=$(read_config "最大倍率_" "50")
MAX_CHECK_INTERVAL=$(($BASE_CHECK_INTERVAL * $MAGNIFICATION)) # 最大检测间隔时间，单位为秒
CHECK_INTERVAL=$BASE_CHECK_INTERVAL

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
module_log "延迟唤醒启用: $DELAYED_WEAKUP"
module_log "延迟唤醒时间: $DELAY_TIME"
module_log "CPU最大频率: $CPU_MAX_FREQ"
module_log "CPU最小频率: $CPU_MIN_FREQ"
module_log "后台进程CPU集: $BACKGROUND"
module_log "系统后台进程CPU集: $SYSTEM_BACKGROUND"
module_log "前台进程CPU集: $FOREGROUND"
module_log "系统前台进程CPU集: $SYSTEM_FOREGROUND"

# 初始化检测次数计数器
CHECK_COUNT=0
# 初始化延迟次数计数器
DELAY_COUNT=1
while true; do
  SCREEN_STATUS=$(dumpsys display | grep mScreenState | awk -F '=' '{print $2}')
  module_log "屏幕状态: $SCREEN_STATUS"
  if [ "$SCREEN_STATUS" = "OFF" ]; then
    
    module_log "启用息屏降频省电模式..."
    # 降频到最低
    echo $CPU_MIN_FREQ > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
    module_log "设置CPU核心分配 $POWER_SAVE_CPUS"
    echo $POWER_SAVE_CPUS > /dev/cpuset/background/cpus
    echo $POWER_SAVE_CPUS > /dev/cpuset/system-background/cpus
    echo $POWER_SAVE_CPUS > /dev/cpuset/foreground/cpus
    echo $POWER_SAVE_CPUS > /dev/cpuset/top-app/cpus
    sleep $CHECK_INTERVAL
    DELAY_COUNT=0
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
    module_log "退出息屏降频省电模式..."
    
    if [ "$DELAYED_WEAKUP" = "0" ] && [ "$DELAY_COUNT" = "0" ]; then
      module_log "启用延迟唤醒..."
      module_log "等待 $DELAY_TIME 秒"
      # 启用延迟唤醒
      sleep $DELAY_TIME
      SCREEN_STATUS=$(dumpsys display | grep mScreenState | awk -F '=' '{print $2}')
      module_log "屏幕状态: $SCREEN_STATUS"
      if [ "$SCREEN_STATUS" = "ON" ]; then
        # 恢复到最大频率和原始CPU集分配
        echo $CPU_MAX_FREQ > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
        module_log "恢复到最大频率和原始CPU集分配"
        echo $BACKGROUND > /dev/cpuset/background/cpus
        echo $SYSTEM_BACKGROUND > /dev/cpuset/system-background/cpus
        echo $FOREGROUND > /dev/cpuset/foreground/cpus
        echo $SYSTEM_FOREGROUND > /dev/cpuset/top-app/cpus
        sleep $BASE_CHECK_INTERVAL    
        # 重置检测间隔和检测次数
        CHECK_INTERVAL=$BASE_CHECK_INTERVAL
        CHECK_COUNT=0
        DELAY_COUNT=1
      fi
    else
      # 恢复到最大频率和原始CPU集分配
      echo $CPU_MAX_FREQ > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
      module_log "恢复到最大频率和原始CPU集分配"
      echo $BACKGROUND > /dev/cpuset/background/cpus
      echo $SYSTEM_BACKGROUND > /dev/cpuset/system-background/cpus
      echo $FOREGROUND > /dev/cpuset/foreground/cpus
      echo $SYSTEM_FOREGROUND > /dev/cpuset/top-app/cpus
      sleep $BASE_CHECK_INTERVAL    
      # 重置检测间隔和检测次数
      CHECK_INTERVAL=$BASE_CHECK_INTERVAL
      CHECK_COUNT=0
    fi
  fi
done
# 使用 trap 捕获信号，确保脚本终止时恢复原始状态
trap "
  echo $CPU_MAX_FREQ > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
  echo $BACKGROUND > /dev/cpuset/background/cpus
  echo $SYSTEM_BACKGROUND > /dev/cpuset/system-background/cpus
  echo $FOREGROUND > /dev/cpuset/foreground/cpus
  echo $SYSTEM_FOREGROUND > /dev/cpuset/top-app/cpus
  settings put global low_power 1
  module_log '脚本终止，已恢复原始状态'
  exit
" SIGHUP SIGINT SIGTERM