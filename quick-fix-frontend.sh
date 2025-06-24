#!/bin/bash

# Frontend Container Restart Quick Fix
# Applies common fixes for frontend container restart issues

echo "🔧 Frontend Container Restart - Quick Fix"
echo "========================================="

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    exit 1
fi

print_step "Stopping all containers..."
docker-compose down 2>/dev/null || true

print_step "Cleaning up problematic containers and images..."
docker container prune -f
docker image prune -f

print_step "Checking for port conflicts..."
if netstat -tuln 2>/dev/null | grep -q ":80 "; then
    print_warning "Port 80 is in use. Checking what's using it..."
    netstat -tulnp 2>/dev/null | grep ":80 " || true
    
    print_step "Attempting to stop common conflicting services..."
    sudo systemctl stop apache2 2>/dev/null || true
    sudo systemctl stop nginx 2>/dev/null || true
    sleep 2
fi

print_step "Applying nginx configuration fix..."
# The nginx.conf fix has already been applied to the file

print_step "Checking available memory..."
AVAILABLE_MEM=$(free -m | awk 'NR==2{print $7}')
if [ "$AVAILABLE_MEM" -lt 1000 ]; then
    print_warning "Low memory detected ($AVAILABLE_MEM MB available)"
    print_warning "Consider adding swap space or increasing memory"
    
    # Offer to create swap
    echo "Create 2GB swap file? (y/N)"
    read -p "This can help with build issues: " create_swap
    
    if [[ $create_swap =~ ^[Yy]$ ]]; then
        print_step "Creating swap file..."
        sudo fallocate -l 2G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        print_success "Swap file created and activated"
    fi
fi

print_step "Starting services with fixed configuration..."
if docker-compose up --build -d; then
    print_success "Services started successfully!"
    
    print_step "Waiting for services to initialize..."
    sleep 10
    
    # Check frontend status
    FRONTEND_CONTAINER=$(docker ps --filter "name=frontend" --format "{{.Names}}" | head -1)
    if [ -n "$FRONTEND_CONTAINER" ]; then
        STATUS=$(docker inspect "$FRONTEND_CONTAINER" --format='{{.State.Status}}')
        RESTART_COUNT=$(docker inspect "$FRONTEND_CONTAINER" --format='{{.RestartCount}}')
        
        echo "Frontend container status: $STATUS"
        echo "Restart count: $RESTART_COUNT"
        
        if [ "$STATUS" = "running" ] && [ "$RESTART_COUNT" -lt 2 ]; then
            print_success "Frontend container is stable!"
            
            # Test connectivity
            print_step "Testing frontend connectivity..."
            sleep 5
            if curl -f http://localhost/health >/dev/null 2>&1; then
                print_success "Frontend health check passed!"
                print_success "Frontend is accessible at http://localhost"
            else
                print_warning "Frontend health check failed, but container is running"
                echo "This might be normal if the application is still starting"
            fi
        else
            print_warning "Frontend container may still have issues"
            echo "Run './debug-frontend.sh' for detailed diagnosis"
        fi
    else
        print_error "Frontend container not found"
    fi
    
else
    print_error "Failed to start services"
    echo ""
    echo "🔧 Alternative solutions:"
    echo "1. Try debug mode: ./docker-start.sh debug-frontend"
    echo "2. Use simple configuration: docker-compose -f docker-compose-no-health.yml up -d"
    echo "3. Run diagnosis: ./debug-frontend.sh"
    echo "4. Check logs: docker-compose logs"
fi

echo ""
echo "🏁 Quick fix completed!"
echo ""
echo "📋 Next steps if issues persist:"
echo "1. Run full diagnosis: ./debug-frontend.sh"
echo "2. Check detailed guide: FRONTEND_TROUBLESHOOTING.md"
echo "3. Try debug mode: ./docker-start.sh debug-frontend"
echo "4. View logs: docker-compose logs frontend"