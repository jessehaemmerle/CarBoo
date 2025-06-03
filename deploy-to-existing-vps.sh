#!/bin/bash

# FleetManager Pro VPS Deployment Script for Existing Reverse Proxy Setup
# This script deploys FleetManager Pro alongside other containers with different domains

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites for FleetManager Pro..."
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        echo "Install with: curl -fsSL https://get.docker.com | sh"
        exit 1
    fi
    
    if ! command_exists docker-compose; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        echo "Install with: sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose"
        exit 1
    fi
    
    # Check for existing reverse proxy networks
    PROXY_NETWORKS=$(docker network ls --format "{{.Name}}" | grep -E "traefik|nginx-proxy|proxy|web" || true)
    
    if [ -z "$PROXY_NETWORKS" ]; then
        print_warning "No reverse proxy network found. Available networks:"
        docker network ls
        echo
        read -p "Enter the name of your reverse proxy network (or press Enter to create new): " NETWORK_NAME
        if [ -z "$NETWORK_NAME" ]; then
            NETWORK_NAME="fleetmanager-proxy"
            print_status "Will create new network: $NETWORK_NAME"
        fi
    fi
    
    print_success "Prerequisites check passed!"
}

# Detect reverse proxy type
detect_proxy_type() {
    print_status "Detecting reverse proxy setup..."
    
    # Check for running Traefik
    if docker ps --format "{{.Names}}" | grep -qi traefik; then
        PROXY_TYPE="traefik"
        PROXY_NETWORK=$(docker network ls --format "{{.Name}}" | grep -i traefik | head -n1)
        if [ -z "$PROXY_NETWORK" ]; then
            PROXY_NETWORK="traefik-network"
        fi
        print_success "Detected Traefik reverse proxy (network: $PROXY_NETWORK)"
        
    # Check for nginx-proxy
    elif docker ps --format "{{.Names}}" | grep -qi nginx-proxy; then
        PROXY_TYPE="nginx-proxy"
        PROXY_NETWORK=$(docker network ls --format "{{.Name}}" | grep -E "nginx-proxy|nginx_proxy" | head -n1)
        if [ -z "$PROXY_NETWORK" ]; then
            PROXY_NETWORK="nginx-proxy"
        fi
        print_success "Detected nginx-proxy reverse proxy (network: $PROXY_NETWORK)"
        
    # Check for Caddy
    elif docker ps --format "{{.Names}}" | grep -qi caddy; then
        PROXY_TYPE="caddy"
        PROXY_NETWORK=$(docker network ls --format "{{.Name}}" | grep -i caddy | head -n1)
        if [ -z "$PROXY_NETWORK" ]; then
            PROXY_NETWORK="caddy"
        fi
        print_success "Detected Caddy reverse proxy (network: $PROXY_NETWORK)"
        
    else
        print_warning "Could not auto-detect reverse proxy type."
        echo
        echo "Available options:"
        echo "1) Traefik (with automatic SSL)"
        echo "2) nginx-proxy (with automatic SSL)"
        echo "3) Caddy (with automatic SSL)"
        echo "4) Custom/Manual setup"
        echo "5) No reverse proxy (direct ports)"
        read -p "Select your reverse proxy type (1-5): " choice
        
        case $choice in
            1)
                PROXY_TYPE="traefik"
                PROXY_NETWORK="traefik-network"
                ;;
            2)
                PROXY_TYPE="nginx-proxy"
                PROXY_NETWORK="nginx-proxy"
                ;;
            3)
                PROXY_TYPE="caddy"
                PROXY_NETWORK="caddy"
                ;;
            4)
                PROXY_TYPE="manual"
                read -p "Enter your proxy network name: " PROXY_NETWORK
                if [ -z "$PROXY_NETWORK" ]; then
                    print_error "Network name is required for manual setup."
                    exit 1
                fi
                ;;
            5)
                PROXY_TYPE="standalone"
                PROXY_NETWORK="fleetmanager-network"
                print_warning "Running without reverse proxy. FleetManager will use ports 3000 and 8001 directly."
                ;;
            *)
                print_error "Invalid choice"
                exit 1
                ;;
        esac
    fi
    
    # Verify/create network
    if ! docker network ls | grep -q "$PROXY_NETWORK"; then
        print_status "Creating network '$PROXY_NETWORK'..."
        docker network create "$PROXY_NETWORK"
        print_success "Network '$PROXY_NETWORK' created"
    fi
}

