#!/bin/bash

# Quick Docker Installation Script
# Simple one-command Docker installation for Ubuntu/Debian systems

echo "🚀 Quick Docker Installation"
echo "============================"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please do not run this script as root"
    exit 1
fi

# Update and install prerequisites
echo "📦 Installing prerequisites..."
sudo apt-get update
sudo apt-get install -y curl

# Install Docker using the official convenience script
echo "🐳 Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
echo "🔧 Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add user to docker group
echo "👤 Adding user to docker group..."
sudo usermod -aG docker $USER

# Start Docker service
echo "🚀 Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Clean up
rm -f get-docker.sh

echo ""
echo "✅ Docker installation completed!"
echo ""
echo "⚠️  Important: Please log out and log back in to use Docker without sudo"
echo ""
echo "🧪 Test your installation:"
echo "  docker --version"
echo "  docker-compose --version"
echo ""
echo "🚗 Start Fleet Management:"
echo "  ./docker-start.sh docker-prod"
echo ""