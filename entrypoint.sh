#!/bin/bash
# entrypoint.sh

echo "Starting warp-svc..."
warp-svc &

# Give the daemon a few seconds to initialize
sleep 3

# Check if environment variables are provided
if [ -n "$CF_TEAM_NAME" ] && [ -n "$CF_CLIENT_ID" ] && [ -n "$CF_CLIENT_SECRET" ]; then
    # Check if already registered by looking for the team name in the account output
    if ! warp-cli --accept-tos account | grep -q "$CF_TEAM_NAME"; then
        echo "No existing registration found. Enrolling via Service Token..."
        warp-cli --accept-tos registration new "$CF_TEAM_NAME" --client-id "$CF_CLIENT_ID" --client-secret "$CF_CLIENT_SECRET"
        sleep 2
        warp-cli --accept-tos connect
    else
        echo "Device is already enrolled in Zero Trust."
    fi
else
    echo "Warning: Service Token variables are missing. Skipping auto-enrollment."
fi

# Set up NAT Masquerading for the LAN gateway feature
echo "Configuring iptables NAT rule..."
iptables -t nat -A POSTROUTING -o CloudflareWARP -j MASQUERADE

# Keep the container running
wait -n