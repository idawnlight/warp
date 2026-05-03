#!/bin/bash
# entrypoint.sh

set -e

LAN_INTERFACE="${LAN_INTERFACE:-eth0}"
WARP_INTERFACE="${WARP_INTERFACE:-CloudflareWARP}"
ENABLE_IPV6_LAN="${ENABLE_IPV6_LAN:-false}"
SLAAC_PREFIX="${SLAAC_PREFIX:-fd42:5741:5250::/64}"
SLAAC_ADDRESS="${SLAAC_ADDRESS:-fd42:5741:5250::1/64}"
SLAAC_RDNSS="${SLAAC_RDNSS:-}"

is_enabled() {
	case "${1,,}" in
		1|true|yes|on) return 0 ;;
		*) return 1 ;;
	esac
}

add_iptables_rule() {
	local table="$1"
	shift

	if ! iptables -t "$table" -C "$@" 2>/dev/null; then
		iptables -t "$table" -A "$@"
	fi
}

add_ip6tables_rule() {
	local table="$1"
	shift

	if ! ip6tables -t "$table" -C "$@" 2>/dev/null; then
		ip6tables -t "$table" -A "$@"
	fi
}

configure_slaac_address() {
	echo "Configuring ${SLAAC_ADDRESS} on ${LAN_INTERFACE}..."
	ip link set dev "$LAN_INTERFACE" up

	if ip -6 addr add "$SLAAC_ADDRESS" dev "$LAN_INTERFACE" 2>/tmp/slaac-ip.err; then
		rm -f /tmp/slaac-ip.err
		return
	fi

	if grep -q "File exists" /tmp/slaac-ip.err; then
		rm -f /tmp/slaac-ip.err
		return
	fi

	cat /tmp/slaac-ip.err >&2
	rm -f /tmp/slaac-ip.err
	exit 1
}

write_radvd_config() {
	{
		printf 'interface %s\n' "$LAN_INTERFACE"
		printf '{\n'
		printf '    AdvSendAdvert on;\n'
		printf '    AdvManagedFlag off;\n'
		printf '    AdvOtherConfigFlag off;\n'
		printf '    MinRtrAdvInterval 3;\n'
		printf '    MaxRtrAdvInterval 10;\n'
		printf '    AdvDefaultLifetime 1800;\n'
		printf '    prefix %s\n' "$SLAAC_PREFIX"
		printf '    {\n'
		printf '        AdvOnLink on;\n'
		printf '        AdvAutonomous on;\n'
		printf '        AdvRouterAddr on;\n'
		printf '    };\n'

		if [ -n "$SLAAC_RDNSS" ]; then
			printf '    RDNSS %s\n' "$SLAAC_RDNSS"
			printf '    {\n'
			printf '    };\n'
		fi

		printf '};\n'
	} > /etc/radvd.conf
}

start_ipv6_lan() {
	echo "Enabling IPv6 forwarding..."

	configure_slaac_address

	echo "Configuring ip6tables NAT6 rule..."
	add_ip6tables_rule nat POSTROUTING -o "$WARP_INTERFACE" -j MASQUERADE

	echo "Applying IPv6 TCP MSS Clamping..."
	add_ip6tables_rule mangle FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

	echo "Starting radvd for ${SLAAC_PREFIX} on ${LAN_INTERFACE}..."
	mkdir -p /run/radvd
	write_radvd_config
	radvd -n -C /etc/radvd.conf &
}

echo "Starting dbus..."
mkdir -p /run/dbus
rm -f /run/dbus/pid
dbus-daemon --system --nofork &
sleep 1

echo "Starting warp-svc..."
warp-svc &

# Set up NAT Masquerading for the LAN gateway feature
echo "Configuring iptables NAT rule..."
add_iptables_rule nat POSTROUTING -o "$WARP_INTERFACE" -j MASQUERADE

# Force TCP packets to adapt to the WARP MTU to prevent fragmentation
echo "Applying TCP MSS Clamping..."
add_iptables_rule mangle FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

if is_enabled "$ENABLE_IPV6_LAN"; then
	start_ipv6_lan
else
	echo "IPv6 SLAAC/NAT6 disabled. Set ENABLE_IPV6_LAN=true to enable it."
fi

echo "Starting gost..."
gost -L "http://:1080?udp=true" -L "socks5://:1081?udp=true" &

# Keep the container running
wait -n