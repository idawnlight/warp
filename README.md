# warp

Dockerized Cloudflare WARP client with [gost](https://github.com/go-gost/gost) proxy.

## Features

- Cloudflare WARP / Zero Trust / One with NAT masquerading
- Optional IPv6 SLAAC with `radvd` and NAT6/NAT66 through WARP
- HTTP proxy on port `1080`, SOCKS5 proxy on port `1081` (UDP supported)
- Multi-arch: `linux/amd64` and `linux/arm64`
- Weekly automated builds via GitHub Actions

## Quick Start

```sh
cp warp.env.example warp.env
vim warp.env

docker network create -d macvlan \
    --subnet=192.168.0.0/24 \
    --gateway=192.168.0.1 \
    --ipv6 \
    --subnet=fd42:5741:5250::/64 \
    -o parent=eth0 home

cp mdm.xml.template mdm.xml
vim mdm.xml
docker compose --env-file warp.env up -d
```

## Configuration

Mount an `mdm.xml` to `/var/lib/cloudflare-warp/mdm.xml` for managed deployment settings. See the [Cloudflare WARP docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/deployment/mdm-deployment/) for details.

## IPv6 SLAAC / NAT6

The Compose file enables a small IPv6 LAN router mode. Docker assigns the container a ULA address from the external macvlan network, the container advertises that /64 with `radvd`, and IPv6 client traffic is masqueraded out through the WARP interface.

Runtime values live in `warp.env`, which is ignored by Git. Start from `warp.env.example` and adjust it for the target LAN.

The `home` Docker network must be created with IPv6 enabled, and `LAN_IPV6_ADDRESS` must be an address inside `SLAAC_PREFIX` without a CIDR suffix. If `home` was created before IPv6 was added, remove and recreate that Docker network before starting the container.

Defaults:

```dotenv
ENABLE_IPV6_LAN=true
LAN_INTERFACE=eth0
WARP_INTERFACE=CloudflareWARP
LAN_IPV4_ADDRESS=192.168.0.2
LAN_IPV6_ADDRESS=fd42:5741:5250::2
SLAAC_PREFIX=fd42:5741:5250::/64
```

Use a unique ULA /64 for `SLAAC_PREFIX` and put `LAN_IPV6_ADDRESS` inside that prefix. This is NAT66/NAT6, not public IPv6 prefix delegation. To advertise recursive DNS servers with RDNSS, set `SLAAC_RDNSS`, for example `2606:4700:4700::1111 2606:4700:4700::1001`.
