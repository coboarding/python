#!/bin/bash

# Poczekaj na VNC serwer
echo "Waiting for VNC server to start..."
while ! nc -z ${VNC_HOST:-browser-service} ${VNC_PORT:-5900}; do
  sleep 0.5
done

# Uruchom noVNC z opcjonalnymi parametrami
exec /opt/novnc/utils/novnc_proxy \
    --vnc ${VNC_HOST:-browser-service}:${VNC_PORT:-5900} \
    --listen 6080 \
    ${NOVNC_OPTS:---compression=9 --quality=3}