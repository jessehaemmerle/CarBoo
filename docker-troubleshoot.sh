#!/bin/bash

# Docker Troubleshooting Script for Fleet Management System
# This script helps diagnose and fix common Docker deployment issues

set -e

echo "🔧 Fleet Management System - Docker Troubleshooting"
echo "=================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check Docker installation and status
check_docker() {
    print_info "Checking Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        return 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed"
        return 1
    fi
    
    print_status "Docker is properly installed and running"
    return 0
}

# Check and create environment file
check_environment() {
    print_info "Checking environment configuration..."
    
    if [ ! -f .env ]; then
        print_warning ".env file not found, creating from template..."
        
        if [ -f .env.example ]; then
            cp .env.example .env
            
            # Generate secure passwords
            MONGO_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
            JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)
            
            # Update .env file
            sed -i "s/your-secure-mongodb-password-here/$MONGO_PASSWORD/g" .env
            sed -i "s/your-super-secure-jwt-secret-key-minimum-32-characters-long/$JWT_SECRET/g" .env
            sed -i "s/your-server-ip/localhost/g" .env
            
            print_status ".env file created with secure passwords"
        else
            print_error ".env.example template not found"
            return 1
        fi
    else
        print_status ".env file exists"
    fi
    
    # Validate required environment variables
    if ! grep -q "MONGO_PASSWORD=" .env; then
        print_error "MONGO_PASSWORD not found in .env"
        return 1
    fi
    
    if ! grep -q "JWT_SECRET=" .env; then
        print_error "JWT_SECRET not found in .env"
        return 1
    fi
    
    print_status "Environment configuration is valid"
    return 0
}

# Check Docker Compose syntax
check_compose_syntax() {
    print_info "Validating Docker Compose configuration..."
    
    if docker-compose config &> /dev/null; then
        print_status "Docker Compose configuration is valid"
    else
        print_error "Docker Compose configuration has errors:"
        docker-compose config
        return 1
    fi
    
    return 0
}

# Check for port conflicts
check_ports() {
    print_info "Checking for port conflicts..."
    
    ports=(3000 8001 27017)
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            print_warning "Port $port is already in use"
        else
            print_status "Port $port is available"
        fi
    done
}

# Check container health
check_container_health() {
    print_info "Checking container health..."
    
    containers=$(docker-compose ps -q 2>/dev/null)
    if [ -z "$containers" ]; then
        print_warning "No containers are running"
        return 0
    fi
    
    for container in $containers; do
        container_name=$(docker inspect --format '{{.Name}}' $container | sed 's/\///')
        health_status=$(docker inspect --format '{{.State.Health.Status}}' $container 2>/dev/null || echo "no-health-check")
        
        if [ "$health_status" = "healthy" ]; then
            print_status "$container_name is healthy"
        elif [ "$health_status" = "unhealthy" ]; then
            print_error "$container_name is unhealthy"
            
            # Show last health check logs
            print_info "Last health check log for $container_name:"
            docker inspect --format '{{range .State.Health.Log}}{{.Output}}{{end}}' $container | tail -n 5
        elif [ "$health_status" = "starting" ]; then
            print_warning "$container_name is still starting up"
        else
            print_info "$container_name has no health check configured"
        fi
    done
}

# Show container logs
show_logs() {
    local service=$1
    print_info "Showing logs for $service..."
    echo "----------------------------------------"
    docker-compose logs --tail=20 $service
    echo "----------------------------------------"
}

# Fix backend health issues
fix_backend_health() {
    print_info "Attempting to fix backend health issues..."
    
    # Check if backend container exists
    backend_container=$(docker-compose ps -q backend 2>/dev/null)
    if [ -z "$backend_container" ]; then
        print_error "Backend container not found"
        return 1
    fi
    
    # Check backend logs
    print_info "Backend container logs:"
    show_logs backend
    
    # Test health endpoint manually
    print_info "Testing health endpoint..."
    if docker exec $backend_container curl -f http://localhost:8001/api/health &>/dev/null; then
        print_status "Health endpoint is responding"
    else
        print_error "Health endpoint is not responding"
        
        # Check if FastAPI is running
        if docker exec $backend_container ps aux | grep -q uvicorn; then
            print_info "Uvicorn process is running"
        else
            print_error "Uvicorn process is not running"
        fi
    fi
}

# Main troubleshooting function
main() {
    case "${1:-check}" in
        "check")
            echo "🔍 Running comprehensive Docker health check..."
            echo
            
            check_docker || exit 1
            echo
            
            check_environment || exit 1
            echo
            
            check_compose_syntax || exit 1
            echo
            
            check_ports
            echo
            
            check_container_health
            echo
            
            print_status "Health check completed"
            ;;
            
        "fix-backend")
            echo "🔧 Attempting to fix backend issues..."
            echo
            
            check_docker || exit 1
            fix_backend_health
            ;;
            
        "logs")
            service=${2:-""}
            if [ -z "$service" ]; then
                print_info "Available services: mongodb, backend, frontend"
                print_info "Usage: ./docker-troubleshoot.sh logs <service>"
            else
                show_logs $service
            fi
            ;;
            
        "restart")
            print_info "Restarting Docker services..."
            docker-compose down
            sleep 2
            docker-compose up -d
            print_status "Services restarted"
            ;;
            
        "clean")
            print_warning "This will remove all containers, images, and volumes"
            read -p "Are you sure? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                docker-compose down -v --remove-orphans
                docker system prune -f
                print_status "Cleanup completed"
            fi
            ;;
            
        "help"|*)
            echo "Usage: ./docker-troubleshoot.sh [command]"
            echo
            echo "Commands:"
            echo "  check        Run comprehensive health check (default)"
            echo "  fix-backend  Attempt to fix backend health issues"
            echo "  logs <service>  Show logs for specific service"
            echo "  restart      Restart all Docker services"
            echo "  clean        Clean up all Docker resources"
            echo "  help         Show this help message"
            ;;
    esac
}

# Run main function
main "$@"