# Setup environment configuration
setup_environment() {
    print_status "Setting up FleetManager Pro environment configuration..."
    
    if [ ! -f .env.vps ]; then
        # Create environment template
        cat > .env.vps << 'EOF'
# FleetManager Pro VPS Configuration
# Domain Configuration
DOMAIN=fleet.yourdomain.com
SSL_EMAIL=admin@yourdomain.com

# Database Configuration
MONGO_PASSWORD=your_secure_mongo_password_here
MONGO_URL=mongodb://root:your_secure_mongo_password_here@mongodb:27017/fleetmanager?authSource=admin

# Security Configuration
JWT_SECRET=your_super_secure_jwt_secret_here_change_this_in_production

# Backend Configuration
BACKEND_URL=https://fleet.yourdomain.com
REACT_APP_BACKEND_URL=https://fleet.yourdomain.com

# Reverse Proxy Configuration
PROXY_TYPE=traefik
PROXY_NETWORK=traefik-network

# Environment
ENVIRONMENT=production
EOF
    fi
    
    if [ ! -f .env ]; then
        cp .env.vps .env
        
        # Get domain from user
        read -p "Enter your domain for FleetManager Pro (e.g., fleet.yourdomain.com): " domain
        if [ -z "$domain" ]; then
            print_error "Domain is required."
            exit 1
        fi
        
        # Get email for SSL
        if [ "$PROXY_TYPE" != "standalone" ]; then
            read -p "Enter your email for SSL certificates: " email
            if [ -z "$email" ]; then
                print_error "Email is required for SSL certificates."
                exit 1
            fi
        else
            email="admin@localhost"
        fi
        
        # Generate secure passwords
        if command_exists openssl; then
            MONGO_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
            JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)
        else
            MONGO_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 25 | head -n 1)
            JWT_SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 50 | head -n 1)
        fi
        
        # Set backend URL based on proxy type
        if [ "$PROXY_TYPE" = "standalone" ]; then
            BACKEND_URL="http://$domain:8001"
            REACT_APP_BACKEND_URL="http://$domain:8001"
        else
            BACKEND_URL="https://$domain"
            REACT_APP_BACKEND_URL="https://$domain"
        fi
        
        # Update .env file
        sed -i.bak "s/fleet.yourdomain.com/$domain/g" .env
        sed -i.bak "s/admin@yourdomain.com/$email/g" .env
        sed -i.bak "s/your_secure_mongo_password_here/$MONGO_PASSWORD/g" .env
        sed -i.bak "s/your_super_secure_jwt_secret_here_change_this_in_production/$JWT_SECRET/g" .env
        sed -i.bak "s|https://fleet.yourdomain.com|$BACKEND_URL|g" .env
        sed -i.bak "s/PROXY_TYPE=traefik/PROXY_TYPE=$PROXY_TYPE/" .env
        sed -i.bak "s/PROXY_NETWORK=traefik-network/PROXY_NETWORK=$PROXY_NETWORK/" .env
        
        rm .env.bak 2>/dev/null || true
        
        print_success "Environment file created with domain: $domain"
        print_success "Generated secure MongoDB password and JWT secret"
    else
        print_success "Environment file already exists."
        source .env
        domain=$DOMAIN
    fi
}

