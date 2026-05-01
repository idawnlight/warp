# warp

Dockerized Cloudflare WARP client with [gost](https://github.com/go-gost/gost) proxy.

## Features

- Cloudflare WARP / Zero Trust / One with NAT masquerading
- HTTP proxy on port `1080`, SOCKS5 proxy on port `1081` (UDP supported)
- Multi-arch: `linux/amd64` and `linux/arm64`
- Weekly automated builds via GitHub Actions

## Quick Start

```sh
docker network create -d macvlan \
    --subnet=192.168.0.0/24 \
    --gateway=192.168.0.1 \
    -o parent=eth0 home

vim compose.yaml
docker compose up -d
```

## Configuration

Mount an `mdm.xml` to `/var/lib/cloudflare-warp/mdm.xml` for managed deployment settings. See the [Cloudflare WARP docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/deployment/mdm-deployment/) for details.
