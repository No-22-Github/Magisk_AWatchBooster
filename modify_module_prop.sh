# 获取当前时间
current_time=$(date "+%Y-%m-%d %H:%M:%S")

# 在模块启动时删除之前的标记
sed -i "s/\[.*🚀优化完毕\]//" $MODPATH/module.prop

# 修改description，添加结束时间
sed -i "s/^description=.*/& \[${current_time}🚀优化完毕\]/" $MODPATH/module.prop