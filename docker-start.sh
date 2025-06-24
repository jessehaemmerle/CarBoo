#!/bin/bash

# Fleet Management System - Docker Setup Script
# This script helps switch between supervisor-based and Docker-based deployment

set -e

echo "🚗 Fleet Management System - Docker Setup"
echo "=========================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed."
        echo ""
        echo "🚀 Auto-Installation Options:"
        echo "1. Quick installation (Ubuntu/Debian only)"
        echo "2. Full installation (all Linux distributions)"
        echo "3. Manual installation"
        echo "4. Exit"
        echo ""
        read -p "Choose option (1-4): " install_choice
        
        case $install_choice in
            1)
                print_info "Starting quick Docker installation..."
                if [ -f "./quick-install-docker.sh" ]; then
                    ./quick-install-docker.sh
                else
                    print_error "Quick install script not found"
                    return 1
                fi
                ;;
            2)
                print_info "Starting full Docker installation..."
                if [ -f "./install-docker.sh" ]; then
                    ./install-docker.sh
                else
                    print_error "Full install script not found"
                    return 1
                fi
                ;;
            3)
                echo "Manual installation: https://docs.docker.com/get-docker/"
                return 1
                ;;
            4)
                return 1
                ;;
            *)
                print_error "Invalid choice"
                return 1
                ;;
        esac
        
        print_info "Please restart this script after Docker installation completes"
        return 1
    fi

    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker service."
        print_info "Try: sudo systemctl start docker"
        return 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed."
        print_info "Install Docker Compose: https://docs.docker.com/compose/install/"
        return 1
    fi

    print_status "Docker and Docker Compose are available"
    return 0
}

# Stop supervisor services
stop_supervisor() {
    print_info "Stopping supervisor services..."
    sudo supervisorctl stop all || true
    print_status "Supervisor services stopped"
}

# Start supervisor services
start_supervisor() {
    print_info "Starting supervisor services..."
    sudo supervisorctl restart all
    print_status "Supervisor services started"
}

# Create environment file for Docker
create_docker_env() {
    if [ ! -f .env ]; then
        print_info "Creating .env file for Docker..."
        
        # Generate secure passwords
        MONGO_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)
        
        cat > .env << EOF
# Fleet Management System - Docker Environment Configuration
# Generated on $(date)

# Database Configuration
MONGO_PASSWORD=${MONGO_PASSWORD}
DB_NAME=fleetmanager

# Security Configuration  
JWT_SECRET=${JWT_SECRET}

# Backend Configuration
BACKEND_URL=http://localhost:8001
ENVIRONMENT=production

# Frontend Configuration
REACT_APP_BACKEND_URL=http://localhost:8001
FRONTEND_HOST_PORT=80
EOF
        
        print_status ".env file created with secure configuration"
    else
        print_status ".env file already exists"
    fi
}

# Function to show service status
show_status() {
    echo ""
    print_info "Current Service Status:"
    echo "======================="
    
    if check_docker && docker-compose ps 2>/dev/null | grep -q "Up"; then
        echo "🐳 Docker Services:"
        docker-compose ps
    else
        echo "🐳 Docker Services: Not running"
    fi
    
    echo ""
    echo "🔧 Supervisor Services:"
    sudo supervisorctl status || true
}

# Function to display help
show_help() {
    echo ""
    echo "🚀 Available commands:"
    echo "  ./docker-start.sh docker-dev     - Start Docker development environment"
    echo "  ./docker-start.sh docker-prod    - Start Docker production environment"
    echo "  ./docker-start.sh supervisor     - Switch back to supervisor mode"
    echo "  ./docker-start.sh stop-docker    - Stop Docker services"
    echo "  ./docker-start.sh logs           - View Docker logs"
    echo "  ./docker-start.sh status         - Show all services status"
    echo "  ./docker-start.sh clean          - Clean Docker containers and volumes"
    echo "  ./docker-start.sh help           - Show this help"
    echo ""
    echo "🔧 Current Setup Information:"
    echo "  • Supervisor mode: Services run via supervisor (current default)"
    echo "  • Docker mode: Services run in containers"
    echo "  • Both modes use the same application code"
    echo "  • Switch between modes as needed"
}

