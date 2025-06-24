#!/bin/bash

# MongoDB Health Check Debug Script
# This script helps debug MongoDB container health issues

set -e

echo "🔍 MongoDB Health Check Debug"
echo "============================="

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

# Check if Docker is running
print_step "Checking Docker availability..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running"
    exit 1
fi

print_success "Docker is available"

# Check if any MongoDB containers are running
print_step "Checking running MongoDB containers..."
MONGO_CONTAINERS=$(docker ps --filter "ancestor=mongo:7.0" --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "")

if [ -z "$MONGO_CONTAINERS" ]; then
    print_warning "No MongoDB containers are currently running"
    echo ""
    echo "To start MongoDB containers:"
    echo "  ./docker-start.sh docker-prod"
    echo "  ./docker-start.sh docker-dev"
    exit 0
else
    print_success "Found MongoDB containers:"
    echo "$MONGO_CONTAINERS"
fi

# Test health check commands
print_step "Testing MongoDB health check commands..."

# Get container name
CONTAINER_NAME=$(docker ps --filter "ancestor=mongo:7.0" --format "{{.Names}}" | head -1)

if [ -n "$CONTAINER_NAME" ]; then
    print_step "Testing health check on container: $CONTAINER_NAME"
    
    # Test 1: Check if mongosh is available
    echo "Test 1: Checking if mongosh is available..."
    if docker exec "$CONTAINER_NAME" which mongosh &>/dev/null; then
        print_success "mongosh is available in container"
        MONGOSH_VERSION=$(docker exec "$CONTAINER_NAME" mongosh --version 2>/dev/null || echo "unknown")
        echo "  Version: $MONGOSH_VERSION"
    else
        print_warning "mongosh not found, checking for legacy mongo..."
        if docker exec "$CONTAINER_NAME" which mongo &>/dev/null; then
            print_success "Legacy mongo command is available"
            MONGO_VERSION=$(docker exec "$CONTAINER_NAME" mongo --version 2>/dev/null || echo "unknown")
            echo "  Version: $MONGO_VERSION"
        else
            print_error "Neither mongosh nor mongo command found"
        fi
    fi
    
    # Test 2: Test simple connection
    echo ""
    echo "Test 2: Testing simple MongoDB connection..."
    if docker exec "$CONTAINER_NAME" mongosh --eval "db.adminCommand('ping')" &>/dev/null; then
        print_success "Simple ping command works"
    elif docker exec "$CONTAINER_NAME" mongosh localhost:27017/test --quiet --eval "quit(db.runCommand('ping').ok ? 0 : 2)" &>/dev/null; then
        print_success "Enhanced ping command works"
    else
        print_error "MongoDB ping commands failed"
        echo "Trying to get more info..."
        docker exec "$CONTAINER_NAME" mongosh --eval "db.adminCommand('ping')" 2>&1 || true
    fi
    
    # Test 3: Check container logs for errors
    echo ""
    echo "Test 3: Checking container logs for errors..."
    ERROR_LOGS=$(docker logs "$CONTAINER_NAME" 2>&1 | grep -i error | tail -5 || echo "No errors found")
    if [ "$ERROR_LOGS" = "No errors found" ]; then
        print_success "No errors in container logs"
    else
        print_warning "Found errors in logs:"
        echo "$ERROR_LOGS"
    fi
    
    # Test 4: Check health check status
    echo ""
    echo "Test 4: Current container health status..."
    HEALTH_STATUS=$(docker inspect "$CONTAINER_NAME" --format='{{.State.Health.Status}}' 2>/dev/null || echo "no health check")
    if [ "$HEALTH_STATUS" = "healthy" ]; then
        print_success "Container is healthy"
    elif [ "$HEALTH_STATUS" = "unhealthy" ]; then
        print_error "Container is unhealthy"
        
        # Get last health check logs
        echo "Last health check logs:"
        docker inspect "$CONTAINER_NAME" --format='{{range .State.Health.Log}}{{.Output}}{{end}}' 2>/dev/null | tail -3 || echo "No health check logs available"
    elif [ "$HEALTH_STATUS" = "starting" ]; then
        print_warning "Container health check is still starting"
    else
        print_warning "No health check configured or unknown status: $HEALTH_STATUS"
    fi
fi

echo ""
echo "Suggested fixes if MongoDB is unhealthy:"
echo "1. MongoDB 7.0 containers often don't have mongosh/mongo - use process check instead"
echo "2. Use simplified health check: ps aux | grep mongod"
echo "3. Use alternative configurations without health checks"
echo "4. Apply the MongoDB health fix: ./fix-mongodb-health.sh"
echo ""
echo "Alternative health check configurations:"
echo "Option 1 (Process check - Recommended):"
echo '  test: ["CMD-SHELL", "ps aux | grep mongod | grep -v grep || exit 1"]'
echo ""
echo "Option 2 (No health check):"
echo "  # Remove healthcheck section entirely"
echo ""
echo "Option 3 (Use fixed configuration):"
echo '  docker-compose -f docker-compose-fixed.yml up -d'