#!/bin/bash

# Fix for "group nginx is in use" error

echo "🔧 Fixing nginx group conflict..."

echo "✅ ISSUE IDENTIFIED:"
echo "   nginx:alpine image already has nginx user/group"
echo "   Dockerfile.prod was trying to create them again"

echo ""
echo "✅ SOLUTION APPLIED:"
echo "   - Removed duplicate nginx user/group creation"
echo "   - Added proper permission setting for existing nginx user"
echo "   - Uses built-in nginx user from nginx:alpine image"

echo ""
echo "🧹 Cleaning up old build artifacts..."
# Remove any existing containers and images that might have the old configuration
docker-compose down 2>/dev/null || true
docker rmi $(docker images | grep fleetmanager | grep frontend | awk '{print $3}') 2>/dev/null || true

echo ""
echo "🚀 Ready to build! Try one of these commands:"
echo ""
echo "Option 1 - Clean build:"
echo "   docker-compose up --build"
echo ""
echo "Option 2 - Setup script:"
echo "   ./setup.sh prod"
echo ""
echo "Option 3 - Test frontend build only:"
echo "   docker build -f frontend/Dockerfile.prod frontend/"
echo ""

echo "📋 What was fixed in frontend/Dockerfile.prod:"
echo "   ❌ Before: addgroup -g 1001 -S nginx (conflicted with existing group)"
echo "   ✅ After:  chown -R nginx:nginx (uses existing nginx user/group)"

echo ""
echo "🔍 The nginx group conflict should now be resolved!"