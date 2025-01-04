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
# 读取设置的检测周期
CHECK_INTERVAL=$(read_config "检测周期_" "3")
CPU_MAX_FREQ=$(cat "/sys/devices/system/cpu/cpu3/cpufreq/cpuinfo_max_freq")
CPU_MIN_FREQ=$(cat "/sys/devices/system/cpu/cpu3/cpufreq/cpuinfo_min_freq")
BACKGROUND=$(cat "/dev/cpuset/background/cpus")
SYSTEM_BACKGROUND=$(cat "/dev/cpuset/system-background/cpus")
FOREGROUND=$(cat "/dev/cpuset/foreground/cpus")
SYSTEM_FOREGROUND=$(cat "/dev/cpuset/top-app/cpus")
while true; do
  SCREEN_STATUS=$(dumpsys display | grep mScreenState | awk -F '=' '{print $2}')
  if [ "$SCREEN_STATUS" = "ON" ]; then
    # 息屏降频
    sleep $CHECK_INTERVAL
  else
    # 亮屏恢复
    sleep $CHECK_INTERVAL
  fi
done