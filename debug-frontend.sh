#!/bin/bash

# Frontend Container Debug Script
# Diagnoses frontend container restart issues

set -e

echo "🚀 Frontend Container Debug & Fix Tool"
echo "======================================"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_info() {
    echo -e "${PURPLE}ℹ️${NC} $1"
}

# Check if Docker is running
print_step "Checking Docker environment..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running"
    exit 1
fi

print_success "Docker is available"

# Check for frontend containers
print_step "Checking frontend containers..."
FRONTEND_CONTAINERS=$(docker ps -a --filter "name=frontend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "")

if [ -z "$FRONTEND_CONTAINERS" ]; then
    print_warning "No frontend containers found"
    echo "Make sure you've started the Docker environment:"
    echo "  ./docker-start.sh docker-prod"
    exit 1
else
    echo "$FRONTEND_CONTAINERS"
fi

# Get frontend container name
CONTAINER_NAME=$(docker ps -a --filter "name=frontend" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER_NAME" ]; then
    print_error "No frontend container found"
    exit 1
fi

print_info "Analyzing container: $CONTAINER_NAME"

# Check container status
print_step "Analyzing container status..."
CONTAINER_STATUS=$(docker inspect "$CONTAINER_NAME" --format='{{.State.Status}}')
RESTART_COUNT=$(docker inspect "$CONTAINER_NAME" --format='{{.RestartCount}}')
EXIT_CODE=$(docker inspect "$CONTAINER_NAME" --format='{{.State.ExitCode}}')

echo "Status: $CONTAINER_STATUS"
echo "Restart Count: $RESTART_COUNT"
echo "Exit Code: $EXIT_CODE"

if [ "$RESTART_COUNT" -gt 5 ]; then
    print_error "Container has restarted $RESTART_COUNT times - there's definitely an issue"
elif [ "$RESTART_COUNT" -gt 0 ]; then
    print_warning "Container has restarted $RESTART_COUNT times"
fi

# Check container logs
print_step "Analyzing container logs..."
echo "Last 50 lines of container logs:"
echo "================================"
docker logs --tail 50 "$CONTAINER_NAME" 2>&1 || print_error "Could not retrieve logs"
echo "================================"

# Check for common error patterns
print_step "Checking for common error patterns..."

LOG_OUTPUT=$(docker logs "$CONTAINER_NAME" 2>&1 || echo "")

# Common error patterns
if echo "$LOG_OUTPUT" | grep -qi "EADDRINUSE"; then
    print_error "Port conflict detected - port is already in use"
    echo "Solution: Check if port 80 or 3000 is occupied by another service"
elif echo "$LOG_OUTPUT" | grep -qi "permission denied"; then
    print_error "Permission error detected"
    echo "Solution: Check file permissions and user context"
elif echo "$LOG_OUTPUT" | grep -qi "ENOMEM\|out of memory"; then
    print_error "Memory issue detected"
    echo "Solution: Increase available memory or use multi-stage build"
elif echo "$LOG_OUTPUT" | grep -qi "MODULE_NOT_FOUND\|Cannot find module"; then
    print_error "Missing dependencies detected"
    echo "Solution: Check package.json and Docker build process"
elif echo "$LOG_OUTPUT" | grep -qi "ENOENT"; then
    print_error "File not found error detected"
    echo "Solution: Check file paths and Docker context"
elif echo "$LOG_OUTPUT" | grep -qi "nginx"; then
    print_warning "Nginx-related logs found - checking nginx configuration"
elif echo "$LOG_OUTPUT" | grep -qi "build failed\|compilation failed"; then
    print_error "Build failure detected"
    echo "Solution: Check build dependencies and Node.js version"
else
    print_info "No obvious error patterns found in logs"
fi

# Check system resources
print_step "Checking system resources..."
echo "Memory usage:"
free -h
echo ""
echo "Disk usage:"
df -h /
echo ""

# Check port conflicts
print_step "Checking port conflicts..."
if netstat -tuln 2>/dev/null | grep -q ":80 "; then
    PORT_80_PROCESS=$(netstat -tulnp 2>/dev/null | grep ":80 " || echo "Unknown process")
    print_warning "Port 80 is in use:"
    echo "$PORT_80_PROCESS"
else
    print_success "Port 80 is available"
fi

# Check Docker build context
print_step "Checking Docker build context..."
if [ -f "frontend/Dockerfile" ]; then
    print_success "Frontend Dockerfile found"
    echo "Dockerfile content:"
    echo "==================="
    head -20 frontend/Dockerfile
    echo "==================="
else
    print_error "Frontend Dockerfile not found"
fi

if [ -f "frontend/Dockerfile.prod" ]; then
    print_success "Production Dockerfile found"
else
    print_warning "Production Dockerfile not found"
fi

# Check package.json
print_step "Checking package.json..."
if [ -f "frontend/package.json" ]; then
    print_success "package.json found"
    
    NODE_VERSION=$(grep '"node"' frontend/package.json || echo "not specified")
    echo "Node version requirement: $NODE_VERSION"
    
    SCRIPTS=$(jq -r '.scripts // {} | keys[]' frontend/package.json 2>/dev/null || echo "Could not parse scripts")
    echo "Available scripts: $SCRIPTS"
else
    print_error "package.json not found in frontend directory"
fi

# Check environment variables
print_step "Checking environment variables..."
if [ -f "frontend/.env" ]; then
    print_success "Frontend .env file found"
    echo "Environment variables:"
    cat frontend/.env
else
    print_warning "Frontend .env file not found"
fi

# Test manual build
print_step "Testing manual frontend build..."
echo "Would you like to test a manual frontend build? (y/N)"
read -p "This will take a few minutes: " test_build

if [[ $test_build =~ ^[Yy]$ ]]; then
    print_info "Building frontend manually..."
    if docker build -t test-frontend-build frontend/; then
        print_success "Manual build successful"
        docker rmi test-frontend-build 2>/dev/null || true
    else
        print_error "Manual build failed"
        echo "This confirms there's an issue with the build process"
    fi
fi

# Provide solutions
echo ""
echo "🔧 RECOMMENDED SOLUTIONS"
echo "========================"

if [ "$RESTART_COUNT" -gt 3 ]; then
    echo "1. IMMEDIATE FIX - Use alternative frontend configuration:"
    echo "   docker-compose -f docker-compose-frontend-debug.yml up -d frontend"
    echo ""
    echo "2. MEMORY FIX - If build fails due to memory:"
    echo "   - Increase Docker memory limit"
    echo "   - Use multi-stage build with smaller base image"
    echo ""
    echo "3. PORT FIX - If port 80 is occupied:"
    echo "   sudo systemctl stop apache2 nginx"
    echo "   # or change FRONTEND_HOST_PORT in .env"
    echo ""
    echo "4. DEPENDENCY FIX - Rebuild with clean cache:"
    echo "   docker-compose down"
    echo "   docker system prune -f"
    echo "   docker-compose up --build -d"
    echo ""
    echo "5. DEBUG MODE - Run frontend in debug mode:"
    echo "   docker run -it --rm -p 3000:3000 -v \$(pwd)/frontend:/app <frontend-image> /bin/bash"
fi

echo ""
echo "📋 NEXT STEPS:"
echo "1. Review the logs above for specific error messages"
echo "2. Try the recommended solutions based on the errors found"
echo "3. Check the generated debug configurations"
echo "4. If issues persist, check FRONTEND_TROUBLESHOOTING.md"

echo ""
print_info "Debug completed. Check the output above for specific issues and solutions."