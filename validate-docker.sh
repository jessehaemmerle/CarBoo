#!/bin/bash

# Docker Configuration Validation Script
# Validates that all Docker files and configurations are properly set up

echo "🔍 Fleet Management System - Docker Configuration Validation"
echo "==========================================================="

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass_count=0
fail_count=0
warn_count=0

# Function to print test results
test_pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    ((pass_count++))
}

test_fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    ((fail_count++))
}

test_warn() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
    ((warn_count++))
}

test_info() {
    echo -e "${BLUE}ℹ️  INFO${NC}: $1"
}

echo "Running Docker configuration validation tests..."
echo ""

# Test 1: Check if essential Docker files exist
echo "📁 Testing Docker file presence..."

if [ -f "docker-compose.yml" ]; then
    test_pass "docker-compose.yml exists"
else
    test_fail "docker-compose.yml missing"
fi

if [ -f "docker-compose.dev.yml" ]; then
    test_pass "docker-compose.dev.yml exists"
else
    test_fail "docker-compose.dev.yml missing"
fi

if [ -f "backend/Dockerfile" ]; then
    test_pass "backend/Dockerfile exists"
else
    test_fail "backend/Dockerfile missing"
fi

if [ -f "backend/Dockerfile.prod" ]; then
    test_pass "backend/Dockerfile.prod exists"
else
    test_fail "backend/Dockerfile.prod missing"
fi

if [ -f "frontend/Dockerfile" ]; then
    test_pass "frontend/Dockerfile exists"
else
    test_fail "frontend/Dockerfile missing"
fi

if [ -f "frontend/Dockerfile.prod" ]; then
    test_pass "frontend/Dockerfile.prod exists"
else
    test_fail "frontend/Dockerfile.prod missing"
fi

echo ""

# Test 2: Check dependency files
echo "📦 Testing dependency files..."

if [ -f "backend/requirements.txt" ]; then
    test_pass "backend/requirements.txt exists"
    
    # Check for essential packages
    if grep -q "fastapi" backend/requirements.txt; then
        test_pass "FastAPI found in requirements.txt"
    else
        test_fail "FastAPI missing from requirements.txt"
    fi
    
    if grep -q "uvicorn" backend/requirements.txt; then
        test_pass "Uvicorn found in requirements.txt"
    else
        test_fail "Uvicorn missing from requirements.txt"
    fi
    
    if grep -q "pymongo" backend/requirements.txt; then
        test_pass "PyMongo found in requirements.txt"
    else
        test_fail "PyMongo missing from requirements.txt"
    fi
else
    test_fail "backend/requirements.txt missing"
fi

if [ -f "frontend/package.json" ]; then
    test_pass "frontend/package.json exists"
    
    # Check for essential packages
    if grep -q "react" frontend/package.json; then
        test_pass "React found in package.json"
    else
        test_fail "React missing from package.json"
    fi
    
    if grep -q "react-scripts" frontend/package.json; then
        test_pass "React Scripts found in package.json"
    else
        test_fail "React Scripts missing from package.json"
    fi
else
    test_fail "frontend/package.json missing"
fi

echo ""

# Test 3: Check Docker Compose configuration
echo "🐳 Testing Docker Compose configurations..."

# Test production compose
if command -v docker-compose &> /dev/null; then
    if docker-compose config &> /dev/null; then
        test_pass "docker-compose.yml syntax is valid"
    else
        test_fail "docker-compose.yml has syntax errors"
    fi
    
    if docker-compose -f docker-compose.dev.yml config &> /dev/null; then
        test_pass "docker-compose.dev.yml syntax is valid"
    else
        test_fail "docker-compose.dev.yml has syntax errors"
    fi
else
    test_warn "Docker Compose not available for syntax validation"
fi

# Check service definitions
if grep -q "mongodb:" docker-compose.yml; then
    test_pass "MongoDB service defined in production compose"
else
    test_fail "MongoDB service missing from production compose"
fi

if grep -q "backend:" docker-compose.yml; then
    test_pass "Backend service defined in production compose"
else
    test_fail "Backend service missing from production compose"
fi

if grep -q "frontend:" docker-compose.yml; then
    test_pass "Frontend service defined in production compose"
else
    test_fail "Frontend service missing from production compose"
fi

echo ""

# Test 4: Check environment configuration
echo "⚙️  Testing environment configuration..."

