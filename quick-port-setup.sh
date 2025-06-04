#!/bin/bash

# Quick Port Presets for Common Scenarios

echo "🚀 FleetManager Pro - Quick Port Setup"
echo "======================================"

echo ""
echo "Choose a port configuration:"
echo ""
echo "1) Standard ports (3000, 8001, 27017) - Default"
echo "2) High ports (8080, 8081, 27018) - Avoid conflicts"
echo "3) Web ports (80, 8000, 27017) - Direct web access"
echo "4) Custom ports - Choose your own"
echo "5) Random available ports - Auto-detect"
echo ""

read -p "Select option (1-5): " choice

case $choice in
    1)
        FRONTEND_PORT=3000
        BACKEND_PORT=8001
        MONGO_PORT=27017
        SETUP_NAME="standard"
        ;;
    2)
        FRONTEND_PORT=8080
        BACKEND_PORT=8081
        MONGO_PORT=27018
        SETUP_NAME="high-ports"
        ;;
    3)
        FRONTEND_PORT=80
        BACKEND_PORT=8000
        MONGO_PORT=27017
        SETUP_NAME="web-ports"
        ;;
    4)
        echo "Enter custom ports:"
        read -p "Frontend port: " FRONTEND_PORT
        read -p "Backend port: " BACKEND_PORT
        read -p "MongoDB port: " MONGO_PORT
        SETUP_NAME="custom"
        ;;
    5)
        echo "🔍 Finding available ports..."
        FRONTEND_PORT=$(python3 -c "import socket; s=socket.socket(); s.bind(('', 0)); print(s.getsockname()[1]); s.close()")
        BACKEND_PORT=$(python3 -c "import socket; s=socket.socket(); s.bind(('', 0)); print(s.getsockname()[1]); s.close()")
        MONGO_PORT=$(python3 -c "import socket; s=socket.socket(); s.bind(('', 0)); print(s.getsockname()[1]); s.close()")
        SETUP_NAME="auto"
        ;;
    *)
        echo "Invalid option. Using standard ports."
        FRONTEND_PORT=3000
        BACKEND_PORT=8001
        MONGO_PORT=27017
        SETUP_NAME="standard"
        ;;
esac

echo ""
echo "✅ Selected configuration: $SETUP_NAME"
echo "   Frontend: $FRONTEND_PORT"
echo "   Backend:  $BACKEND_PORT"
echo "   MongoDB:  $MONGO_PORT"

# Get domain
read -p "Enter your domain (or press Enter for localhost): " DOMAIN
DOMAIN=${DOMAIN:-localhost}

# Generate environment
MONGO_PASSWORD=$(openssl rand -base64 25 | tr -d "=+/")
JWT_SECRET=$(openssl rand -base64 50 | tr -d "=+/")

# Create environment file
cat > .env.$SETUP_NAME << EOF
# FleetManager Pro - $SETUP_NAME Configuration
DOMAIN=$DOMAIN
FRONTEND_PORT=$FRONTEND_PORT
BACKEND_PORT=$BACKEND_PORT
MONGO_PORT=$MONGO_PORT

# URLs
BACKEND_URL=http://$DOMAIN:$BACKEND_PORT
REACT_APP_BACKEND_URL=http://$DOMAIN:$BACKEND_PORT

# Database
MONGO_PASSWORD=$MONGO_PASSWORD
MONGO_URL=mongodb://root:$MONGO_PASSWORD@mongodb:27017/fleetmanager?authSource=admin

# Security
JWT_SECRET=$JWT_SECRET
ENVIRONMENT=production
EOF

# Create docker-compose file
cat > docker-compose.$SETUP_NAME.yml << 'EOF'
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: fleetmanager_mongodb_${SETUP_NAME}
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
      MONGO_INITDB_DATABASE: fleetmanager
    ports:
      - "${MONGO_PORT}:27017"
    volumes:
      - mongodb_data_${SETUP_NAME}:/data/db
    networks:
      - fleetmanager-${SETUP_NAME}

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
    container_name: fleetmanager_backend_${SETUP_NAME}
    restart: unless-stopped
    environment:
      - MONGO_URL=${MONGO_URL}
      - JWT_SECRET=${JWT_SECRET}
      - ENVIRONMENT=production
    ports:
      - "${BACKEND_PORT}:8001"
    depends_on:
      - mongodb
    networks:
      - fleetmanager-${SETUP_NAME}

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.prod
      args:
        - REACT_APP_BACKEND_URL=${REACT_APP_BACKEND_URL}
    container_name: fleetmanager_frontend_${SETUP_NAME}
    restart: unless-stopped
    ports:
      - "${FRONTEND_PORT}:3000"
    depends_on:
      - backend
    networks:
      - fleetmanager-${SETUP_NAME}