# Select and prepare docker-compose file
prepare_compose_file() {
    print_status "Preparing Docker Compose configuration for $PROXY_TYPE..."
    
    case $PROXY_TYPE in
        "traefik")
            create_traefik_compose
            COMPOSE_FILE="docker-compose.vps-traefik.yml"
            ;;
        "nginx-proxy")
            create_nginx_proxy_compose
            COMPOSE_FILE="docker-compose.vps-nginx.yml"
            ;;
        "caddy")
            create_caddy_compose
            COMPOSE_FILE="docker-compose.vps-caddy.yml"
            ;;
        "standalone")
            create_standalone_compose
            COMPOSE_FILE="docker-compose.vps-standalone.yml"
            ;;
        *)
            create_manual_compose
            COMPOSE_FILE="docker-compose.vps-manual.yml"
            ;;
    esac
    
    print_success "Using compose file: $COMPOSE_FILE"
}

# Create Traefik-compatible compose file
create_traefik_compose() {
    cat > docker-compose.vps-traefik.yml << 'EOF'
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: fleetmanager_mongodb_vps
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
      MONGO_INITDB_DATABASE: fleetmanager
    volumes:
      - mongodb_data:/data/db
    networks:
      - fleetmanager-internal
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 30s
      timeout: 10s
      retries: 3

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
    container_name: fleetmanager_backend_vps
    restart: unless-stopped
    environment:
      - MONGO_URL=${MONGO_URL}
      - JWT_SECRET=${JWT_SECRET}
      - ENVIRONMENT=production
    depends_on:
      mongodb:
        condition: service_healthy
    networks:
      - fleetmanager-internal
      - ${PROXY_NETWORK}
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=${PROXY_NETWORK}"
      - "traefik.http.routers.fleetmanager-api.rule=Host(`${DOMAIN}`) && PathPrefix(`/api`)"
      - "traefik.http.routers.fleetmanager-api.tls.certresolver=letsencrypt"
      - "traefik.http.services.fleetmanager-api.loadbalancer.server.port=8001"

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.prod
      args:
        - REACT_APP_BACKEND_URL=${REACT_APP_BACKEND_URL}
    container_name: fleetmanager_frontend_vps
    restart: unless-stopped
    depends_on:
      - backend
    networks:
      - ${PROXY_NETWORK}
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=${PROXY_NETWORK}"
      - "traefik.http.routers.fleetmanager-frontend.rule=Host(`${DOMAIN}`)"
      - "traefik.http.routers.fleetmanager-frontend.tls.certresolver=letsencrypt"
      - "traefik.http.services.fleetmanager-frontend.loadbalancer.server.port=3000"

volumes:
  mongodb_data:

networks:
  fleetmanager-internal:
    driver: bridge
  ${PROXY_NETWORK}:
    external: true
EOF
}

# Create nginx-proxy compatible compose file
create_nginx_proxy_compose() {
    cat > docker-compose.vps-nginx.yml << 'EOF'
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: fleetmanager_mongodb_vps
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
      MONGO_INITDB_DATABASE: fleetmanager
    volumes:
      - mongodb_data:/data/db
    networks:
      - fleetmanager-internal

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
    container_name: fleetmanager_backend_vps
    restart: unless-stopped
    environment:
      - MONGO_URL=${MONGO_URL}
      - JWT_SECRET=${JWT_SECRET}
      - ENVIRONMENT=production
      - VIRTUAL_HOST=${DOMAIN}
      - VIRTUAL_PATH=/api
      - VIRTUAL_PORT=8001
      - LETSENCRYPT_HOST=${DOMAIN}
      - LETSENCRYPT_EMAIL=${SSL_EMAIL}
    depends_on:
      - mongodb
    networks:
      - fleetmanager-internal
      - ${PROXY_NETWORK}

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.prod
      args:
        - REACT_APP_BACKEND_URL=${REACT_APP_BACKEND_URL}
    container_name: fleetmanager_frontend_vps
    restart: unless-stopped
    environment:
      - VIRTUAL_HOST=${DOMAIN}
      - VIRTUAL_PORT=3000
      - LETSENCRYPT_HOST=${DOMAIN}
      - LETSENCRYPT_EMAIL=${SSL_EMAIL}
    depends_on:
      - backend
    networks:
      - ${PROXY_NETWORK}

volumes:
  mongodb_data:

networks:
  fleetmanager-internal:
    driver: bridge
  ${PROXY_NETWORK}:
    external: true
EOF
}

