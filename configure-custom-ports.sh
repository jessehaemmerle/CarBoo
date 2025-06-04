#!/bin/bash

# Port Configuration Script for FleetManager Pro
# Allows you to set custom ports for all services

set -e

echo "🔧 FleetManager Pro - Port Configuration"
echo "========================================"

# Default ports
DEFAULT_FRONTEND_PORT=3000
DEFAULT_BACKEND_PORT=8001
DEFAULT_MONGO_PORT=27017

echo ""
echo "Current default ports:"
echo "  Frontend: $DEFAULT_FRONTEND_PORT"
echo "  Backend:  $DEFAULT_BACKEND_PORT"
echo "  MongoDB:  $DEFAULT_MONGO_PORT"
echo ""

# Get custom ports from user
read -p "Enter FRONTEND port (default: $DEFAULT_FRONTEND_PORT): " FRONTEND_PORT
FRONTEND_PORT=${FRONTEND_PORT:-$DEFAULT_FRONTEND_PORT}

read -p "Enter BACKEND port (default: $DEFAULT_BACKEND_PORT): " BACKEND_PORT  
BACKEND_PORT=${BACKEND_PORT:-$DEFAULT_BACKEND_PORT}

read -p "Enter MONGODB port (default: $DEFAULT_MONGO_PORT): " MONGO_PORT
MONGO_PORT=${MONGO_PORT:-$DEFAULT_MONGO_PORT}

echo ""
echo "✅ Selected ports:"
echo "  Frontend: $FRONTEND_PORT"
echo "  Backend:  $BACKEND_PORT" 
echo "  MongoDB:  $MONGO_PORT"
echo ""

# Get domain
read -p "Enter your domain (e.g., fleet.yourdomain.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
    DOMAIN="localhost"
fi

echo ""
echo "🔧 Configuring FleetManager Pro with custom ports..."

# Create custom environment file
cat > .env.custom-ports << EOF
# FleetManager Pro - Custom Port Configuration
DOMAIN=$DOMAIN
FRONTEND_PORT=$FRONTEND_PORT
BACKEND_PORT=$BACKEND_PORT
MONGO_PORT=$MONGO_PORT

# URLs with custom ports
BACKEND_URL=http://$DOMAIN:$BACKEND_PORT
REACT_APP_BACKEND_URL=http://$DOMAIN:$BACKEND_PORT

# Database
MONGO_PASSWORD=\$(openssl rand -base64 25 | tr -d "=+/")
MONGO_URL=mongodb://root:\$MONGO_PASSWORD@mongodb:27017/fleetmanager?authSource=admin

# Security
JWT_SECRET=\$(openssl rand -base64 50 | tr -d "=+/")
ENVIRONMENT=production
EOF

# Generate secure passwords
MONGO_PASSWORD=$(openssl rand -base64 25 | tr -d "=+/")
JWT_SECRET=$(openssl rand -base64 50 | tr -d "=+/")

# Update with actual passwords
sed -i "s/\$(openssl rand -base64 25 | tr -d \"=+\/\")/$MONGO_PASSWORD/" .env.custom-ports
sed -i "s/\$(openssl rand -base64 50 | tr -d \"=+\/\")/$JWT_SECRET/" .env.custom-ports

echo "✅ Environment file created: .env.custom-ports"

# Create custom docker-compose file
cat > docker-compose.custom-ports.yml << EOF
version: '3.8'

