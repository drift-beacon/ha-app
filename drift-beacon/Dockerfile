# syntax=docker/dockerfile:1.4

ARG NODE_VERSION=26.10.0
ARG BUILD_FROM
ARG SERVER_IMAGE=ghcr.io/rshallam/drift-beacon-server:0.2.52

FROM ${SERVER_IMAGE} AS server
FROM ${BUILD_FROM} AS runtime

ARG BUILD_ARCH
ARG NODE_VERSION
# The add-on is aarch64 only
ARG NODE_SHA256=7a6353f63eb3d04765004b4adf172616243e4522434635cb1d26288658b04ab5
ARG TEMPIO_VERSION="2024.11.2"
ARG TEMPIO_SHA256=01d1c8108e05b02e865286e715b05025a97f484ac694daa019323144e1d4e986

ENV SERVICE_PORT=9823
ENV NGINX_PORT_HTTPS=9000
ENV NGINX_PORT_HTTP=9001

WORKDIR /app

# libatomic1: the official Node.js binaries link against it, and the base image doesn't ship it.
# git: plugin catalogues are scanned from shallow HTTPS clones at runtime.
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    jq \
    libatomic1 \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/* /etc/nginx \
    && { [ "$(dpkg --print-architecture)" = arm64 ] || { echo "Unsupported architecture: the add-on is aarch64 only"; exit 1; }; } \
    && NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.xz" \
    && echo "Downloading Node.js from: ${NODE_URL}" \
    && curl -fsSL "${NODE_URL}" -o node.tar.xz \
    && echo "${NODE_SHA256}  node.tar.xz" | sha256sum -c - \
    # Only the runtime: skip the C headers (for compiling native addons), npm/npx and the docs.
    && tar -xJf node.tar.xz -C /usr/local --strip-components=1 --no-same-owner \
        --exclude='*/include' --exclude='*/lib/node_modules' --exclude='*/bin/npm' --exclude='*/bin/npx' \
        --exclude='*/CHANGELOG.md' --exclude='*/README.md' \
    && rm node.tar.xz \
    && node --version \
    && git --version \
    && test -x "$(git --exec-path)/git-remote-https"
    # Note: curl is kept installed for bashio to contact HA API

# Install tempio for nginx config templating
RUN curl -fsSL -o /usr/bin/tempio \
    "https://github.com/home-assistant/tempio/releases/download/${TEMPIO_VERSION}/tempio_${BUILD_ARCH}" \
    && echo "${TEMPIO_SHA256}  /usr/bin/tempio" | sha256sum -c - \
    && chmod a+x /usr/bin/tempio

COPY --from=server /app ./
COPY rootfs /

RUN chmod +x /usr/local/bin/*.sh \
    && chmod +x /etc/s6-overlay/s6-rc.d/*/run /etc/s6-overlay/s6-rc.d/*/finish
RUN mkdir -p /data

# DATA_DIR: the add-on's persistent volume. Without it the server writes `data` in its working directory, inside the
# image, and an update starts with no accounts.
ENV NODE_ENV=production \
    PORT=9823 \
    DATA_DIR=/data

# Expose ports
EXPOSE 9000
EXPOSE 9001

# Liveness through nginx's plain-HTTP port, which serves with SSL on and off. No --start-interval: it needs Docker 25,
# and the Supervisor still supports 24.
HEALTHCHECK --interval=10s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -fsS -o /dev/null "http://localhost:${NGINX_PORT_HTTP}/api/livez" || exit 1