if [ -f ".env.example" ]; then
    test_pass ".env.example template exists"
    
    # Check for essential variables
    if grep -q "MONGO_PASSWORD" .env.example; then
        test_pass "MONGO_PASSWORD template found"
    else
        test_fail "MONGO_PASSWORD missing from template"
    fi
    
    if grep -q "JWT_SECRET" .env.example; then
        test_pass "JWT_SECRET template found"
    else
        test_fail "JWT_SECRET missing from template"
    fi
    
    if grep -q "REACT_APP_BACKEND_URL" .env.example; then
        test_pass "REACT_APP_BACKEND_URL template found"
    else
        test_fail "REACT_APP_BACKEND_URL missing from template"
    fi
else
    test_fail ".env.example template missing"
fi

if [ -f ".env" ]; then
    test_info ".env file exists (good for Docker deployment)"
else
    test_info ".env file not found (will be created automatically)"
fi

echo ""

# Test 5: Check management scripts
echo "🛠️  Testing management scripts..."

if [ -f "docker-start.sh" ]; then
    test_pass "docker-start.sh management script exists"
    
    if [ -x "docker-start.sh" ]; then
        test_pass "docker-start.sh is executable"
    else
        test_warn "docker-start.sh is not executable (run: chmod +x docker-start.sh)"
    fi
else
    test_fail "docker-start.sh management script missing"
fi

if [ -f "setup.sh" ]; then
    test_pass "setup.sh script exists"
    
    if [ -x "setup.sh" ]; then
        test_pass "setup.sh is executable"
    else
        test_warn "setup.sh is not executable (run: chmod +x setup.sh)"
    fi
else
    test_warn "setup.sh script missing"
fi

echo ""

# Test 6: Check for potential issues
echo "🚨 Testing for potential issues..."

# Check for hardcoded URLs in compose files
if grep -E "localhost|127\.0\.0\.1" docker-compose.yml | grep -v -E "BACKEND_URL|REACT_APP_BACKEND_URL"; then
    test_warn "Hardcoded localhost/127.0.0.1 found in docker-compose.yml"
else
    test_pass "No hardcoded localhost in docker-compose.yml"
fi

# Check port conflicts
if grep -q "3000:3000" docker-compose.yml && grep -q "3000:3000" docker-compose.dev.yml; then
    test_pass "Consistent port mapping for frontend (3000)"
else
    test_warn "Inconsistent frontend port mapping between compose files"
fi

if grep -q "8001:8001" docker-compose.yml && grep -q "8001:8001" docker-compose.dev.yml; then
    test_pass "Consistent port mapping for backend (8001)"
else
    test_warn "Inconsistent backend port mapping between compose files"
fi

# Check for volume definitions
if grep -q "volumes:" docker-compose.yml; then
    test_pass "Volume definitions found in production compose"
else
    test_warn "No volume definitions in production compose"
fi

if grep -q "volumes:" docker-compose.dev.yml; then
    test_pass "Volume definitions found in development compose"
    
    # Check for source code mounting in dev
    if grep -q "\./frontend:/app" docker-compose.dev.yml; then
        test_pass "Frontend source mounting configured for development"
    else
        test_warn "Frontend source mounting not configured for development"
    fi
    
    if grep -q "\./backend:/app" docker-compose.dev.yml; then
        test_pass "Backend source mounting configured for development"
    else
        test_warn "Backend source mounting not configured for development"
    fi
else
    test_warn "No volume definitions in development compose"
fi

echo ""

# Test 7: Check current system compatibility
echo "💻 Testing system compatibility..."

if command -v docker &> /dev/null; then
    test_pass "Docker is installed and available"
    
    if docker info &> /dev/null 2>&1; then
        test_pass "Docker daemon is running"
    else
        test_warn "Docker daemon is not running or not accessible"
    fi
else
    test_warn "Docker is not installed"
fi

if command -v docker-compose &> /dev/null; then
    test_pass "Docker Compose is installed and available"
else
    test_warn "Docker Compose is not installed"
fi

echo ""

# Final summary
echo "📊 VALIDATION SUMMARY"
echo "===================="
echo -e "${GREEN}✅ Passed: $pass_count${NC}"
echo -e "${RED}❌ Failed: $fail_count${NC}"
echo -e "${YELLOW}⚠️  Warnings: $warn_count${NC}"

echo ""

if [ $fail_count -eq 0 ]; then
    echo -e "${GREEN}🎉 All critical tests passed! Your Docker setup is ready.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Install Docker and Docker Compose if not already installed"
    echo "2. Run: ./docker-start.sh docker-dev"
    echo "3. Access your application at http://localhost:3000"
else
    echo -e "${RED}🚨 Some critical tests failed. Please fix the issues above.${NC}"
fi

if [ $warn_count -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  There are $warn_count warnings to review.${NC}"
fi

echo ""
echo "For help with Docker setup, run: ./docker-start.sh help"
echo "For detailed documentation, see: DOCKER_README.md"