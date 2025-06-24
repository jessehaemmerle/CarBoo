#!/bin/bash

# Docker Complete Installation Script
# Automatically installs Docker and Docker Compose on Linux systems
# Supports: Ubuntu/Debian, CentOS/RHEL/Fedora, Amazon Linux

set -e

echo "🐳 Docker Complete Installation Script"
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
    echo -e "${GREEN}✅ SUCCESS:${NC} $1"
}

print_error() {
    echo -e "${RED}❌ ERROR:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
}

print_info() {
    echo -e "${PURPLE}ℹ️  INFO:${NC} $1"
}

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VERSION=$(lsb_release -sr)
    elif [ -f /etc/redhat-release ]; then
        OS="Red Hat Enterprise Linux"
        VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+')
    else
        OS=$(uname -s)
        VERSION=$(uname -r)
    fi
    
    print_info "Detected OS: $OS $VERSION"
}

# Function to check if Docker is already installed
check_existing_docker() {
    if command -v docker >/dev/null 2>&1; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
        print_warning "Docker is already installed (version: $DOCKER_VERSION)"
        
        if command -v docker-compose >/dev/null 2>&1; then
            COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | tr -d ',')
            print_warning "Docker Compose is already installed (version: $COMPOSE_VERSION)"
        fi
        
        echo -e "\nOptions:"
        echo "1. Update existing installation"
        echo "2. Skip installation and configure only"
        echo "3. Remove and reinstall completely"
        echo "4. Exit"
        
        read -p "Choose option (1-4): " choice
        
        case $choice in
            1) UPDATE_MODE=true ;;
            2) CONFIGURE_ONLY=true ;;
            3) REMOVE_FIRST=true ;;
            4) exit 0 ;;
            *) print_error "Invalid choice. Exiting."; exit 1 ;;
        esac
    fi
}

# Function to remove existing Docker installation
remove_docker() {
    print_step "Removing existing Docker installation..."
    
    # Stop Docker service
    sudo systemctl stop docker 2>/dev/null || true
    sudo systemctl disable docker 2>/dev/null || true
    
    # Remove Docker packages based on OS
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        sudo apt-get remove -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli 2>/dev/null || true
        sudo apt-get autoremove -y 2>/dev/null || true
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"Fedora"* ]]; then
        sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine docker-ce docker-ce-cli 2>/dev/null || true
    elif [[ "$OS" == *"Amazon Linux"* ]]; then
        sudo yum remove -y docker 2>/dev/null || true
    fi
    
    # Remove Docker data (optional - ask user)
    read -p "Remove Docker data and images? (y/N): " remove_data
    if [[ $remove_data =~ ^[Yy]$ ]]; then
        sudo rm -rf /var/lib/docker 2>/dev/null || true
        sudo rm -rf /etc/docker 2>/dev/null || true
        print_info "Docker data removed"
    fi
    
    print_success "Existing Docker installation removed"
}

# Function to install Docker on Ubuntu/Debian
install_docker_ubuntu_debian() {
    print_step "Installing Docker on Ubuntu/Debian..."
    
    # Update package index
    sudo apt-get update
    
    # Install prerequisites
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Set up the stable repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index again
    sudo apt-get update
    
    # Install Docker Engine
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    print_success "Docker installed successfully on Ubuntu/Debian"
}

# Function to install Docker on CentOS/RHEL/Fedora
install_docker_centos_rhel() {
    print_step "Installing Docker on CentOS/RHEL/Fedora..."
    
    # Install prerequisites
    sudo yum install -y yum-utils
    
    # Add Docker repository
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    # Install Docker Engine
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    print_success "Docker installed successfully on CentOS/RHEL/Fedora"
}

# Function to install Docker on Amazon Linux
install_docker_amazon_linux() {
    print_step "Installing Docker on Amazon Linux..."
    
    # Update packages
    sudo yum update -y
    
    # Install Docker
    sudo yum install -y docker
    
    # Install Docker Compose separately for Amazon Linux
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    print_success "Docker installed successfully on Amazon Linux"
}

# Function to install Docker Compose (standalone)
install_docker_compose_standalone() {
    print_step "Installing Docker Compose (standalone)..."
    
    # Get latest version
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
    
    # Download and install
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Create symlink for easier access
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose 2>/dev/null || true
    
    print_success "Docker Compose installed successfully"
}

