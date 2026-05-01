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

# Keep the container running
wait -n