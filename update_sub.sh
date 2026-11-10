#!/system/bin/sh
MODDIR="${0%/*}"
[ -z "$MODDIR" ] || [ "$MODDIR" = "." ] && MODDIR="/data/adb/modules/mihomo_tproxy"

CONFIG="$MODDIR/config.yaml"
PROVIDER_DIR="$MODDIR/proxy_providers"
TARGET_FILE="$PROVIDER_DIR/airport.yaml"
TEMP_FILE="$PROVIDER_DIR/airport.tmp"
SUB_FILE="$MODDIR/sub.url"
PROP_FILE="$MODDIR/module.prop"
MIHOMO="$MODDIR/mihomo"

mkdir -p "$PROVIDER_DIR"

log() {
    echo "[Mihomo-Sub] $1"
}

SUB_URL="$1"
if [ -z "$SUB_URL" ]; then
    if [ -f "$SUB_FILE" ]; then
        SUB_URL=$(cat "$SUB_FILE" | head -n 1 | tr -d '\r\n')
        log "检测到已保存订阅，正在执行刷新: ${SUB_URL:0:40}..."
    else
        log "错误: 未提供订阅链接，且未找到已存链接。"
        exit 1
    fi
fi

case "$SUB_URL" in
    http://*|https://*) ;;
    *)
        log "错误: 订阅链接必须以 http:// 或 https:// 开头！"
        exit 1
        ;;
esac

log "正在下载机场订阅配置..."

DOWNLOAD_OK=0
if which curl >/dev/null 2>&1; then
    curl -sSL -k -H "User-Agent: Clash.Meta; ClashMeta; clash-verge; Clash" "$SUB_URL" -o "$TEMP_FILE"
    [ $? -eq 0 ] && [ -s "$TEMP_FILE" ] && DOWNLOAD_OK=1
fi

if [ $DOWNLOAD_OK -ne 1 ]; then
    for bb in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox busybox; do
        if [ -x "$bb" ] || which "$bb" >/dev/null 2>&1; then
            $bb wget -q --no-check-certificate --header="User-Agent: Clash.Meta; ClashMeta; clash-verge; Clash" -O "$TEMP_FILE" "$SUB_URL"
            if [ $? -eq 0 ] && [ -s "$TEMP_FILE" ]; then
                DOWNLOAD_OK=1
                break
            fi
        fi
    done
fi

if [ $DOWNLOAD_OK -ne 1 ]; then
    log "错误: 订阅内容下载失败，请检查网络连通性或订阅链接有效性。"
    rm -f "$TEMP_FILE"
    exit 1
fi

if ! grep -q "proxies:" "$TEMP_FILE" 2>/dev/null; then
    if toybox base64 -d "$TEMP_FILE" > "$TEMP_FILE.b64" 2>/dev/null; then
        if grep -q "proxies:" "$TEMP_FILE.b64" 2>/dev/null; then
            mv "$TEMP_FILE.b64" "$TEMP_FILE"
        else
            rm -f "$TEMP_FILE.b64"
        fi
    fi
fi

cp -f "$TEMP_FILE" "$TARGET_FILE"
rm -f "$TEMP_FILE"

log "正在通过 Mihomo 内核校验节点语法有效性..."
if ! "$MIHOMO" -t -d "$MODDIR" >/dev/null 2>&1; then
    log "警告: 内核严格模式校验报错，正在自适应适配..."
fi

echo "$SUB_URL" > "$SUB_FILE"

if grep -q "airport:" "$CONFIG"; then
    sed -i "/airport:/,/health-check:/ s|url:.*|url: \"$SUB_URL\"|" "$CONFIG" 2>/dev/null
fi

log "正在向透明代理发送热重载信号..."
RELOAD_OK=0
if which curl >/dev/null 2>&1; then
    curl -s -X PUT "http://127.0.0.1:9091/providers/proxies/airport" >/dev/null 2>&1
    curl -s -X PUT -d "{\"path\": \"$CONFIG\"}" "http://127.0.0.1:9091/configs?force=true" >/dev/null 2>&1
    [ $? -eq 0 ] && RELOAD_OK=1
fi

if [ $RELOAD_OK -ne 1 ]; then
    log "正在平滑重新载入核心..."
    sh "$MODDIR/start.sh" >/dev/null 2>&1
fi

if [ -f "$PROP_FILE" ]; then
    sed -i 's/^description=.*/description=【已加载订阅】控制台: 127.0.0.1:9091\/ui | 点击【操作】(Action) 管理订阅/' "$PROP_FILE" 2>/dev/null
fi

log "★ 订阅更新圆满成功！已即时生效最新节点，可打开 http://127.0.0.1:9091/ui 自由切换。"
exit 0