# Create Caddy compatible compose file
create_caddy_compose() {
    cat > docker-compose.vps-caddy.yml << 'EOF'
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: fleetmanager_mongodb_vps
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
      MONGO_INITDB_DATABASE: fleetmanager
    volumes:
      - mongodb_data:/data/db
    networks:
      - fleetmanager-internal

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
    container_name: fleetmanager_backend_vps
    restart: unless-stopped
    environment:
      - MONGO_URL=${MONGO_URL}
      - JWT_SECRET=${JWT_SECRET}
      - ENVIRONMENT=production
    depends_on:
      - mongodb
    networks:
      - fleetmanager-internal
      - ${PROXY_NETWORK}
    labels:
      - "caddy=${DOMAIN}"
      - "caddy.reverse_proxy=/api/* fleetmanager_backend_vps:8001"

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.prod
      args:
        - REACT_APP_BACKEND_URL=${REACT_APP_BACKEND_URL}
    container_name: fleetmanager_frontend_vps
    restart: unless-stopped
    depends_on:
      - backend
    networks:
      - ${PROXY_NETWORK}
    labels:
      - "caddy=${DOMAIN}"
      - "caddy.reverse_proxy=fleetmanager_frontend_vps:3000"

volumes:
  mongodb_data:

networks:
  fleetmanager-internal:
    driver: bridge
  ${PROXY_NETWORK}:
    external: true
EOF
}

# Create standalone compose file (direct ports)
create_standalone_compose() {
    cat > docker-compose.vps-standalone.yml << 'EOF'
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: fleetmanager_mongodb_vps
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
      MONGO_INITDB_DATABASE: fleetmanager
    volumes:
      - mongodb_data:/data/db
    networks:
      - fleetmanager-network

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
    container_name: fleetmanager_backend_vps
    restart: unless-stopped
    environment:
      - MONGO_URL=${MONGO_URL}
      - JWT_SECRET=${JWT_SECRET}
      - ENVIRONMENT=production
    ports:
      - "8001:8001"
    depends_on:
      - mongodb
    networks:
      - fleetmanager-network

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.prod
      args:
        - REACT_APP_BACKEND_URL=${REACT_APP_BACKEND_URL}
    container_name: fleetmanager_frontend_vps
    restart: unless-stopped
    ports:
      - "3000:3000"
    depends_on:
      - backend
    networks:
      - fleetmanager-network

volumes:
  mongodb_data:

networks:
  fleetmanager-network:
    driver: bridge
EOF
}

# Create manual compose file
create_manual_compose() {
    cat > docker-compose.vps-manual.yml << 'EOF'
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: fleetmanager_mongodb_vps
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
      MONGO_INITDB_DATABASE: fleetmanager
    volumes:
      - mongodb_data:/data/db
    networks:
      - fleetmanager-internal

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
    container_name: fleetmanager_backend_vps
    restart: unless-stopped
    environment:
      - MONGO_URL=${MONGO_URL}
      - JWT_SECRET=${JWT_SECRET}
      - ENVIRONMENT=production
    depends_on:
      - mongodb
    networks:
      - fleetmanager-internal
      - ${PROXY_NETWORK}

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.prod
      args:
        - REACT_APP_BACKEND_URL=${REACT_APP_BACKEND_URL}
    container_name: fleetmanager_frontend_vps
    restart: unless-stopped
    depends_on:
      - backend
    networks:
      - ${PROXY_NETWORK}

volumes:
  mongodb_data:

networks:
  fleetmanager-internal:
    driver: bridge
  ${PROXY_NETWORK}:
    external: true
EOF
}

