#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="docker-compose.prod.yml"

# Lies den Host-Port aus .env (oder Default 8080)
FRONTEND_HOST_PORT=${1:-$(grep ^FRONTEND_HOST_PORT .env | cut -d'=' -f2)}

echo "==> Deploy mit Frontend on Host-Port: $FRONTEND_HOST_PORT"

# Wenn Port 80: Apache stoppen
if [ "$FRONTEND_HOST_PORT" = "80" ] && ss -tln | grep -q ":80 "; then
  echo "⚠️  Apache läuft – stoppe ihn für Port 80…"
  sudo systemctl stop apache2
  sudo systemctl disable apache2
fi

echo "==> Down, Build & Up"
docker compose --env-file .env -f $COMPOSE_FILE down --remove-orphans
docker compose --env-file .env -f $COMPOSE_FILE up -d --build

echo "==> Warte auf Backend (bis zu 2 Minuten)…"
for i in {1..24}; do
  st=$(docker inspect fleetmanager_backend_prod --format '{{.State.Health.Status}}' 2>/dev/null||echo)
  echo "  Versuch $i: Backend $st"
  [[ "$st" == "healthy" ]] && break
  sleep 5
done

echo "==> Warte auf Frontend (bis zu 2 Minuten)…"
for i in {1..24}; do
  st=$(docker inspect fleetmanager_frontend_prod --format '{{.State.Health.Status}}' 2>/dev/null||echo)
  echo "  Versuch $i: Frontend $st"
  [[ "$st" == "healthy" ]] && break
  sleep 5
done

echo
echo "==> Aktuelle Container-Ports"
docker ps --filter name=fleetmanager_frontend_prod --format 'table {{.Names}}\t{{.Ports}}'

echo
echo "==> Fertig! Frontend erreichbar unter http://$(hostname -I | awk '{print $1}'):$FRONTEND_HOST_PORT"