# Main command handling
case "${1:-help}" in
    "docker-dev")
        if ! check_docker; then
            exit 1
        fi
        
        print_info "Switching to Docker development mode..."
        stop_supervisor
        create_docker_env
        
        print_info "Starting Docker development environment..."
        docker-compose -f docker-compose.dev.yml down || true
        docker-compose -f docker-compose.dev.yml up --build -d
        
        print_status "Docker development environment started!"
        echo ""
        print_info "Services are now running in Docker containers with hot reload"
        print_info "Frontend: http://localhost:3000"
        print_info "Backend API: http://localhost:8001"
        print_info "API Docs: http://localhost:8001/docs"
        ;;
        
    "docker-prod")
        if ! check_docker; then
            exit 1
        fi
        
        print_info "Switching to Docker production mode..."
        stop_supervisor
        create_docker_env
        
        print_info "Starting Docker production environment..."
        docker-compose down || true
        
        # Try main compose first, fall back to alternatives if MongoDB health issues
        echo ""
        print_info "Starting services with health checks..."
        if ! docker-compose up --build -d; then
            print_warning "Startup failed. This might be due to MongoDB health check issues."
            echo ""
            echo "🔧 Alternative startup options:"
            echo "1. Use TCP-based health checks (recommended)"
            echo "2. Use no health check dependencies"
            echo "3. Debug MongoDB health issues"
            echo "4. Continue with current setup"
            echo ""
            read -p "Choose option (1-4): " health_choice
            
            case $health_choice in
                1)
                    print_info "Using TCP-based health checks..."
                    docker-compose down || true
                    docker-compose -f docker-compose-tcp-health.yml up --build -d
                    ;;
                2)
                    print_info "Using simplified startup without health dependencies..."
                    docker-compose down || true
                    docker-compose -f docker-compose-no-health.yml up --build -d
                    ;;
                3)
                    print_info "Starting MongoDB health debug..."
                    if [ -f "./debug-mongodb-health.sh" ]; then
                        ./debug-mongodb-health.sh
                    else
                        print_error "Debug script not found"
                    fi
                    echo "See MONGODB_HEALTH_TROUBLESHOOTING.md for detailed help"
                    exit 1
                    ;;
                4)
                    print_info "Continuing with current setup..."
                    ;;
                *)
                    print_error "Invalid choice"
                    exit 1
                    ;;
            esac
        fi
        
        print_status "Docker production environment started!"
        echo ""
        print_info "Services are now running in optimized Docker containers"
        print_info "Frontend: http://localhost:80"
        print_info "Backend API: http://localhost:8001"
        print_info "API Docs: http://localhost:8001/docs"
        
        # Check if services are healthy
        sleep 5
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "unhealthy"; then
            print_warning "Some services may be unhealthy. Run './debug-mongodb-health.sh' for help"
        fi
        
        # Check specifically for frontend restart issues
        FRONTEND_CONTAINER=$(docker ps --filter "name=frontend" --format "{{.Names}}" | head -1)
        if [ -n "$FRONTEND_CONTAINER" ]; then
            RESTART_COUNT=$(docker inspect "$FRONTEND_CONTAINER" --format='{{.RestartCount}}' 2>/dev/null || echo "0")
            if [ "$RESTART_COUNT" -gt 2 ]; then
                print_warning "Frontend container has restarted $RESTART_COUNT times"
                echo ""
                echo "🔧 Frontend troubleshooting options:"
                echo "1. Run frontend debug script: ./debug-frontend.sh"
                echo "2. Use debug configuration: docker-compose -f docker-compose-frontend-debug.yml up -d"
                echo "3. Check troubleshooting guide: FRONTEND_TROUBLESHOOTING.md"
            fi
        fi
        ;;
        
    "supervisor")
        print_info "Switching to supervisor mode..."
        
        if check_docker; then
            print_info "Stopping Docker services..."
            docker-compose down || true
            docker-compose -f docker-compose.dev.yml down || true
        fi
        
        start_supervisor
        
        print_status "Supervisor mode activated!"
        echo ""
        print_info "Services are now running via supervisor"
        print_info "Frontend: http://localhost:3000"
        print_info "Backend API: http://localhost:8001"
        ;;
        
    "stop-docker")
        if ! check_docker; then
            exit 1
        fi
        
        print_info "Stopping Docker services..."
        docker-compose down || true
        docker-compose -f docker-compose.dev.yml down || true
        print_status "Docker services stopped"
        ;;
        
    "logs")
        if ! check_docker; then
            exit 1
        fi
        
        print_info "Viewing Docker logs (press Ctrl+C to exit)..."
        if docker-compose ps 2>/dev/null | grep -q "Up"; then
            docker-compose logs -f
        elif docker-compose -f docker-compose.dev.yml ps 2>/dev/null | grep -q "Up"; then
            docker-compose -f docker-compose.dev.yml logs -f
        else
            print_warning "No Docker services are currently running"
        fi
        ;;
        
    "status")
        show_status
        ;;
        
    "clean")
        if ! check_docker; then
            exit 1
        fi
        
        print_warning "This will remove all Docker containers, images, and volumes for this project"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Cleaning up Docker resources..."
            docker-compose down -v --remove-orphans || true
            docker-compose -f docker-compose.dev.yml down -v --remove-orphans || true
            
            # Remove project-specific images
            docker images | grep fleetmanager | awk '{print $3}' | xargs docker rmi -f || true
            
            print_status "Docker cleanup completed!"
        else
            print_info "Cleanup cancelled"
        fi
        ;;
        
    "help"|*)
        show_help
        ;;
esac

# Show status after most operations
if [[ "$1" =~ ^(docker-dev|docker-prod|supervisor)$ ]]; then
    echo ""
    show_status
fi