volumes:
  mongodb_data_${SETUP_NAME}:

networks:
  fleetmanager-${SETUP_NAME}:
EOF

# Replace placeholder with actual setup name
sed -i "s/\${SETUP_NAME}/$SETUP_NAME/g" docker-compose.$SETUP_NAME.yml

# Create management script
cat > manage-$SETUP_NAME.sh << EOF
#!/bin/bash

case "\$1" in
    "start")
        echo "🚀 Starting FleetManager Pro ($SETUP_NAME)..."
        docker-compose -f docker-compose.$SETUP_NAME.yml --env-file .env.$SETUP_NAME up -d --build
        echo ""
        echo "✅ Started! Access at:"
        echo "   🌐 Frontend: http://$DOMAIN:$FRONTEND_PORT"
        echo "   🚀 Backend:  http://$DOMAIN:$BACKEND_PORT"
        echo "   📚 API Docs: http://$DOMAIN:$BACKEND_PORT/docs"
        ;;
    "stop")
        echo "🛑 Stopping FleetManager Pro ($SETUP_NAME)..."
        docker-compose -f docker-compose.$SETUP_NAME.yml down
        ;;
    "restart")
        echo "🔄 Restarting FleetManager Pro ($SETUP_NAME)..."
        docker-compose -f docker-compose.$SETUP_NAME.yml restart
        ;;
    "logs")
        docker-compose -f docker-compose.$SETUP_NAME.yml logs -f \$2
        ;;
    "status")
        echo "📊 FleetManager Pro Status ($SETUP_NAME):"
        docker-compose -f docker-compose.$SETUP_NAME.yml ps
        echo ""
        echo "🌐 URLs:"
        echo "   Frontend: http://$DOMAIN:$FRONTEND_PORT"
        echo "   Backend:  http://$DOMAIN:$BACKEND_PORT"
        ;;
    "build")
        echo "🔨 Building FleetManager Pro ($SETUP_NAME)..."
        docker-compose -f docker-compose.$SETUP_NAME.yml build --no-cache
        ;;
    "clean")
        echo "🧹 Cleaning FleetManager Pro ($SETUP_NAME)..."
        docker-compose -f docker-compose.$SETUP_NAME.yml down -v
        docker system prune -f
        ;;
    *)
        echo "🛠️  FleetManager Pro Management ($SETUP_NAME)"
        echo "Usage: \$0 {start|stop|restart|logs|status|build|clean}"
        echo ""
        echo "Commands:"
        echo "  start   - Start all services"
        echo "  stop    - Stop all services"
        echo "  restart - Restart all services"
        echo "  logs    - View logs (optionally specify service)"
        echo "  status  - Show service status and URLs"
        echo "  build   - Rebuild all images"
        echo "  clean   - Stop and remove everything"
        ;;
esac
EOF

chmod +x manage-$SETUP_NAME.sh

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📁 Files created:"
echo "   .env.$SETUP_NAME"
echo "   docker-compose.$SETUP_NAME.yml"
echo "   manage-$SETUP_NAME.sh"
echo ""
echo "🚀 Quick start:"
echo "   ./manage-$SETUP_NAME.sh start"
echo ""
echo "🛠️  Management commands:"
echo "   ./manage-$SETUP_NAME.sh start"
echo "   ./manage-$SETUP_NAME.sh stop"
echo "   ./manage-$SETUP_NAME.sh status"
echo "   ./manage-$SETUP_NAME.sh logs"
echo ""
echo "🌐 Your application will be available at:"
echo "   Frontend: http://$DOMAIN:$FRONTEND_PORT"
echo "   Backend:  http://$DOMAIN:$BACKEND_PORT"
echo ""

# Show firewall commands
echo "🔥 Firewall configuration (if needed):"
echo "   sudo ufw allow $FRONTEND_PORT/tcp"
echo "   sudo ufw allow $BACKEND_PORT/tcp"
if [ "$MONGO_PORT" != "27017" ]; then
    echo "   sudo ufw allow $MONGO_PORT/tcp"
fi
echo ""

# Show DNS configuration
echo "🌐 DNS Configuration:"
echo "   Create A record: $DOMAIN → YOUR_SERVER_IP"
echo "   Access via: http://$DOMAIN:$FRONTEND_PORT"
echo ""

echo "✨ Ready to deploy FleetManager Pro on custom ports!"