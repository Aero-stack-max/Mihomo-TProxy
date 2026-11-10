##########################################################################################
#
# Magisk / KernelSU / APatch Module Install Script
#
##########################################################################################

ui_print "**************************************************"
ui_print "       Mihomo 系统级透明代理 (全通用独立版)      "
ui_print "   - 纯内核透明接管 · 无感免钥匙 · 全局防 DNS 泄漏 -"
ui_print "**************************************************"

if [ "$ARCH" != "arm64" ]; then
    abort "! 本模块核心为 aarch64 (arm64) 架构，当前设备架构为: $ARCH，暂不支持。"
fi

ui_print "- 正在解压并部署模块运行环境..."
unzip -o "$ZIPFILE" -x 'META-INF/*' 'util_functions.sh' -d "$MODPATH" >&2

ui_print "- 正在配置系统安全权限与运行脚本..."
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/mihomo" 0 0 0755
set_perm "$MODPATH/start.sh" 0 0 0755
set_perm "$MODPATH/stop.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/update_sub.sh" 0 0 0755
set_perm "$MODPATH/webroot/cgi-bin/api.sh" 0 0 0755

mkdir -p "$MODPATH/proxy_providers"
set_perm_recursive "$MODPATH/proxy_providers" 0 0 0755 0644

ui_print "**************************************************"
ui_print "★ 模块安装成功！"
ui_print "使用指南："
ui_print "1. 安装后请重启手机；"
ui_print "2. 重启后点击 Magisk【操作】按钮，将自动打开管理面板；"
ui_print "3. 浏览器可随时访问: http://127.0.0.1:9092 导入订阅；"
ui_print "4. 节点切换仪表盘: http://127.0.0.1:9091/ui"
ui_print "**************************************************"
