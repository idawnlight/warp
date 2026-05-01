FROM ubuntu:24.04

# Prevent interactive prompts during apt installations
ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisites, add Cloudflare repo, and install warp-cli
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    iptables \
    iproute2 \
    ca-certificates \
    dbus \
    && curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ noble main" | tee /etc/apt/sources.list.d/cloudflare-client.list \
    && apt-get update && apt-get install -y cloudflare-warp \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy our startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]