services:
  # MongoDB Database
  mongodb:
    image: mongo:7.0
    container_name: fleetmanager_mongodb_custom
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: \${MONGO_PASSWORD}
      MONGO_INITDB_DATABASE: fleetmanager
    ports:
      - "\${MONGO_PORT}:27017"
    volumes:
      - mongodb_data_custom:/data/db
    networks:
      - fleetmanager-custom
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # Backend API
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
    container_name: fleetmanager_backend_custom
    restart: unless-stopped
    environment:
      - MONGO_URL=\${MONGO_URL}
      - JWT_SECRET=\${JWT_SECRET}
      - ENVIRONMENT=production
    ports:
      - "\${BACKEND_PORT}:8001"
    depends_on:
      mongodb:
        condition: service_healthy
    networks:
      - fleetmanager-custom
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # Frontend Web App
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.prod
      args:
        - REACT_APP_BACKEND_URL=\${REACT_APP_BACKEND_URL}
    container_name: fleetmanager_frontend_custom
    restart: unless-stopped
    ports:
      - "\${FRONTEND_PORT}:3000"
    depends_on:
      backend:
        condition: service_healthy
    networks:
      - fleetmanager-custom
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

volumes:
  mongodb_data_custom:
    driver: local

networks:
  fleetmanager-custom:
    driver: bridge
EOF

echo "✅ Docker Compose file created: docker-compose.custom-ports.yml"

# Create management scripts
cat > start-custom-ports.sh << EOF
#!/bin/bash
echo "🚀 Starting FleetManager Pro on custom ports..."
docker-compose -f docker-compose.custom-ports.yml --env-file .env.custom-ports up -d
echo ""
echo "✅ FleetManager Pro started!"
echo "🌐 Access your application:"
echo "   Frontend: http://$DOMAIN:$FRONTEND_PORT"
echo "   Backend:  http://$DOMAIN:$BACKEND_PORT"
echo "   API Docs: http://$DOMAIN:$BACKEND_PORT/docs"
echo ""
echo "📊 MongoDB: localhost:$MONGO_PORT"
EOF

cat > stop-custom-ports.sh << EOF
#!/bin/bash
echo "🛑 Stopping FleetManager Pro..."
docker-compose -f docker-compose.custom-ports.yml --env-file .env.custom-ports down
echo "✅ FleetManager Pro stopped"
EOF

cat > logs-custom-ports.sh << EOF
#!/bin/bash
if [ -z "\$1" ]; then
    echo "📋 Showing all logs..."
    docker-compose -f docker-compose.custom-ports.yml --env-file .env.custom-ports logs -f
else
    echo "📋 Showing logs for: \$1"
    docker-compose -f docker-compose.custom-ports.yml --env-file .env.custom-ports logs -f \$1
fi
EOF

cat > status-custom-ports.sh << EOF
#!/bin/bash
echo "📊 FleetManager Pro Status"
echo "=========================="
docker-compose -f docker-compose.custom-ports.yml --env-file .env.custom-ports ps
echo ""
echo "🌐 Application URLs:"
echo "   Frontend: http://$DOMAIN:$FRONTEND_PORT"
echo "   Backend:  http://$DOMAIN:$BACKEND_PORT"
echo "   API Docs: http://$DOMAIN:$BACKEND_PORT/docs"
echo "   MongoDB:  localhost:$MONGO_PORT"
EOF

# Make scripts executable
chmod +x start-custom-ports.sh stop-custom-ports.sh logs-custom-ports.sh status-custom-ports.sh

echo "✅ Management scripts created!"

echo ""
echo "🎉 Custom port configuration complete!"
echo ""
echo "📋 Your FleetManager Pro will run on:"
echo "   🌐 Frontend: http://$DOMAIN:$FRONTEND_PORT"
echo "   🚀 Backend:  http://$DOMAIN:$BACKEND_PORT"  
echo "   📊 MongoDB:  localhost:$MONGO_PORT"
echo ""
echo "🛠️  Management commands:"
echo "   Start:  ./start-custom-ports.sh"
echo "   Stop:   ./stop-custom-ports.sh"
echo "   Logs:   ./logs-custom-ports.sh [service]"
echo "   Status: ./status-custom-ports.sh"
echo ""
echo "🚀 To start your application:"
echo "   ./start-custom-ports.sh"
echo ""
echo "🌐 DNS Configuration:"
echo "   Point your domain $DOMAIN to your server IP"
echo "   Access via: http://$DOMAIN:$FRONTEND_PORT"
echo ""
echo "🔥 Your custom port setup is ready!"