# Function to configure Docker
configure_docker() {
    print_step "Configuring Docker..."
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    # Create Docker daemon configuration for better performance
    sudo mkdir -p /etc/docker
    
    cat << EOF | sudo tee /etc/docker/daemon.json > /dev/null
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2"
}
EOF
    
    # Restart Docker with new configuration
    sudo systemctl restart docker
    
    print_success "Docker configured successfully"
}

# Function to verify installation
verify_installation() {
    print_step "Verifying Docker installation..."
    
    # Check Docker version
    if command -v docker >/dev/null 2>&1; then
        DOCKER_VERSION=$(docker --version)
        print_success "Docker: $DOCKER_VERSION"
    else
        print_error "Docker installation failed"
        return 1
    fi
    
    # Check Docker Compose version
    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_VERSION=$(docker-compose --version)
        print_success "Docker Compose: $COMPOSE_VERSION"
    else
        print_error "Docker Compose installation failed"
        return 1
    fi
    
    # Test Docker functionality
    print_step "Testing Docker functionality..."
    
    if sudo docker run --rm hello-world >/dev/null 2>&1; then
        print_success "Docker test successful"
    else
        print_error "Docker test failed"
        return 1
    fi
    
    # Check if user is in docker group
    if groups $USER | grep -q docker; then
        print_success "User $USER added to docker group"
    else
        print_warning "User $USER not in docker group (may require re-login)"
    fi
    
    print_success "Docker installation verified successfully"
}

# Function to display post-installation information
show_post_install_info() {
    echo ""
    echo "🎉 Docker Installation Complete!"
    echo "================================"
    echo ""
    echo -e "${GREEN}Next Steps:${NC}"
    echo "1. Log out and log back in (or run 'newgrp docker') to use Docker without sudo"
    echo "2. Test your installation:"
    echo "   docker run hello-world"
    echo "   docker-compose --version"
    echo ""
    echo -e "${BLUE}Fleet Management Docker Commands:${NC}"
    echo "   ./docker-start.sh docker-prod    # Start production (Port 80)"
    echo "   ./docker-start.sh docker-dev     # Start development (Port 3000)"
    echo "   ./validate-docker-config.sh      # Validate configuration"
    echo ""
    echo -e "${PURPLE}Useful Docker Commands:${NC}"
    echo "   docker ps                        # List running containers"
    echo "   docker images                    # List images"
    echo "   docker system prune              # Clean up unused resources"
    echo ""
    echo -e "${YELLOW}Documentation:${NC}"
    echo "   Docker: https://docs.docker.com/"
    echo "   Fleet Management: ./DOCKER_DEPLOYMENT_GUIDE.md"
}

# Main installation flow
main() {
    print_step "Starting Docker installation process..."
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root"
        exit 1
    fi
    
    # Detect operating system
    detect_os
    
    # Check existing installation
    check_existing_docker
    
    # Skip installation if requested
    if [ "$CONFIGURE_ONLY" = true ]; then
        configure_docker
        verify_installation
        show_post_install_info
        exit 0
    fi
    
    # Remove existing installation if requested
    if [ "$REMOVE_FIRST" = true ]; then
        remove_docker
    fi
    
    # Install Docker based on OS
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        install_docker_ubuntu_debian
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"Fedora"* ]]; then
        install_docker_centos_rhel
    elif [[ "$OS" == *"Amazon Linux"* ]]; then
        install_docker_amazon_linux
    else
        print_error "Unsupported operating system: $OS"
        print_info "Please install Docker manually: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Install Docker Compose if not already installed with Docker
    if ! command -v docker-compose >/dev/null 2>&1; then
        install_docker_compose_standalone
    fi
    
    # Configure Docker
    configure_docker
    
    # Verify installation
    if verify_installation; then
        show_post_install_info
    else
        print_error "Installation verification failed"
        exit 1
    fi
    
    print_success "Docker installation completed successfully!"
}

# Handle script arguments
case "${1:-install}" in
    "install"|"")
        main
        ;;
    "remove")
        detect_os
        remove_docker
        print_success "Docker removal completed"
        ;;
    "verify")
        verify_installation
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  install (default)  - Install Docker and Docker Compose"
        echo "  remove            - Remove Docker installation"
        echo "  verify            - Verify existing installation"
        echo "  help              - Show this help message"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac