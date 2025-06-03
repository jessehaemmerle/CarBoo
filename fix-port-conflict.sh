#!/bin/bash

# Port Conflict Resolver for Traefik Setup
# This script helps identify and resolve port conflicts

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}🔧 Port Conflict Resolver${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header

echo "Diagnosing port conflicts..."
echo ""

# Check what's using ports 80 and 443
print_status "Checking what's using ports 80 and 443:"
echo ""

# Port 80
print_status "Port 80 usage:"
PORT80_PROCESS=$(sudo lsof -i :80 2>/dev/null || echo "")
if [ -n "$PORT80_PROCESS" ]; then
    echo "$PORT80_PROCESS"
    PORT80_IN_USE=true
else
    print_success "Port 80 is available"
    PORT80_IN_USE=false
fi

echo ""

# Port 443
print_status "Port 443 usage:"
PORT443_PROCESS=$(sudo lsof -i :443 2>/dev/null || echo "")
if [ -n "$PORT443_PROCESS" ]; then
    echo "$PORT443_PROCESS"
    PORT443_IN_USE=true
else
    print_success "Port 443 is available"
    PORT443_IN_USE=false
fi

echo ""

# Check for common web servers
print_status "Checking for common web servers:"
NGINX_RUNNING=$(systemctl is-active nginx 2>/dev/null || echo "inactive")
APACHE_RUNNING=$(systemctl is-active apache2 2>/dev/null || echo "inactive")
HTTPD_RUNNING=$(systemctl is-active httpd 2>/dev/null || echo "inactive")

echo "Nginx: $NGINX_RUNNING"
echo "Apache2: $APACHE_RUNNING" 
echo "HTTPD: $HTTPD_RUNNING"

echo ""

# Check for Docker containers using these ports
print_status "Checking for Docker containers using ports 80/443:"
DOCKER_CONTAINERS=$(docker ps --format "table {{.Names}}\t{{.Ports}}" 2>/dev/null | grep -E ":80|:443" || echo "")
if [ -n "$DOCKER_CONTAINERS" ]; then
    echo "$DOCKER_CONTAINERS"
else
    print_success "No Docker containers using ports 80/443"
fi

echo ""
echo -e "${YELLOW}================================${NC}"
echo -e "${YELLOW}🛠️  SOLUTION OPTIONS${NC}"
echo -e "${YELLOW}================================${NC}"
echo ""

if [ "$PORT80_IN_USE" = true ] || [ "$PORT443_IN_USE" = true ]; then
    print_warning "Ports 80 and/or 443 are in use. Here are your options:"
    echo ""
    
    echo -e "${GREEN}Option 1: Stop existing web servers (Recommended)${NC}"
    echo "If you have Nginx, Apache, or other web servers running:"
    echo ""
    
    if [ "$NGINX_RUNNING" = "active" ]; then
        echo "Stop Nginx:"
        echo "  sudo systemctl stop nginx"
        echo "  sudo systemctl disable nginx  # Prevents auto-start on boot"
        echo ""
    fi
    
    if [ "$APACHE_RUNNING" = "active" ]; then
        echo "Stop Apache:"
        echo "  sudo systemctl stop apache2"
        echo "  sudo systemctl disable apache2  # Prevents auto-start on boot"
        echo ""
    fi
    
    if [ "$HTTPD_RUNNING" = "active" ]; then
        echo "Stop HTTPD:"
        echo "  sudo systemctl stop httpd"
        echo "  sudo systemctl disable httpd  # Prevents auto-start on boot"
        echo ""
    fi
    
    echo -e "${GREEN}Option 2: Use different ports for Traefik${NC}"
    echo "Modify Traefik to use different ports (e.g., 8080, 8443):"
    echo "  Edit docker-compose files to use different ports"
    echo "  Access via: http://yourdomain.com:8080"
    echo ""
    
    echo -e "${GREEN}Option 3: Integrate with existing reverse proxy${NC}"
    echo "If you have an existing Nginx/Apache setup:"
    echo "  Configure existing proxy to forward to Traefik on internal ports"
    echo "  Keep existing SSL certificates"
    echo ""
    
    echo -e "${GREEN}Option 4: Kill processes using the ports${NC}"
    echo "Force kill processes (use with caution):"
    if [ -n "$PORT80_PROCESS" ]; then
        PORT80_PID=$(echo "$PORT80_PROCESS" | awk 'NR==2{print $2}')
        echo "  sudo kill -9 $PORT80_PID  # Kill process on port 80"
    fi
    if [ -n "$PORT443_PROCESS" ]; then
        PORT443_PID=$(echo "$PORT443_PROCESS" | awk 'NR==2{print $2}')
        echo "  sudo kill -9 $PORT443_PID  # Kill process on port 443"
    fi
    echo ""
    
else
    print_success "Ports 80 and 443 are available! You can proceed with Traefik setup."
    echo ""
    echo "Run: ./domain-manager.sh setup-traefik"
    exit 0
fi

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}🚀 RECOMMENDED SOLUTION${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

print_status "For most users, Option 1 (stopping existing web servers) is recommended:"
echo ""
echo "1. Stop existing web servers:"
if [ "$NGINX_RUNNING" = "active" ]; then
    echo "   sudo systemctl stop nginx && sudo systemctl disable nginx"
fi
if [ "$APACHE_RUNNING" = "active" ]; then
    echo "   sudo systemctl stop apache2 && sudo systemctl disable apache2"
fi
if [ "$HTTPD_RUNNING" = "active" ]; then
    echo "   sudo systemctl stop httpd && sudo systemctl disable httpd"
fi

echo ""
echo "2. Then retry Traefik setup:"
echo "   ./domain-manager.sh setup-traefik"
echo ""

print_warning "Note: This will stop your existing web server. Make sure you don't have"
print_warning "important websites running on it, or migrate them to Traefik first."

echo ""
echo -e "${YELLOW}================================${NC}"
echo -e "${YELLOW}🔄 QUICK FIX SCRIPT${NC}"
echo -e "${YELLOW}================================${NC}"
echo ""

cat << 'EOF'
# Quick fix script - run these commands:

# Stop common web servers
sudo systemctl stop nginx 2>/dev/null || true
sudo systemctl stop apache2 2>/dev/null || true  
sudo systemctl stop httpd 2>/dev/null || true

# Disable them from auto-starting
sudo systemctl disable nginx 2>/dev/null || true
sudo systemctl disable apache2 2>/dev/null || true
sudo systemctl disable httpd 2>/dev/null || true

# Verify ports are free
sudo lsof -i :80
sudo lsof -i :443

# If still in use, kill the processes
# sudo kill -9 $(sudo lsof -t -i:80) 2>/dev/null || true
# sudo kill -9 $(sudo lsof -t -i:443) 2>/dev/null || true

# Retry Traefik setup
./domain-manager.sh setup-traefik
EOF

echo ""
print_success "Copy and run the commands above to resolve the port conflict!"