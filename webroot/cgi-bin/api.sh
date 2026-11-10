#!/system/bin/sh
MODDIR="/data/adb/modules/mihomo_tproxy"
[ -z "$MODDIR" ] || [ "$MODDIR" = "." ] && MODDIR="/data/adb/modules/mihomo_tproxy"

echo "Content-Type: application/json; charset=utf-8"
echo "Access-Control-Allow-Origin: *"
echo ""

urldecode() {
    echo -e "$(echo "$1" | sed 's/+/ /g;s/%\(..\)/\\x\1/g')"
}

ACTION=$(echo "$QUERY_STRING" | sed -n 's/.*action=\([^&]*\).*/\1/p')

case "$ACTION" in
    status)
        RUNNING="false"
        PID=""
        if [ -f "$MODDIR/mihomo.pid" ] && kill -0 $(cat "$MODDIR/mihomo.pid" 2>/dev/null) 2>/dev/null; then
            RUNNING="true"
            PID=$(cat "$MODDIR/mihomo.pid")
        fi
        
        SAVED_SUB=""
        [ -f "$MODDIR/sub.url" ] && SAVED_SUB=$(cat "$MODDIR/sub.url" | tr -d '\r\n')
        
        echo "{\"running\":$RUNNING,\"pid\":\"$PID\",\"sub\":\"$SAVED_SUB\"}"
        ;;
    update)
        RAW_URL=$(echo "$QUERY_STRING" | sed -n 's/.*url=\([^&]*\).*/\1/p')
        DEC_URL=$(urldecode "$RAW_URL")
        
        OUTPUT=$(sh "$MODDIR/update_sub.sh" "$DEC_URL" 2>&1)
        CODE=$?
        ESCAPED=$(echo "$OUTPUT" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')
        echo "{\"errno\":$CODE,\"output\":\"$ESCAPED\"}"
        ;;
    refresh)
        OUTPUT=$(sh "$MODDIR/update_sub.sh" 2>&1)
        CODE=$?
        ESCAPED=$(echo "$OUTPUT" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')
        echo "{\"errno\":$CODE,\"output\":\"$ESCAPED\"}"
        ;;
    restart)
        sh "$MODDIR/start.sh" >/dev/null 2>&1
        echo "{\"errno\":0,\"output\":\"透明代理核心已重启\"}"
        ;;
    stop)
        sh "$MODDIR/stop.sh" >/dev/null 2>&1
        echo "{\"errno\":0,\"output\":\"透明代理已停止，已恢复系统直连\"}"
        ;;
    *)
        echo "{\"error\":\"Invalid action\"}"
        ;;
esac
