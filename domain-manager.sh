#!/bin/bash

# Complete Multi-Domain Manager
# Manages Traefik reverse proxy and multiple applications

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}🌐 Multi-Domain Manager${NC}"
    echo -e "${CYAN}================================${NC}"
}

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

print_header

# Show help
show_help() {
    echo -e "${PURPLE}🚀 Multi-Domain Manager Commands:${NC}"
    echo ""
    echo -e "${CYAN}Traefik Management:${NC}"
    echo "  setup-traefik        Initialize Traefik reverse proxy"
    echo "  start-traefik        Start Traefik service"
    echo "  stop-traefik         Stop Traefik service"
    echo "  traefik-status       Show Traefik status"
    echo ""
    echo -e "${CYAN}FleetManager Management:${NC}"
    echo "  deploy-fleet         Deploy FleetManager Pro"
    echo "  stop-fleet           Stop FleetManager Pro"
    echo "  restart-fleet        Restart FleetManager Pro"
    echo "  fleet-logs           View FleetManager logs"
    echo "  fleet-status         Show FleetManager status"
    echo ""
    echo -e "${CYAN}General Commands:${NC}"
    echo "  status               Show all services status"
    echo "  logs                 View all logs"
    echo "  health               Run health checks"
    echo "  cleanup              Clean up unused resources"
    echo "  help                 Show this help"
    echo ""
    echo -e "${PURPLE}📋 Quick Start:${NC}"
    echo "1. ./domain-manager.sh setup-traefik"
    echo "2. ./domain-manager.sh deploy-fleet"
    echo "3. ./domain-manager.sh status"
}

# Setup Traefik
setup_traefik() {
    print_status "Setting up Traefik reverse proxy..."
    
    # Create network
    if ! docker network ls | grep -q "traefik-network"; then
        print_status "Creating Traefik network..."
        docker network create traefik-network
        print_success "Traefik network created"
    else
        print_success "Traefik network already exists"
    fi
    
    # Create Traefik config if not exists
    if [ ! -f .env.traefik ]; then
        print_status "Creating Traefik configuration..."
        cp .env.traefik.example .env.traefik
        print_warning "Please edit .env.traefik with your domain and email!"
        print_status "Opening .env.traefik for editing..."
        ${EDITOR:-nano} .env.traefik
    fi
    
    # Start Traefik
    print_status "Starting Traefik..."
    docker-compose -f traefik-only.yml --env-file .env.traefik up -d
    
    # Wait for Traefik to be ready
    print_status "Waiting for Traefik to start..."
    sleep 10
    
    if docker ps | grep -q "traefik"; then
        print_success "Traefik is running!"
        
        # Load config
        source .env.traefik
        echo ""
        echo -e "${GREEN}🎉 Traefik Setup Complete!${NC}"
        echo -e "${CYAN}Dashboard:${NC} https://traefik.${MAIN_DOMAIN}"
        echo -e "${CYAN}Network:${NC} traefik-network"
        echo ""
        print_warning "Make sure your DNS records point to this server!"
    else
        print_error "Traefik failed to start. Check logs with: docker logs traefik"
    fi
}

# Start Traefik
start_traefik() {
    if [ ! -f .env.traefik ]; then
        print_error ".env.traefik not found. Run setup-traefik first."
        exit 1
    fi
    
    print_status "Starting Traefik..."
    docker-compose -f traefik-only.yml --env-file .env.traefik up -d
    print_success "Traefik started"
}

# Stop Traefik
stop_traefik() {
    print_status "Stopping Traefik..."
    docker-compose -f traefik-only.yml down
    print_success "Traefik stopped"
}

# Traefik status
traefik_status() {
    print_status "Traefik status:"
    if docker ps | grep -q "traefik"; then
        print_success "Traefik is running"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep traefik
        
        if [ -f .env.traefik ]; then
            source .env.traefik
            echo ""
            echo -e "${CYAN}Dashboard:${NC} https://traefik.${MAIN_DOMAIN}"
        fi
    else
        print_warning "Traefik is not running"
    fi
    
    echo ""
    print_status "Traefik network:"
    docker network ls | grep traefik || print_warning "Traefik network not found"
}

# Deploy FleetManager
deploy_fleet() {
    # Check if Traefik is running
    if ! docker ps | grep -q "traefik"; then
        print_error "Traefik is not running. Start it first with: setup-traefik"
        exit 1
    fi
    
    # Check if network exists
    if ! docker network ls | grep -q "traefik-network"; then
        print_error "Traefik network not found. Run setup-traefik first."
        exit 1
    fi
    
    # Create FleetManager config if not exists
    if [ ! -f .env.domain ]; then
        print_status "Creating FleetManager domain configuration..."
        cat > .env.domain << 'EOF'
# FleetManager Pro Domain Configuration
DOMAIN=fleet.yourdomain.com
ACME_EMAIL=admin@yourdomain.com
MONGO_PASSWORD=secure-mongo-password-here
JWT_SECRET=secure-jwt-secret-key-here
ENVIRONMENT=production
EOF
        print_warning "Please edit .env.domain with your FleetManager domain!"
        ${EDITOR:-nano} .env.domain
    fi
    
    # Load config
    source .env.domain
    
    if [ "$DOMAIN" = "fleet.yourdomain.com" ]; then
        print_error "Please configure your domain in .env.domain"
        exit 1
    fi
    
    # Generate passwords if needed
    if [[ "$MONGO_PASSWORD" == *"secure-mongo"* ]]; then
        NEW_MONGO_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        sed -i "s/secure-mongo-password-here/$NEW_MONGO_PASSWORD/g" .env.domain
        print_success "Generated secure MongoDB password"
    fi
    
    if [[ "$JWT_SECRET" == *"secure-jwt"* ]]; then
        NEW_JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)
        sed -i "s/secure-jwt-secret-key-here/$NEW_JWT_SECRET/g" .env.domain
        print_success "Generated secure JWT secret"
    fi
    
    # Deploy FleetManager
    print_status "Deploying FleetManager Pro on domain: $DOMAIN"
    docker-compose -f docker-compose.traefik.yml --env-file .env.domain up -d --build
    
    print_success "FleetManager Pro deployed!"
    echo ""
    echo -e "${GREEN}🎉 FleetManager Pro is Live!${NC}"
    echo -e "${CYAN}URL:${NC} https://$DOMAIN"
    echo -e "${CYAN}API:${NC} https://$DOMAIN/api"
    echo -e "${CYAN}Docs:${NC} https://$DOMAIN/docs"
    echo ""
    print_warning "SSL certificate will be generated automatically (may take 1-2 minutes)"
}

