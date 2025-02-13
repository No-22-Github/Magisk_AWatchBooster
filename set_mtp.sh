#!/system/bin/sh
# 设置 USB 协议为 MTP
while true; do
    current_config=$(getprop sys.usb.config)
    case "$current_config" in
        *mtp*) 
        *)    
            setprop sys.usb.config mtp
    esac
    sleep 10
done