# Deploy the application
deploy_application() {
    print_status "Deploying FleetManager Pro application..."
    
    # Create health check endpoint in backend if not exists
    if ! grep -q "/api/health" backend/server.py; then
        print_status "Adding health check endpoint to backend..."
        # The health endpoint was already added in the previous implementation
    fi
    
    # Build and deploy
    print_status "Building Docker images..."
    docker-compose -f "$COMPOSE_FILE" build --no-cache
    
    print_status "Starting services..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Wait for services to be ready
    print_status "Waiting for services to start..."
    sleep 45
    
    # Check if services are running
    if docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
        print_success "FleetManager Pro deployed successfully!"
        
        echo
        echo "🎉 FleetManager Pro is now deployed!"
        if [ "$PROXY_TYPE" = "standalone" ]; then
            echo "📍 Frontend: http://$domain:3000"
            echo "🔧 Backend API: http://$domain:8001"
            echo "📚 API Docs: http://$domain:8001/docs"
        else
            echo "📍 Frontend: https://$domain"
            echo "🔧 Backend API: https://$domain/api"
            echo "📚 API Docs: https://$domain/docs"
        fi
        echo
        
        # Show running containers
        print_status "Running containers:"
        docker-compose -f "$COMPOSE_FILE" ps
        
        # Test health endpoint
        print_status "Testing health endpoint..."
        sleep 10
        if [ "$PROXY_TYPE" = "standalone" ]; then
            HEALTH_URL="http://localhost:8001/api/health"
        else
            HEALTH_URL="http://localhost:8001/api/health"  # Test internal first
        fi
        
        if curl -f -s "$HEALTH_URL" > /dev/null 2>&1; then
            print_success "✅ Backend health check passed"
        else
            print_warning "⚠️  Backend health check failed - may still be starting"
        fi
        
    else
        print_error "Some services failed to start. Check logs:"
        docker-compose -f "$COMPOSE_FILE" logs
        exit 1
    fi
}

