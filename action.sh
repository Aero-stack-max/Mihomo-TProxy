#!/system/bin/sh
DIR="${0%/*}"
[ -z "$DIR" ] && DIR="/data/adb/modules/mihomo_tproxy"

echo "=================================================="
echo "    Mihomo 系统级透明代理 (Magisk 快捷管理)      "
echo "=================================================="

# 1. 自动检测 /sdcard/sub.txt (免网页极简导入法)
if [ -f "/sdcard/sub.txt" ]; then
    SD_URL=$(cat /sdcard/sub.txt | head -n 1 | tr -d '\r\n')
    case "$SD_URL" in
        http://*|https://*)
            echo "[-] 检测到 /sdcard/sub.txt 中的订阅链接，正在自动导入..."
            sh "$DIR/update_sub.sh" "$SD_URL"
            echo "[✓] 已成功从 /sdcard/sub.txt 导入并生效！"
            exit 0
            ;;
    esac
fi

# 2. 如果已安装 WebUI X 组件，直接唤起专属窗口
if pm path com.dergoogler.mmrl.wx >/dev/null 2>&1; then
    echo "[-] 正在唤起 WebUI X 图形管理界面..."
    am start -n "com.dergoogler.mmrl.wx/.ui.activity.webui.WebUIActivity" -e MOD_ID "mihomo_tproxy" >/dev/null 2>&1
    echo "[✓] 图形界面已唤起！点击输入框即可弹出输入法软键盘。"
    exit 0
fi

# 3. 未安装 WebUI X：自动打开手机默认浏览器直达本地管理面板 (100% 支持输入法弹起)
echo "[-] 未安装 WebUI X，正在自动调起手机浏览器打开管理面板..."
am start -a android.intent.action.VIEW -d "http://127.0.0.1:9092" >/dev/null 2>&1
echo "[✓] 已在手机浏览器中打开管理面板: http://127.0.0.1:9092"
echo "    提示: 在浏览器输入框中点击即可弹出软键盘，长按粘贴订阅后点击更新即可！"
exit 0
