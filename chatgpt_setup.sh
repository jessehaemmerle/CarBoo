#!/usr/bin/env bash
set -euo pipefail

# Lies ENV und Compose-File
ENV_FILE=".env"
COMPOSE_FILE="docker-compose.yml"

# Lade ENV
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' $ENV_FILE | xargs)
fi

# Apache stoppen, falls Port 80 belegt
if ss -tln | grep -q ':80 '; then
  echo "⚠️  Apache läuft auf Port 80 – stoppe ihn…"
  sudo systemctl stop apache2
  sudo systemctl disable apache2
fi

# Down & Cleanup
docker compose --env-file $ENV_FILE -f $COMPOSE_FILE down --remove-orphans

# Build & Start
docker compose --env-file $ENV_FILE -f $COMPOSE_FILE up -d --build

# Health-Wait
for svc in fleetmanager_backend_prod fleetmanager_frontend_prod; do
  for i in {1..24}; do
    status=$(docker inspect $svc --format '{{.State.Health.Status}}' 2>/dev/null || echo "no-health")
    echo "Warte auf $svc: $status"
    [ "$status" = "healthy" ] && break
    sleep 5
  done
done

echo "✅ Deployment abgeschlossen. Frontend unter http://$(hostname -I | awk '{print $1}'):${FRONTEND_HOST_PORT}"