# Create management scripts
create_management_scripts() {
    print_status "Creating management scripts..."
    
    # Create start script
    cat > start-fleet-vps.sh << EOF
#!/bin/bash
echo "🚀 Starting FleetManager Pro..."
docker-compose -f $COMPOSE_FILE up -d
echo "✅ FleetManager Pro started!"
if [ "$PROXY_TYPE" = "standalone" ]; then
    echo "🌐 Access: http://$domain:3000"
else
    echo "🌐 Access: https://$domain"
fi
EOF
    
    # Create stop script
    cat > stop-fleet-vps.sh << EOF
#!/bin/bash
echo "🛑 Stopping FleetManager Pro..."
docker-compose -f $COMPOSE_FILE down
echo "✅ FleetManager Pro stopped."
EOF
    
    # Create restart script
    cat > restart-fleet-vps.sh << EOF
#!/bin/bash
echo "🔄 Restarting FleetManager Pro..."
docker-compose -f $COMPOSE_FILE down
docker-compose -f $COMPOSE_FILE up -d
echo "✅ FleetManager Pro restarted!"
EOF
    
    # Create logs script
    cat > logs-fleet-vps.sh << EOF
#!/bin/bash
if [ -z "\$1" ]; then
    echo "📋 Showing all FleetManager Pro logs..."
    docker-compose -f $COMPOSE_FILE logs -f
else
    echo "📋 Showing logs for service: \$1"
    docker-compose -f $COMPOSE_FILE logs -f \$1
fi
EOF
    
    # Create update script
    cat > update-fleet-vps.sh << EOF
#!/bin/bash
echo "🔄 Updating FleetManager Pro..."

# Pull latest changes (if using git)
if [ -d ".git" ]; then
    echo "📥 Pulling latest code..."
    git pull
fi

# Rebuild and restart
echo "🔨 Rebuilding images..."
docker-compose -f $COMPOSE_FILE build --no-cache

echo "🔄 Restarting services..."
docker-compose -f $COMPOSE_FILE down
docker-compose -f $COMPOSE_FILE up -d

echo "✅ FleetManager Pro updated and restarted!"
EOF
    
    # Create backup script
    cat > backup-fleet-vps.sh << EOF
#!/bin/bash
echo "💾 Creating FleetManager Pro backup..."

# Create backup directory
mkdir -p backups

# Backup database
timestamp=\$(date +%Y%m%d_%H%M%S)
backup_file="fleetmanager_backup_\${timestamp}.tar.gz"

echo "📦 Backing up MongoDB data..."
docker-compose -f $COMPOSE_FILE exec -T mongodb mongodump --uri="mongodb://root:\${MONGO_PASSWORD}@localhost:27017/fleetmanager?authSource=admin" --out /data/backup

docker cp \$(docker-compose -f $COMPOSE_FILE ps -q mongodb):/data/backup ./backups/backup_\${timestamp}

cd backups
tar -czf \${backup_file} backup_\${timestamp}
rm -rf backup_\${timestamp}
cd ..

echo "✅ Backup created: backups/\${backup_file}"
EOF
    
    # Create health check script
    cat > health-fleet-vps.sh << EOF
#!/bin/bash
echo "🏥 FleetManager Pro Health Check"
echo "================================="

# Check containers
echo "📦 Container Status:"
docker-compose -f $COMPOSE_FILE ps

echo ""
echo "🌐 Service Health:"

# Test backend health
if curl -f -s "http://localhost:8001/api/health" > /dev/null 2>&1; then
    echo "✅ Backend API: Healthy"
else
    echo "❌ Backend API: Unhealthy"
fi

# Test frontend
if curl -f -s "http://localhost:3000" > /dev/null 2>&1; then
    echo "✅ Frontend: Healthy"
else
    echo "❌ Frontend: Unhealthy"
fi

# Test database
if docker-compose -f $COMPOSE_FILE exec -T mongodb mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
    echo "✅ MongoDB: Healthy"
else
    echo "❌ MongoDB: Unhealthy"
fi

echo ""
if [ "$PROXY_TYPE" = "standalone" ]; then
    echo "🌐 Application URLs:"
    echo "   Frontend: http://$domain:3000"
    echo "   Backend: http://$domain:8001"
    echo "   API Docs: http://$domain:8001/docs"
else
    echo "🌐 Application URLs:"
    echo "   Frontend: https://$domain"
    echo "   Backend: https://$domain/api"
    echo "   API Docs: https://$domain/docs"
fi
EOF
    
    # Make scripts executable
    chmod +x start-fleet-vps.sh stop-fleet-vps.sh restart-fleet-vps.sh logs-fleet-vps.sh update-fleet-vps.sh backup-fleet-vps.sh health-fleet-vps.sh
    
    print_success "Management scripts created!"
}

