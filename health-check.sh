#!/bin/bash

# Fleet Management System Health Check
echo "🏥 Fleet Management System Health Check"
echo "======================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if containers are running
echo "📦 Checking container status..."

containers=("fleet_mongodb" "fleet_backend" "fleet_frontend")
all_healthy=true

for container in "${containers[@]}"; do
    if docker ps --format "table {{.Names}}" | grep -q "$container"; then
        status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
        if [ "$status" = "running" ]; then
            echo -e "  ✅ ${GREEN}$container${NC}: Running"
        else
            echo -e "  ❌ ${RED}$container${NC}: $status"
            all_healthy=false
        fi
    else
        echo -e "  ❌ ${RED}$container${NC}: Not found"
        all_healthy=false
    fi
done

echo ""
echo "🌐 Checking service endpoints..."

# Check backend health
if curl -s -f http://localhost:8001/docs > /dev/null 2>&1; then
    echo -e "  ✅ ${GREEN}Backend API${NC}: Healthy (http://localhost:8001)"
else
    echo -e "  ❌ ${RED}Backend API${NC}: Not responding"
    all_healthy=false
fi

# Check frontend health
if curl -s -f http://localhost:3000 > /dev/null 2>&1; then
    echo -e "  ✅ ${GREEN}Frontend${NC}: Healthy (http://localhost:3000)"
else
    echo -e "  ❌ ${RED}Frontend${NC}: Not responding"
    all_healthy=false
fi

# Check database connectivity
echo ""
echo "🗄️  Checking database connectivity..."

if docker exec fleet_mongodb mongosh --eval "db.adminCommand('ping')" fleet_db > /dev/null 2>&1; then
    echo -e "  ✅ ${GREEN}MongoDB${NC}: Connected"
else
    echo -e "  ❌ ${RED}MongoDB${NC}: Connection failed"
    all_healthy=false
fi

# Resource usage
echo ""
echo "📊 Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(docker ps --format "{{.Names}}" | grep fleet_)

echo ""
if [ "$all_healthy" = true ]; then
    echo -e "🎉 ${GREEN}All systems healthy!${NC}"
    exit 0
else
    echo -e "⚠️  ${YELLOW}Some services are not healthy. Check the logs for more details:${NC}"
    echo "   docker-compose logs"
    exit 1
fi