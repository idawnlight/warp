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
docker network create -d macvlan \
    --subnet=192.168.0.0/24 \
    --gateway=192.168.0.1 \
    -o parent=eth0 home

cp warp.env.example warp.env
vim warp.env
cp mdm.xml.template mdm.xml
vim mdm.xml
docker compose up -d
```

## Configuration

Mount an `mdm.xml` to `/var/lib/cloudflare-warp/mdm.xml` for managed deployment settings. See the [Cloudflare WARP docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/deployment/mdm-deployment/) for details.

## IPv6 SLAAC / NAT6

The Compose file enables a small IPv6 LAN router mode. The container assigns itself a ULA address, advertises that /64 with `radvd`, and masquerades IPv6 client traffic out through the WARP interface.

Runtime values live in `warp.env`, which is ignored by Git. Start from `warp.env.example` and adjust it for the target LAN.

Defaults:

```dotenv
ENABLE_IPV6_LAN=true
LAN_INTERFACE=eth0
WARP_INTERFACE=CloudflareWARP
SLAAC_PREFIX=fd42:5741:5250::/64
SLAAC_ADDRESS=fd42:5741:5250::1/64
```

Use a unique ULA /64 for `SLAAC_PREFIX` and put `SLAAC_ADDRESS` inside that prefix. This is NAT66/NAT6, not public IPv6 prefix delegation. To advertise recursive DNS servers with RDNSS, set `SLAAC_RDNSS`, for example `2606:4700:4700::1111 2606:4700:4700::1001`.
