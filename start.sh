#!/system/bin/sh
DIR="/data/adb/modules/mihomo_tproxy"

# 1. Clean previous state
sh "$DIR/stop.sh" >/dev/null 2>&1

# 2. Add policy routes for Mihomo outbound packets (0x200000 = 2097152)
# Ensures core packets route directly out to physical network
ip rule add fwmark 0x200000 lookup wlan0 pref 90 2>/dev/null
ip rule add fwmark 0x200000 lookup rmnet_data0 pref 91 2>/dev/null
ip rule add fwmark 0x200000 lookup rmnet_data1 pref 92 2>/dev/null
ip rule add fwmark 0x200000 lookup rmnet_data2 pref 93 2>/dev/null

# 3. Launch Mihomo Core
nohup "$DIR/mihomo" -d "$DIR" > "$DIR/mihomo.log" 2>&1 &
PID=$!
echo $PID > "$DIR/mihomo.pid"

# 4. Port Listening Gateway (Wait up to 10s using /bin/ss)
READY=0
for i in $(seq 1 10); do
    if ! kill -0 $PID 2>/dev/null; then
        echo "[ERROR] Mihomo exited unexpectedly. Check $DIR/mihomo.log"
        sh "$DIR/stop.sh"
        exit 1
    fi
    if ss -tlpn 2>/dev/null | grep -q ":7892 "; then
        READY=1
        break
    fi
    sleep 1
done

if [ $READY -ne 1 ]; then
    echo "[ERROR] Port 7892 failed to open within 10s. Rolling back."
    sh "$DIR/stop.sh"
    exit 1
fi

# 5. Apply NAT Interception Chains
# --- TCP Transparent Proxy ---
iptables -t nat -N MIHOMO 2>/dev/null || iptables -t nat -F MIHOMO
iptables -t nat -A MIHOMO -m mark --mark 0x200000/0x200000 -j RETURN
iptables -t nat -A MIHOMO -d 0.0.0.0/8 -j RETURN
iptables -t nat -A MIHOMO -d 10.0.0.0/8 -j RETURN
iptables -t nat -A MIHOMO -d 127.0.0.0/8 -j RETURN
iptables -t nat -A MIHOMO -d 169.254.0.0/16 -j RETURN
iptables -t nat -A MIHOMO -d 172.16.0.0/12 -j RETURN
iptables -t nat -A MIHOMO -d 192.168.0.0/16 -j RETURN
iptables -t nat -A MIHOMO -d 224.0.0.0/4 -j RETURN
iptables -t nat -A MIHOMO -d 240.0.0.0/4 -j RETURN
iptables -t nat -A MIHOMO -p tcp -j REDIRECT --to-ports 7892

iptables -t nat -D PREROUTING -j MIHOMO 2>/dev/null
iptables -t nat -I PREROUTING 1 -j MIHOMO
iptables -t nat -D OUTPUT -j MIHOMO 2>/dev/null
iptables -t nat -I OUTPUT 1 -j MIHOMO

# --- DNS Interception (UDP/TCP 53 -> 1053) ---
iptables -t nat -N MIHOMO_DNS 2>/dev/null || iptables -t nat -F MIHOMO_DNS
iptables -t nat -A MIHOMO_DNS -m mark --mark 0x200000/0x200000 -j RETURN
iptables -t nat -A MIHOMO_DNS -p udp --dport 53 -j REDIRECT --to-ports 1053
iptables -t nat -A MIHOMO_DNS -p tcp --dport 53 -j REDIRECT --to-ports 1053

iptables -t nat -D PREROUTING -j MIHOMO_DNS 2>/dev/null
iptables -t nat -I PREROUTING 1 -j MIHOMO_DNS
iptables -t nat -D OUTPUT -j MIHOMO_DNS 2>/dev/null
iptables -t nat -I OUTPUT 1 -j MIHOMO_DNS

# --- Block QUIC (UDP 443) & DoT (TCP/UDP 853) to force fast HTTP/2 over TCP proxy ---
iptables -D OUTPUT -p udp --dport 443 -j REJECT 2>/dev/null
iptables -I OUTPUT 1 -p udp --dport 443 -j REJECT
iptables -D OUTPUT -p tcp --dport 853 -j REJECT 2>/dev/null
iptables -I OUTPUT 1 -p tcp --dport 853 -j REJECT
iptables -D OUTPUT -p udp --dport 853 -j REJECT 2>/dev/null
iptables -I OUTPUT 1 -p udp --dport 853 -j REJECT

# --- IPv6 Leak Prevention (Force IPv4 Fake-IP & Prevent IPv6 Direct Bypass) ---
ip6tables -D OUTPUT -p udp --dport 53 -j REJECT 2>/dev/null
ip6tables -I OUTPUT 1 -p udp --dport 53 -j REJECT
ip6tables -D OUTPUT -p tcp --dport 53 -j REJECT 2>/dev/null
ip6tables -I OUTPUT 1 -p tcp --dport 53 -j REJECT
ip6tables -D OUTPUT -p tcp --dport 853 -j REJECT 2>/dev/null
ip6tables -I OUTPUT 1 -p tcp --dport 853 -j REJECT
ip6tables -D OUTPUT -d 2000::/3 -j REJECT 2>/dev/null
ip6tables -I OUTPUT 1 -d 2000::/3 -j REJECT

# Launch Local Web Management Server (port 9092) for browsers
for bb in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox busybox; do
    if [ -x "$bb" ] || which "$bb" >/dev/null 2>&1; then
        killall httpd 2>/dev/null
        $bb httpd -p 127.0.0.1:9092 -h "$DIR/webroot" 2>/dev/null
        break
    fi
done

echo "[INFO] Mihomo transparent proxy started successfully (PID: $PID)."
