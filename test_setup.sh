#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------------------------------------
# Usage: ./setup.sh [HOST_PORT]
#   HOST_PORT: Port auf dem Host, auf dem dein Frontend verfügbar sein soll (default: 8080).
# -------------------------------------------------------------------------------------------------

HOST_PORT=${1:-8080}
COMPOSE_FILE="docker-compose.prod.yml"
OVERRIDE_FILE="docker-compose.override.yml"
FRONTEND_SERVICE="fleetmanager_frontend_prod"

echo "==> Deployment startet mit Host-Port: $HOST_PORT"

# 1) Prüfen, ob Apache auf Port 80 läuft (nur Warnung)
if ss -tln | grep -q ":80 "; then
  echo "⚠️  Achtung: Apache läuft auf Port 80. Wenn du Host-Port 80 nutzen willst, stopp Apache:"
  echo "   sudo systemctl stop apache2 && sudo systemctl disable apache2"
fi

# 2) Override-File für dynamisches Port-Mapping erzeugen
cat > $OVERRIDE_FILE <<EOF
version: '3.8'
services:
  frontend:
    ports:
      - "${HOST_PORT}:80"
EOF

echo "==> Override-File '$OVERRIDE_FILE' erstellt: frontend → Host ${HOST_PORT}→Container 80"

# 3) Down & Cleanup (inkl. Orphans)
echo "==> Bringe bestehende Container herunter…"
docker compose -f $COMPOSE_FILE -f $OVERRIDE_FILE down --remove-orphans

# 4) Build & Up
echo "==> Baue und starte alle Services…"
docker compose -f $COMPOSE_FILE -f $OVERRIDE_FILE up -d --build

# 5) Warten auf Healthcheck
echo "==> Warte, bis Frontend gesund ist…"
for i in {1..20}; do
  STATUS=$(docker inspect $FRONTEND_SERVICE --format '{{.State.Health.Status}}' 2>/dev/null || echo "no-health")
  echo "   Versuch $i: Status = $STATUS"
  if [ "$STATUS" = "healthy" ]; then
    echo "✅ Frontend ist healthy."
    break
  fi
  sleep 3
done

# 6) Ausgabe der Port-Bindings
echo
echo "==> Aktive Container und ihre Ports:"
docker ps --filter name=$FRONTEND_SERVICE --format 'table {{.Names}}\t{{.Ports}}'

echo
echo "==> Deployment abgeschlossen. Frontend erreichbar unter http://<deine-ip>:$HOST_PORT"
