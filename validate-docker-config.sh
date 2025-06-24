#!/bin/bash

# Docker Configuration Validation Script
# This script validates all Docker configuration files and environment settings

echo "🚗 Fleet Management - Docker Configuration Validator"
echo "==================================================="

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    PASSED=$((PASSED + 1))
}

print_fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    FAILED=$((FAILED + 1))
}

print_warn() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
}

# Test 1: Check if all required Docker files exist
print_test "Checking Docker configuration files..."

if [ -f "docker-compose.yml" ]; then
    print_pass "docker-compose.yml exists"
else
    print_fail "docker-compose.yml missing"
fi

if [ -f "docker-compose.dev.yml" ]; then
    print_pass "docker-compose.dev.yml exists"
else
    print_fail "docker-compose.dev.yml missing"
fi

if [ -f "docker-compose.prod.yml" ]; then
    print_pass "docker-compose.prod.yml exists"
else
    print_fail "docker-compose.prod.yml missing"
fi

if [ -f "docker-start.sh" ] && [ -x "docker-start.sh" ]; then
    print_pass "docker-start.sh exists and is executable"
else
    print_fail "docker-start.sh missing or not executable"
fi

# Test 2: Check environment files
print_test "Checking environment configuration files..."

if [ -f ".env" ]; then
    print_pass ".env file exists"
    
    # Check for required variables in .env
    if grep -q "FRONTEND_HOST_PORT=80" .env; then
        print_pass "FRONTEND_HOST_PORT=80 configured correctly"
    else
        print_fail "FRONTEND_HOST_PORT=80 not found in .env"
    fi
    
    if grep -q "DB_NAME=fleetmanager" .env; then
        print_pass "DB_NAME=fleetmanager configured correctly"
    else
        print_fail "DB_NAME=fleetmanager not found in .env"
    fi
    
    if grep -q "MONGO_PASSWORD=" .env; then
        print_pass "MONGO_PASSWORD configured"
    else
        print_fail "MONGO_PASSWORD not configured"
    fi
    
    if grep -q "JWT_SECRET=" .env; then
        print_pass "JWT_SECRET configured"
    else
        print_fail "JWT_SECRET not configured"
    fi
else
    print_fail ".env file missing"
fi

if [ -f "frontend/.env" ]; then
    print_pass "frontend/.env exists"
    
    if grep -q "REACT_APP_BACKEND_URL=http://localhost:8001" frontend/.env; then
        print_pass "Frontend backend URL configured for Docker"
    else
        print_fail "Frontend backend URL not configured correctly for Docker"
    fi
else
    print_fail "frontend/.env missing"
fi

if [ -f "backend/.env" ]; then
    print_pass "backend/.env exists"
    
    if grep -q "DB_NAME=\"fleetmanager\"" backend/.env; then
        print_pass "Backend database name configured correctly"
    else
        print_fail "Backend database name not configured correctly"
    fi
else
    print_fail "backend/.env missing"
fi

# Test 3: Check Dockerfile configurations
print_test "Checking Dockerfile configurations..."

for dockerfile in "frontend/Dockerfile" "frontend/Dockerfile.prod" "backend/Dockerfile" "backend/Dockerfile.prod"; do
    if [ -f "$dockerfile" ]; then
        print_pass "$dockerfile exists"
    else
        print_fail "$dockerfile missing"
    fi
done

# Test 4: Check Docker Compose configurations
print_test "Checking Docker Compose service configurations..."

# Check production compose
if grep -q "FRONTEND_HOST_PORT.*:80" docker-compose.yml; then
    print_pass "Production frontend port mapping configured correctly"
else
    print_fail "Production frontend port mapping not configured for port 80"
fi

if grep -q "service_healthy" docker-compose.yml; then
    print_pass "Production health check dependencies configured"
else
    print_fail "Production health check dependencies missing"
fi

# Check development compose
if grep -q "FRONTEND_HOST_PORT.*:3000" docker-compose.dev.yml; then
    print_pass "Development frontend port mapping configurable"
else
    print_fail "Development frontend port mapping not configurable"
fi

# Test 5: Check health check endpoints
print_test "Checking health check endpoints..."

if [ -f "frontend/public/health" ]; then
    print_pass "Frontend health check endpoint exists"
else
    print_fail "Frontend health check endpoint missing"
fi

if grep -q "/api/health" backend/server.py; then
    print_pass "Backend health check endpoint exists"
else
    print_fail "Backend health check endpoint missing"
fi

# Test 6: Validate Docker Compose files syntax
print_test "Validating Docker Compose syntax..."

if command -v docker-compose >/dev/null 2>&1; then
    if docker-compose -f docker-compose.yml config >/dev/null 2>&1; then
        print_pass "docker-compose.yml syntax valid"
    else
        print_fail "docker-compose.yml syntax invalid"
    fi
    
    if docker-compose -f docker-compose.dev.yml config >/dev/null 2>&1; then
        print_pass "docker-compose.dev.yml syntax valid"
    else
        print_fail "docker-compose.dev.yml syntax invalid"
    fi
else
    print_warn "Docker Compose not available - skipping syntax validation"
fi

# Test 7: Check port configuration consistency
print_test "Checking port configuration consistency..."

if grep -q "localhost:80" docker-start.sh; then
    print_pass "Docker start script shows correct production port (80)"
else
    print_fail "Docker start script doesn't show correct production port (80)"
fi

# Summary
echo ""
echo "=========================================="
echo "🏁 Validation Summary"
echo "=========================================="
echo -e "${GREEN}✅ Tests Passed: ${PASSED}${NC}"
echo -e "${RED}❌ Tests Failed: ${FAILED}${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Docker configuration is ready for deployment.${NC}"
    echo ""
    echo "To deploy with frontend on port 80:"
    echo "  ./docker-start.sh docker-prod"
    echo ""
    echo "To deploy development mode:"
    echo "  ./docker-start.sh docker-dev"
    exit 0
else
    echo -e "${RED}⚠️  ${FAILED} test(s) failed. Please fix the issues above before deployment.${NC}"
    exit 1
fi