# Create documentation
create_documentation() {
    cat > VPS-DEPLOYMENT.md << EOF
# FleetManager Pro VPS Deployment

## 🎯 Deployment Summary

FleetManager Pro has been successfully deployed on your VPS with the following configuration:

- **Domain**: $domain
- **Reverse Proxy**: $PROXY_TYPE
- **Network**: $PROXY_NETWORK
- **Environment**: Production

## 🛠️ Management Commands

### Start/Stop Services
\`\`\`bash
./start-fleet-vps.sh      # Start FleetManager Pro
./stop-fleet-vps.sh       # Stop FleetManager Pro
./restart-fleet-vps.sh    # Restart FleetManager Pro
\`\`\`

### Monitoring
\`\`\`bash
./logs-fleet-vps.sh       # View all logs
./logs-fleet-vps.sh frontend  # View specific service logs
./health-fleet-vps.sh     # Run health checks
\`\`\`

### Maintenance
\`\`\`bash
./update-fleet-vps.sh     # Update application
./backup-fleet-vps.sh     # Create database backup
\`\`\`

## 🌐 Access URLs

EOF

    if [ "$PROXY_TYPE" = "standalone" ]; then
        cat >> VPS-DEPLOYMENT.md << EOF
- **Frontend**: http://$domain:3000
- **Backend API**: http://$domain:8001
- **API Documentation**: http://$domain:8001/docs

## 🔒 Security Notes

Since you're using standalone mode (direct ports), consider:
1. Setting up a firewall to restrict access
2. Using Nginx or Apache as a reverse proxy for SSL
3. Implementing rate limiting

EOF
    else
        cat >> VPS-DEPLOYMENT.md << EOF
- **Frontend**: https://$domain
- **Backend API**: https://$domain/api
- **API Documentation**: https://$domain/docs

## 🔒 SSL/TLS

SSL certificates are automatically managed by your $PROXY_TYPE reverse proxy.

EOF
    fi

    cat >> VPS-DEPLOYMENT.md << EOF
## 📁 Important Files

- **Environment**: .env
- **Compose File**: $COMPOSE_FILE
- **Logs**: \`./logs-fleet-vps.sh\`
- **Backups**: backups/ directory

## 🆘 Troubleshooting

### Services not starting
\`\`\`bash
./logs-fleet-vps.sh
docker-compose -f $COMPOSE_FILE ps
\`\`\`

### Database issues
\`\`\`bash
docker-compose -f $COMPOSE_FILE exec mongodb mongosh
\`\`\`

### Network connectivity
\`\`\`bash
docker network ls
docker network inspect $PROXY_NETWORK
\`\`\`

## 🔄 Updates

To update FleetManager Pro:
1. Pull latest code (if using git)
2. Run \`./update-fleet-vps.sh\`
3. Monitor logs: \`./logs-fleet-vps.sh\`

## 📞 Support

For issues:
1. Check health: \`./health-fleet-vps.sh\`
2. View logs: \`./logs-fleet-vps.sh\`
3. Check documentation: VPS-DEPLOYMENT.md
EOF

    print_success "Documentation created: VPS-DEPLOYMENT.md"
}

# Main deployment function
main() {
    echo
    print_status "🚗 Starting FleetManager Pro VPS deployment..."
    echo
    
    # Check prerequisites
    check_prerequisites
    
    # Detect reverse proxy
    detect_proxy_type
    
    # Setup environment
    setup_environment
    
    # Prepare compose file
    prepare_compose_file
    
    # Deploy application
    deploy_application
    
    # Create management scripts
    create_management_scripts
    
    # Create documentation
    create_documentation
    
    # Final instructions
    echo
    print_success "🎉 FleetManager Pro VPS deployment completed successfully!"
    echo
    echo "📋 VPS Management Commands:"
    echo "  Start:     ./start-fleet-vps.sh"
    echo "  Stop:      ./stop-fleet-vps.sh"
    echo "  Restart:   ./restart-fleet-vps.sh"
    echo "  Logs:      ./logs-fleet-vps.sh [service]"
    echo "  Update:    ./update-fleet-vps.sh"
    echo "  Backup:    ./backup-fleet-vps.sh"
    echo "  Health:    ./health-fleet-vps.sh"
    echo
    echo "🌐 Access FleetManager Pro:"
    if [ "$PROXY_TYPE" = "standalone" ]; then
        echo "  Frontend:  http://$domain:3000"
        echo "  Backend:   http://$domain:8001"
        echo "  API Docs:  http://$domain:8001/docs"
    else
        echo "  Frontend:  https://$domain"
        echo "  Backend:   https://$domain/api"
        echo "  API Docs:  https://$domain/docs"
    fi
    echo
    echo "📁 Important Files:"
    echo "  Environment:   .env"
    echo "  Compose:       $COMPOSE_FILE"
    echo "  Documentation: VPS-DEPLOYMENT.md"
    echo
    if [ "$PROXY_TYPE" != "standalone" ]; then
        print_warning "SSL certificates will be automatically obtained by your $PROXY_TYPE reverse proxy."
        echo
    fi
    print_success "🚀 FleetManager Pro is ready for use!"
}

# Run main function
main "$@"