#!/bin/bash
set -euo pipefail

DOMAIN="meet.relaticpanama.org"
PUBLIC_IP="3.147.220.236"
LE_EMAIL="relaticpanama2025@gmail.com"
RELEASE="stable-11146-2"
APP_DIR="$HOME/docker-jitsi-meet-${RELEASE}"

sudo apt-get update
sudo apt-get install -y ca-certificates curl unzip

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker ubuntu
sudo systemctl enable --now docker

cd "$HOME"
curl -sL -o "docker-jitsi-meet-${RELEASE}.zip" "https://github.com/jitsi/docker-jitsi-meet/archive/refs/tags/${RELEASE}.zip"
rm -rf "$APP_DIR"
unzip -q -o "docker-jitsi-meet-${RELEASE}.zip"
cd "$APP_DIR"
cp env.example .env

python3 - <<'PY'
from pathlib import Path
p = Path(".env")
text = p.read_text()
reps = {
    "HTTP_PORT=8000": "HTTP_PORT=80",
    "HTTPS_PORT=8443": "HTTPS_PORT=443",
    "TZ=UTC": "TZ=America/Panama",
    "#PUBLIC_URL=https://meet.example.com:${HTTPS_PORT}": "PUBLIC_URL=https://meet.relaticpanama.org",
    "#JVB_ADVERTISE_IPS=192.168.1.1,1.2.3.4,192.168.178.1#12000,fe80::1#12000": "JVB_ADVERTISE_IPS=3.147.220.236",
    "#ENABLE_LETSENCRYPT=1": "ENABLE_LETSENCRYPT=1",
    "#LETSENCRYPT_DOMAIN=meet.example.com": "LETSENCRYPT_DOMAIN=meet.relaticpanama.org",
    "#LETSENCRYPT_EMAIL=alice@atlanta.net": "LETSENCRYPT_EMAIL=relaticpanama2025@gmail.com",
}
for old, new in reps.items():
    if old not in text:
        raise SystemExit(f"pattern not found: {old}")
    text = text.replace(old, new, 1)
if "ENABLE_HTTP_REDIRECT=" not in text:
    text += "\nENABLE_HTTP_REDIRECT=1\n"
p.write_text(text)
print("env ok")
PY

./gen-passwords.sh

mkdir -p ~/.jitsi-meet-cfg/{web,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri,transcriber}
mkdir -p ~/.jitsi-meet-cfg/storage/{jibri,prosody,transcripts,web}
mkdir -p ~/.jitsi-meet-cfg/tmp/{web-crontabs,web-load-test}
chmod 777 ~/.jitsi-meet-cfg/storage/{jibri,prosody,transcripts,web}
chmod 777 ~/.jitsi-meet-cfg/tmp/{web-crontabs,web-load-test}

sudo docker compose pull
sudo docker compose up -d
sudo docker compose ps

echo
echo "Esperando HTTPS..."
for i in $(seq 1 30); do
  code=$(curl -s -o /dev/null -w "%{http_code}" "https://${DOMAIN}" || true)
  if [ "$code" = "200" ]; then
    echo "LISTO: https://${DOMAIN} → HTTP $code"
    exit 0
  fi
  echo "intento $i: HTTP $code"
  sleep 5
done
echo "Los contenedores están arriba. Si HTTPS aún no responde, espera 1 minuto y abre https://${DOMAIN}"
sudo docker compose logs --tail=40 web