# Stop FleetManager
stop_fleet() {
    if [ -f .env.domain ]; then
        print_status "Stopping FleetManager Pro..."
        docker-compose -f docker-compose.traefik.yml --env-file .env.domain down
        print_success "FleetManager Pro stopped"
    else
        print_error ".env.domain not found"
    fi
}

# Restart FleetManager
restart_fleet() {
    if [ -f .env.domain ]; then
        print_status "Restarting FleetManager Pro..."
        docker-compose -f docker-compose.traefik.yml --env-file .env.domain restart
        print_success "FleetManager Pro restarted"
    else
        print_error ".env.domain not found"
    fi
}

# FleetManager logs
fleet_logs() {
    if [ -f .env.domain ]; then
        print_status "FleetManager logs (press Ctrl+C to exit):"
        docker-compose -f docker-compose.traefik.yml --env-file .env.domain logs -f
    else
        print_error ".env.domain not found"
    fi
}

# FleetManager status
fleet_status() {
    if [ -f .env.domain ]; then
        print_status "FleetManager status:"
        docker-compose -f docker-compose.traefik.yml --env-file .env.domain ps
        
        source .env.domain
        echo ""
        echo -e "${CYAN}Application URL:${NC} https://$DOMAIN"
        
        # Test connectivity
        if curl -s -f "https://$DOMAIN" > /dev/null 2>&1; then
            print_success "Application is responding"
        else
            print_warning "Application may not be accessible yet"
        fi
    else
        print_warning "FleetManager not configured (.env.domain not found)"
    fi
}

# Overall status
show_status() {
    echo -e "${PURPLE}📊 Complete System Status${NC}"
    echo "================================"
    
    traefik_status
    echo ""
    fleet_status
    
    echo ""
    print_status "Docker resources:"
    docker system df
}

# View all logs
view_logs() {
    print_status "All service logs (press Ctrl+C to exit):"
    docker logs traefik --tail=50 -f &
    TRAEFIK_PID=$!
    
    if [ -f .env.domain ]; then
        docker-compose -f docker-compose.traefik.yml --env-file .env.domain logs --tail=50 -f &
        FLEET_PID=$!
    fi
    
    # Wait for Ctrl+C
    trap "kill $TRAEFIK_PID $FLEET_PID 2>/dev/null" EXIT
    wait
}

# Health check
health_check() {
    print_status "Running health checks..."
    
    # Check Traefik
    if docker ps | grep -q "traefik"; then
        print_success "✓ Traefik is running"
    else
        print_error "✗ Traefik is not running"
    fi
    
    # Check FleetManager
    if docker ps | grep -q "fleetmanager"; then
        print_success "✓ FleetManager containers are running"
        
        if [ -f .env.domain ]; then
            source .env.domain
            
            # Test backend
            if curl -s -f "https://$DOMAIN/api/health" > /dev/null 2>&1; then
                print_success "✓ Backend API is responding"
            else
                print_warning "⚠ Backend API may not be ready"
            fi
            
            # Test frontend
            if curl -s -f "https://$DOMAIN" > /dev/null 2>&1; then
                print_success "✓ Frontend is responding"
            else
                print_warning "⚠ Frontend may not be ready"
            fi
        fi
    else
        print_warning "⚠ FleetManager is not running"
    fi
    
    # Check network
    if docker network ls | grep -q "traefik-network"; then
        print_success "✓ Traefik network exists"
    else
        print_error "✗ Traefik network not found"
    fi
    
    # Check ports
    if sudo netstat -tlnp | grep -q ":80\|:443"; then
        print_success "✓ Ports 80/443 are in use (good)"
    else
        print_warning "⚠ Ports 80/443 not in use"
    fi
}

# Cleanup
cleanup() {
    print_warning "This will remove unused Docker resources"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleaning up Docker resources..."
        docker system prune -f
        print_success "Cleanup completed"
    fi
}

# Main command handling
case "${1:-help}" in
    "setup-traefik")
        setup_traefik
        ;;
    "start-traefik")
        start_traefik
        ;;
    "stop-traefik")
        stop_traefik
        ;;
    "traefik-status")
        traefik_status
        ;;
    "deploy-fleet")
        deploy_fleet
        ;;
    "stop-fleet")
        stop_fleet
        ;;
    "restart-fleet")
        restart_fleet
        ;;
    "fleet-logs")
        fleet_logs
        ;;
    "fleet-status")
        fleet_status
        ;;
    "status")
        show_status
        ;;
    "logs")
        view_logs
        ;;
    "health")
        health_check
        ;;
    "cleanup")
        cleanup
        ;;
    "help"|*)
        show_help
        ;;
esac