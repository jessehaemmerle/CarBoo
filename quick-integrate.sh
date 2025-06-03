#!/bin/bash

# FleetManager Pro - Quick Integration Script
# Integrates with any existing reverse proxy setup

set -e

echo "🚗 FleetManager Pro - Quick VPS Integration"
echo "==========================================="

# Quick detection
echo "🔍 Detecting your setup..."

# Check for common reverse proxies
if docker ps | grep -qi traefik; then
    echo "✅ Found Traefik reverse proxy"
    PROXY="traefik"
elif docker ps | grep -qi nginx-proxy; then
    echo "✅ Found nginx-proxy"
    PROXY="nginx-proxy"
elif docker ps | grep -qi caddy; then
    echo "✅ Found Caddy"
    PROXY="caddy"
else
    echo "⚠️  No reverse proxy detected"
    PROXY="none"
fi

# Get domain
read -p "📍 Enter your domain for FleetManager (e.g., fleet.yourdomain.com): " DOMAIN

# Generate secure configs
MONGO_PASS=$(openssl rand -base64 24 | tr -d "=+/")
JWT_SECRET=$(openssl rand -base64 48 | tr -d "=+/")

# Create quick .env
cat > .env << EOF
DOMAIN=$DOMAIN
MONGO_PASSWORD=$MONGO_PASS
JWT_SECRET=$JWT_SECRET
REACT_APP_BACKEND_URL=https://$DOMAIN
BACKEND_URL=https://$DOMAIN
ENVIRONMENT=production
EOF

echo "✅ Environment configured"

# Create appropriate docker-compose
case $PROXY in
    "traefik")
        cp docker-compose.traefik.yml docker-compose.yml
        # Ensure network exists
        docker network create traefik-network 2>/dev/null || true
        ;;
    "nginx-proxy")
        echo "📝 Creating nginx-proxy compatible setup..."
        cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  mongodb:
    image: mongo:7.0
    container_name: fleetmanager_mongo
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
    volumes:
      - mongodb_data:/data/db
    networks:
      - internal

  backend:
    build: ./backend
    container_name: fleetmanager_backend
    restart: unless-stopped
    environment:
      - MONGO_URL=mongodb://root:${MONGO_PASSWORD}@mongodb:27017/fleetmanager?authSource=admin
      - JWT_SECRET=${JWT_SECRET}
      - VIRTUAL_HOST=${DOMAIN}
      - VIRTUAL_PATH=/api
      - VIRTUAL_PORT=8001
      - LETSENCRYPT_HOST=${DOMAIN}
    depends_on:
      - mongodb
    networks:
      - internal
      - nginx-proxy

  frontend:
    build: 
      context: ./frontend
      args:
        - REACT_APP_BACKEND_URL=${REACT_APP_BACKEND_URL}
    container_name: fleetmanager_frontend
    restart: unless-stopped
    environment:
      - VIRTUAL_HOST=${DOMAIN}
      - VIRTUAL_PORT=3000
      - LETSENCRYPT_HOST=${DOMAIN}
    depends_on:
      - backend
    networks:
      - nginx-proxy

volumes:
  mongodb_data:

networks:
  internal:
  nginx-proxy:
    external: true
EOF
        docker network create nginx-proxy 2>/dev/null || true
        ;;
    *)
        echo "📝 Creating standalone setup..."
        cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  mongodb:
    image: mongo:7.0
    container_name: fleetmanager_mongo
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
    volumes:
      - mongodb_data:/data/db
    networks:
      - fleetmanager

  backend:
    build: ./backend
    container_name: fleetmanager_backend
    restart: unless-stopped
    environment:
      - MONGO_URL=mongodb://root:${MONGO_PASSWORD}@mongodb:27017/fleetmanager?authSource=admin
      - JWT_SECRET=${JWT_SECRET}
    ports:
      - "8001:8001"
    depends_on:
      - mongodb
    networks:
      - fleetmanager

  frontend:
    build: 
      context: ./frontend
      args:
        - REACT_APP_BACKEND_URL=http://${DOMAIN}:8001
    container_name: fleetmanager_frontend
    restart: unless-stopped
    ports:
      - "3000:3000"
    depends_on:
      - backend
    networks:
      - fleetmanager

volumes:
  mongodb_data:

networks:
  fleetmanager:
EOF
        # Update .env for standalone
        sed -i 's|https://|http://|g' .env
        echo "REACT_APP_BACKEND_URL=http://$DOMAIN:8001" >> .env
        ;;
esac

echo "🚀 Deploying FleetManager Pro..."

# Deploy
docker-compose up -d --build

echo "⏳ Waiting for services..."
sleep 30

# Check status
if docker-compose ps | grep -q "Up"; then
    echo "✅ FleetManager Pro deployed successfully!"
    echo
    echo "🌐 Access your application:"
    if [ "$PROXY" = "none" ]; then
        echo "   Frontend: http://$DOMAIN:3000"
        echo "   Backend:  http://$DOMAIN:8001"
    else
        echo "   Frontend: https://$DOMAIN"
        echo "   Backend:  https://$DOMAIN/api"
    fi
    echo
    echo "🛠️ Management commands:"
    echo "   Start:   docker-compose up -d"
    echo "   Stop:    docker-compose down"
    echo "   Logs:    docker-compose logs -f"
    echo "   Status:  docker-compose ps"
    echo
else
    echo "❌ Deployment failed. Check logs:"
    docker-compose logs
fi