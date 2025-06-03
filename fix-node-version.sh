#!/bin/bash

# Quick fix for Node.js version compatibility issue
# This script updates and tests the frontend build

echo "🔧 Fixing Node.js version compatibility..."

# Clean up any existing containers and images
echo "🧹 Cleaning up old containers and images..."
docker-compose down 2>/dev/null || true
docker rmi $(docker images | grep fleetmanager | awk '{print $3}') 2>/dev/null || true

echo "✅ Node.js version updated from 18 to 20 in Dockerfiles"

# Test the build
echo "🔨 Testing frontend build with Node.js 20..."
docker build -t fleetmanager-frontend-test ./frontend/

if [ $? -eq 0 ]; then
    echo "✅ Frontend build successful with Node.js 20!"
    echo ""
    echo "🚀 You can now run the application:"
    echo "   ./setup.sh prod"
    echo "   OR"
    echo "   ./domain-manager.sh setup-traefik"
    echo "   ./domain-manager.sh deploy-fleet"
    echo ""
    
    # Clean up test image
    docker rmi fleetmanager-frontend-test 2>/dev/null || true
    
else
    echo "❌ Frontend build failed. Check the error above."
    echo ""
    echo "💡 If you still get errors, try:"
    echo "   1. Delete node_modules: rm -rf frontend/node_modules"
    echo "   2. Update package.json to use compatible versions"
    echo "   3. Rebuild: docker-compose up --build"
fi

echo ""
echo "📋 What was fixed:"
echo "   - Updated frontend/Dockerfile: node:18-alpine → node:20-alpine"
echo "   - Updated frontend/Dockerfile.prod: node:18-alpine → node:20-alpine"
echo "   - react-router-dom@7.5.1 now compatible with Node.js 20"