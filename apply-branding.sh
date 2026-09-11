#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST="${JITSI_WEB_CONFIG:-$HOME/.jitsi-meet-cfg/web}"

mkdir -p "$DEST/branding" "$DEST/nginx" "$DEST/lang"

cp "$ROOT/branding/custom-config.js" "$DEST/custom-config.js"
cp "$ROOT/branding/custom-interface_config.js" "$DEST/custom-interface_config.js"
cp "$ROOT/branding/title.html" "$DEST/title.html"
cp "$ROOT/branding/head.html" "$DEST/head.html"
cp "$ROOT/branding/nginx/custom-meet.conf" "$DEST/nginx/custom-meet.conf"
cp "$ROOT/branding/lang/main-es.json" "$DEST/lang/main-es.json"
cp "$ROOT/branding/lang/main-es-US.json" "$DEST/lang/main-es-US.json"
cp "$ROOT/branding/lang/main.json" "$DEST/lang/main.json"
cp "$ROOT/branding/images/logo.png" "$DEST/branding/logo.png"
cp "$ROOT/branding/images/favicon.png" "$DEST/branding/favicon.png"

echo "Branding copiado a $DEST"
