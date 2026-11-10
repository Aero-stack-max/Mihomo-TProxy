#!/system/bin/sh
DIR="/data/adb/modules/mihomo_tproxy"

# 1. Clean NAT chains
iptables -t nat -D PREROUTING -j MIHOMO 2>/dev/null
iptables -t nat -D OUTPUT -j MIHOMO 2>/dev/null
iptables -t nat -F MIHOMO 2>/dev/null
iptables -t nat -X MIHOMO 2>/dev/null

iptables -t nat -D PREROUTING -j MIHOMO_DNS 2>/dev/null
iptables -t nat -D OUTPUT -j MIHOMO_DNS 2>/dev/null
iptables -t nat -F MIHOMO_DNS 2>/dev/null
iptables -t nat -X MIHOMO_DNS 2>/dev/null

# 2. Clean QUIC & DoT reject rules
iptables -D OUTPUT -p udp --dport 443 -j REJECT 2>/dev/null
iptables -D OUTPUT -p tcp --dport 853 -j REJECT 2>/dev/null
iptables -D OUTPUT -p udp --dport 853 -j REJECT 2>/dev/null

# 3. Clean IPv6 leak prevention rules
ip6tables -D OUTPUT -p udp --dport 53 -j REJECT 2>/dev/null
ip6tables -D OUTPUT -p tcp --dport 53 -j REJECT 2>/dev/null
ip6tables -D OUTPUT -p tcp --dport 853 -j REJECT 2>/dev/null
ip6tables -D OUTPUT -d 2000::/3 -j REJECT 2>/dev/null

# 4. Clean legacy Mangle chains
iptables -t mangle -D PREROUTING -j MIHOMO 2>/dev/null
iptables -t mangle -D OUTPUT -j MIHOMO_OUT 2>/dev/null
iptables -t mangle -F MIHOMO 2>/dev/null
iptables -t mangle -X MIHOMO 2>/dev/null
iptables -t mangle -F MIHOMO_OUT 2>/dev/null
iptables -t mangle -X MIHOMO_OUT 2>/dev/null

# 5. Clean routing rules
ip rule del fwmark 0x200000 lookup wlan0 pref 90 2>/dev/null
ip rule del fwmark 0x200000 lookup rmnet_data0 pref 91 2>/dev/null
ip rule del fwmark 0x200000 lookup rmnet_data1 pref 92 2>/dev/null
ip rule del fwmark 0x200000 lookup rmnet_data2 pref 93 2>/dev/null
ip rule del fwmark 0x1/0x1 lookup 100 pref 100 2>/dev/null
ip rule del fwmark 1 lookup 100 2>/dev/null
ip route flush table 100 2>/dev/null

# 6. Terminate process
if [ -f "$DIR/mihomo.pid" ]; then
    PID=$(cat "$DIR/mihomo.pid" 2>/dev/null)
    [ -n "$PID" ] && kill -9 $PID 2>/dev/null
fi
killall -9 mihomo 2>/dev/null
killall httpd 2>/dev/null
rm -f "$DIR/mihomo.pid" /tmp/tproxy_live_ok

echo "[INFO] Mihomo transparent proxy stopped and cleaned."
