#!/bin/bash

# Quick Port 80/443 Fix Script
# Stops common web servers and frees up ports for Traefik

echo "🔧 Quick Port Fix - Stopping web servers..."

# Stop common web servers
echo "Stopping Nginx..."
sudo systemctl stop nginx 2>/dev/null && echo "✅ Nginx stopped" || echo "ℹ️  Nginx not running"

echo "Stopping Apache..."
sudo systemctl stop apache2 2>/dev/null && echo "✅ Apache stopped" || echo "ℹ️  Apache not running"

echo "Stopping HTTPD..."
sudo systemctl stop httpd 2>/dev/null && echo "✅ HTTPD stopped" || echo "ℹ️  HTTPD not running"

# Disable auto-start
echo ""
echo "Disabling auto-start on boot..."
sudo systemctl disable nginx 2>/dev/null && echo "✅ Nginx disabled" || echo "ℹ️  Nginx not installed"
sudo systemctl disable apache2 2>/dev/null && echo "✅ Apache disabled" || echo "ℹ️  Apache not installed"
sudo systemctl disable httpd 2>/dev/null && echo "✅ HTTPD disabled" || echo "ℹ️  HTTPD not installed"

# Check if ports are still in use
echo ""
echo "Checking port status..."

PORT80_CHECK=$(sudo lsof -i :80 2>/dev/null || echo "")
PORT443_CHECK=$(sudo lsof -i :443 2>/dev/null || echo "")

if [ -z "$PORT80_CHECK" ] && [ -z "$PORT443_CHECK" ]; then
    echo "✅ Ports 80 and 443 are now free!"
    echo ""
    echo "🚀 You can now run:"
    echo "   ./domain-manager.sh setup-traefik"
else
    echo "⚠️  Some processes are still using the ports:"
    
    if [ -n "$PORT80_CHECK" ]; then
        echo "Port 80:"
        echo "$PORT80_CHECK"
        echo ""
        echo "To force kill: sudo kill -9 $(sudo lsof -t -i:80)"
    fi
    
    if [ -n "$PORT443_CHECK" ]; then
        echo "Port 443:"
        echo "$PORT443_CHECK" 
        echo ""
        echo "To force kill: sudo kill -9 $(sudo lsof -t -i:443)"
    fi
    
    echo ""
    echo "💡 Run './fix-port-conflict.sh' for more detailed analysis"
fi