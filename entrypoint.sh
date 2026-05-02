#!/bin/bash
# entrypoint.sh

echo "Starting dbus..."
mkdir -p /run/dbus
rm -f /run/dbus/pid
dbus-daemon --system --nofork &
sleep 1

echo "Starting warp-svc..."
warp-svc &

# Set up NAT Masquerading for the LAN gateway feature
echo "Configuring iptables NAT rule..."
iptables -t nat -A POSTROUTING -o CloudflareWARP -j MASQUERADE

# Force TCP packets to adapt to the WARP MTU to prevent fragmentation
echo "Applying TCP MSS Clamping..."
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

echo "Starting gost..."
gost -L "http://:1080?udp=true" -L "socks5://:1081?udp=true" &

# Keep the container running
wait -n