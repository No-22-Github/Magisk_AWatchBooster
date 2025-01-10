#!/bin/bash

# 检查是否具有 root 权限
if [ "$EUID" -ne 0 ]; then
  echo "错误：此脚本需要 root 权限。请使用 sudo 或以 root 用户身份运行此脚本。"
  exit 1
fi

# 检查权限
if [ ! -r /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies ]; then
  echo "错误：无法读取 CPU 频率调节文件。"
  exit 1
fi

if [ ! -w /storage/emulated/0/Android/AWatchBooster/config.yaml ]; then
  echo "错误：无法写入目标 YAML 文件。"
  exit 1
fi

# 获取 CPU 可用频率档，单位为 kHz
frequencies_khz=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies)
if [ $? -ne 0 ]; then
  echo "错误：读取 CPU 频率调节文件失败。"
  exit 1
fi

# 创建或清空临时文件
temp_yaml=$(mktemp)
if [ $? -ne 0 ]; then
  echo "错误：创建临时文件失败。"
  exit 1
fi

# 将频率值转换为 MHz 并输出到临时文件
for freq in $frequencies_khz; do
  freq_mhz=$((freq / 1000))
  echo "  - ${freq_mhz} MHz" >> "$temp_yaml"
done

# 将频率信息插入到目标 YAML 文件的 frequencies 字段
sed -i '/可用频率档位:/r '"$temp_yaml"'' /storage/emulated/0/Android/AWatchBooster/config.yaml
if [ $? -ne 0 ]; then
  echo "错误：插入频率信息到 YAML 文件失败。"
  rm "$temp_yaml"
  exit 1
fi

# 删除临时文件
rm "$temp_yaml"
if [ $? -ne 0 ]; then
  echo "错误：删除临时文件失败。"
  exit 1
fi

echo "成功：CPU 频率信息已成功更新，请在配置文件里查看。"