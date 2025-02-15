MODDIR=${0%/*}
CONFIG_FILE="/storage/emulated/0/Android/AWatchBooster/config.yaml"

read_config() {
  local result=$(sed -n "s/^$1//p" "$CONFIG_FILE")
  echo ${result:-$2}
}

if [ ! -f "$CONFIG_FILE" ]; then
  echo "配置文件 ($CONFIG_FILE) 未找到！"
  exit 1
fi

echo "配置文件位于：$CONFIG_FILE"
echo "正在读取当前配置文件..."
sleep 0.3
# 读取 config.yaml 配置
# 获取 CPU 最大频率值
CPU_MAX_FREQ=$(read_config "频率限制_" "None")
# 获取性能模式
# 0: 性能优先
# 1: 均衡模式
# 2: 省电模式
PERFORMANCE=$(read_config "性能模式_" "None")
# 获取温控阈值
TEMP_THRESHOLD=$(read_config "温度控制_" "None")
# 获取 CPU 应用分配
BACKGROUND=$(read_config "用户后台应用_" "None")
SYSTEM_BACKGROUND=$(read_config "系统后台应用_" "None")
FOREGROUND=$(read_config "前台应用_" "None")
SYSTEM_FOREGROUND=$(read_config "上层应用_" "None")
# 模块日志输出
OPTIMIZE_MODULE=$(read_config "模块日志输出_" "None")
# 无线 ADB 调试
WIRELESS_ADB=$(read_config "无线ADB调试_" "None")
# ZRAM 设置
ZRAM_STATUS=$(read_config "ZRAM状态_" "None")
# 息屏降频省电功能
POWER_SAVE=$(read_config "息屏降频_" "None")
# 读取是否开启渐进周期的设置
ENABLE_GRADUAL=$(read_config "渐进增加_" "0")

# 读取是否开启延迟唤醒和延迟的时间
DELAYED_WEAKUP=$(read_config "延迟唤醒_" "1")
DELAY_TIME=$(read_config "延迟时间_" "5")

# 读取设置的检测周期
BASE_CHECK_INTERVAL=$(read_config "检测周期_" "5")
MAGNIFICATION=$(read_config "最大倍率_" "50")
MAX_CHECK_INTERVAL=$(($BASE_CHECK_INTERVAL * $MAGNIFICATION)) # 最大检测间隔时间，单位为秒

# 设置USB为MTP协议
USB_MTP=$(read_config "设置USB为MTP_" "None")


echo "读取完毕！解析中..."
echo "当前 AWatchBooster 策略："
echo "--------------------------------"
case $CPU_MAX_FREQ in
    "None")
        echo "未匹配到频率限制配置项"
        ;;
    "1")
        echo "已禁用 CPU 频率限制"
        ;;
    *)
        echo "当前 CPU 频率限制为：$CPU_MAX_FREQ MHz"
        ;;
esac

case $PERFORMANCE in
    "None")
        echo "未匹配到性能模式配置项"
        ;;
    "0")
        echo "当前性能模式：性能优先"
        ;;
    "1")
        echo "当前性能模式：均衡模式"
        ;;
    "2")
        echo "当前性能模式：省电模式"
        ;;
    *)
        echo "性能模式配置项异常，当前值为：$PERFORMANCE"
        ;;
esac

case $TEMP_THRESHOLD in
    "None")
        echo "未匹配到温控阈值配置项"
        ;;
    *)
        echo "当前温控阈值为：$TEMP_THRESHOLD°C"
        ;;
esac

case $BACKGROUND in
    "None")
        echo "未匹配到用户后台应用配置项"
        ;;
    *)
        echo "用户后台核心分配：$BACKGROUND"
        ;;
esac

# 系统后台应用
case $SYSTEM_BACKGROUND in
    "None")
        echo "未匹配到系统后台应用配置项"
        ;;
    *)
        echo "系统后台核心分配：$SYSTEM_BACKGROUND"
        ;;
esac

# 前台应用
case $FOREGROUND in
    "None")
        echo "未匹配到前台应用配置项"
        ;;
    *)
        echo "前台应用核心分配：$FOREGROUND"
        ;;
esac

# 上层应用
case $SYSTEM_FOREGROUND in
    "None")
        echo "未匹配到上层应用配置项"
        ;;
    *)
        echo "上层应用核心分配：$SYSTEM_FOREGROUND"
        ;;
esac

# 模块日志输出
case $OPTIMIZE_MODULE in
    "None")
        echo "未匹配到模块日志输出配置项"
        ;;
    "0")
        echo "模块日志输出已开启"
        ;;
    "1")
        echo "模块日志输出已禁用"
        ;;
    *)
        echo "模块日志输出配置项异常，当前值为：$OPTIMIZE_MODULE"
        ;;
esac

# 无线 ADB 调试
case $WIRELESS_ADB in
    "None")
        echo "未匹配到无线 ADB 调试配置项"
        ;;
    "0")
        echo "无线 ADB 调试已开启"
        ;;
    "1")
        echo "无线 ADB 调试已禁用"
        ;;
    *)
        echo "无线 ADB 调试配置项异常，当前值为：$WIRELESS_ADB"
        ;;
esac

# ZRAM 设置
case $ZRAM_STATUS in
    "None")
        echo "未匹配到 ZRAM 状态配置项"
        ;;
    "0")
        echo "ZRAM 已禁用"
        ;;
    "1")
        echo "ZRAM 已启用，由系统管理"
        ;;
    *)
        echo "ZRAM 状态配置项异常，当前值为：$ZRAM_STATUS"
        ;;
esac

# 息屏降频省电功能
case $POWER_SAVE in
    "None")
        echo "未匹配到息屏降频省电功能配置项"
        ;;
    "0")
        echo "息屏降频省电功能已开启"
        ;;
    "1")
        echo "息屏降频省电功能已禁用"
        ;;
    *)
        echo "息屏降频省电功能配置项异常，当前值为：$POWER_SAVE"
        ;;
esac
# 检测周期配置项判断
case $BASE_CHECK_INTERVAL in
    "None")
        echo "--未匹配到基础检测周期配置项"
        ;;
    *)
        echo "--基础检测周期：$BASE_CHECK_INTERVAL 秒"
        ;;
esac
# 渐进增加
case $ENABLE_GRADUAL in
    "0")
        echo "--渐进增加未启用"
        ;;
    "1")
        echo "--渐进增加已启用"
        # 最大倍率配置项判断
        case $MAGNIFICATION in
            "None")
                echo "--未匹配到最大倍率配置项"
                ;;
            *)
                echo "--最大倍率：$MAGNIFICATION"
                ;;
        esac
        echo "--最大检测间隔：$MAX_CHECK_INTERVAL 秒"
        ;;
    *)
        echo "--渐进增加配置项异常，当前值为：$ENABLE_GRADUAL"
        ;;
esac

# 延迟唤醒设置
case $DELAYED_WEAKUP in
    "0")
        echo "延迟唤醒已禁用"
        ;;
    "1")
        echo "延迟唤醒已启用"
        echo "延迟时间：$DELAY_TIME 秒"
        ;;
    *)
        echo "延迟唤醒配置项异常，当前值为：$DELAYED_WEAKUP"
        ;;
esac

# 设置 USB 为 MTP 协议
case $USB_MTP in
    "None")
        echo "未匹配到 USB 设置为 MTP 协议配置项"
        ;;
    "0")
        echo "USB 已设置为 MTP 协议"
        ;;
    "1")
        echo "USB 未设置为 MTP 协议"
        ;;
    *)
        echo "USB 设置为 MTP 协议配置项异常，当前值为：$USB_MTP"
        ;;
esac

echo "--------------------------------"
echo "配置解析完成！"