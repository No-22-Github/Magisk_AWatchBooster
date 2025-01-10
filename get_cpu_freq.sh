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