#!/system/bin/sh
DIR="/data/adb/modules/mihomo_tproxy"
LOG="$DIR/service.log"

exec > "$LOG" 2>&1

echo "=== Boot service started at $(date) ==="

# 1. Wait for Android boot completed
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done
echo "[INFO] sys.boot_completed detected."

# 2. Wait for physical network to be ready (up to 30s)
NET_READY=0
for i in $(seq 1 15); do
    if ping -c 1 -W 2 223.5.5.5 >/dev/null 2>&1 || ping -c 1 -W 2 119.29.29.29 >/dev/null 2>&1; then
        NET_READY=1
        echo "[INFO] Physical network connectivity confirmed."
        break
    fi
    sleep 2
done

if [ $NET_READY -ne 1 ]; then
    echo "[WARN] Physical network wait timeout. Continuing startup."
fi

# Extra 2s stabilization for netd/dhcp
sleep 2

# 3. Mount /data/adb to Debian chroot for subscription automation
mkdir -p /data/local/debian/mnt/adb 2>/dev/null
mountpoint -q /data/local/debian/mnt/adb 2>/dev/null || mount --bind /data/adb /data/local/debian/mnt/adb 2>/dev/null

# 4. Suppress conflicting Android Clash App if running
am force-stop com.github.metacubex.clash.meta 2>/dev/null

# 5. Launch Mihomo Transparent Proxy
sh "$DIR/start.sh"

# 6. Boot health verification (test direct connectivity)
sleep 2
if ! ping -c 1 -W 3 223.5.5.5 >/dev/null 2>&1 && ! ping -c 1 -W 3 119.29.29.29 >/dev/null 2>&1; then
    echo "[ALERT] Boot network check failed! Triggering safety rollback..."
    sh "$DIR/stop.sh"
    echo "[ALERT] Safe rollback finished. Normal direct network preserved."
    exit 1
fi

echo "[INFO] Mihomo transparent proxy boot initialization 100% healthy."
