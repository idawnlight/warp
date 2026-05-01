#!/bin/bash
# entrypoint.sh

echo "Starting dbus..."
mkdir -p /run/dbus
rm -f /run/dbus/pid
dbus-daemon --system --nofork &
sleep 1

echo "Starting warp-svc..."
warp-svc &

# Give the daemon a few seconds to initialize
sleep 8

# Set up NAT Masquerading for the LAN gateway feature
echo "Configuring iptables NAT rule..."
iptables -t nat -A POSTROUTING -o CloudflareWARP -j MASQUERADE

echo "Starting gost..."
gost -L "http://:1080?udp=true" -L "socks5://:1081?udp=true" &

# Keep the container running
wait -n