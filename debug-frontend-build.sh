#!/bin/bash

# Comprehensive Frontend Build Troubleshooter

echo "🔍 Frontend Build Troubleshooter"
echo "================================"

echo "🧪 Testing frontend build step by step..."

# Test 1: Check if required files exist
echo ""
echo "📁 Step 1: Checking required files..."
echo "Checking index.html..."
if [ -f "frontend/public/index.html" ]; then
    echo "✅ index.html exists"
else
    echo "❌ index.html missing"
fi

echo "Checking package.json..."
if [ -f "frontend/package.json" ]; then
    echo "✅ package.json exists"
else
    echo "❌ package.json missing"
fi

echo "Checking App.js..."
if [ -f "frontend/src/App.js" ]; then
    echo "✅ App.js exists"
else
    echo "❌ App.js missing"
fi

# Test 2: Check .dockerignore
echo ""
echo "📄 Step 2: Checking .dockerignore..."
if grep -q "^public$" frontend/.dockerignore 2>/dev/null; then
    echo "❌ .dockerignore excludes 'public' directory"
    echo "Fixing..."
    sed -i 's/^public$/#public/' frontend/.dockerignore
    echo "✅ Fixed .dockerignore"
else
    echo "✅ .dockerignore looks good"
fi

# Test 3: Test development Dockerfile
echo ""
echo "🔨 Step 3: Testing development Dockerfile..."
if docker build -t fleetmanager-frontend-dev -f frontend/Dockerfile frontend/; then
    echo "✅ Development Dockerfile builds successfully"
    docker rmi fleetmanager-frontend-dev 2>/dev/null || true
else
    echo "❌ Development Dockerfile failed"
fi

# Test 4: Test production Dockerfile
echo ""
echo "🏭 Step 4: Testing production Dockerfile..."
if docker build -t fleetmanager-frontend-prod -f frontend/Dockerfile.prod --build-arg REACT_APP_BACKEND_URL=https://localhost frontend/; then
    echo "✅ Production Dockerfile builds successfully"
    docker rmi fleetmanager-frontend-prod 2>/dev/null || true
else
    echo "❌ Production Dockerfile failed"
    echo ""
    echo "Let's try building with more verbose output..."
    docker build -t fleetmanager-frontend-prod -f frontend/Dockerfile.prod --build-arg REACT_APP_BACKEND_URL=https://localhost --progress=plain frontend/
fi

# Test 5: Check local yarn build
echo ""
echo "🧶 Step 5: Testing local yarn build..."
cd frontend
if [ -f "yarn.lock" ]; then
    echo "Installing dependencies..."
    yarn install --frozen-lockfile
    
    echo "Testing build..."
    if REACT_APP_BACKEND_URL=https://localhost yarn build; then
        echo "✅ Local yarn build successful"
        rm -rf build  # Clean up
    else
        echo "❌ Local yarn build failed"
    fi
else
    echo "❌ yarn.lock not found"
fi
cd ..

echo ""
echo "📋 Build Troubleshooting Summary:"
echo "================================="

# Final recommendations
echo ""
echo "🛠️  If you're still getting errors, try:"
echo ""
echo "1. Complete cleanup and rebuild:"
echo "   docker-compose down -v"
echo "   docker system prune -f"
echo "   docker-compose up --build"
echo ""
echo "2. Build just the frontend:"
echo "   docker build -f frontend/Dockerfile.prod frontend/"
echo ""
echo "3. Check for specific error messages and run:"
echo "   docker build --no-cache -f frontend/Dockerfile.prod frontend/"
echo ""
echo "4. If Node.js version issues persist:"
echo "   cd frontend && rm -rf node_modules yarn.lock"
echo "   cd .. && docker-compose up --build"

echo ""
echo "Please share the specific error message you're seeing for more targeted help!"