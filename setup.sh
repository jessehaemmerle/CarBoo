#!/bin/bash

# FleetManager Pro Setup Script
echo "🚗 FleetManager Pro Setup"
echo "=========================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    
    # Get server IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
    
    # Generate secure passwords
    MONGO_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)
    
    # Update .env file
    sed -i "s/your-secure-mongodb-password-here/$MONGO_PASSWORD/g" .env
    sed -i "s/your-super-secure-jwt-secret-key-minimum-32-characters-long/$JWT_SECRET/g" .env
    sed -i "s/your-server-ip/$SERVER_IP/g" .env
    
    echo "✅ .env file created with secure passwords"
    echo "⚠️  Please review and update .env file with your specific configuration!"
else
    echo "✅ .env file already exists"
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p logs
mkdir -p backups

# Function to display help
show_help() {
    echo ""
    echo "🚀 Available commands:"
    echo "  ./setup.sh dev      - Start development environment"
    echo "  ./setup.sh prod     - Start production environment"
    echo "  ./setup.sh stop     - Stop all services"
    echo "  ./setup.sh restart  - Restart all services"
    echo "  ./setup.sh logs     - View logs"
    echo "  ./setup.sh clean    - Clean up all containers and volumes"
    echo "  ./setup.sh backup   - Backup database"
    echo "  ./setup.sh status   - Show services status"
    echo "  ./setup.sh help     - Show this help message"
}

# Handle command line arguments
case "${1:-help}" in
    "dev")
        echo "🚀 Starting development environment..."
        docker compose -f docker-compose.dev.yml up --build
        ;;
    "prod")
        echo "🚀 Starting production environment..."
        if [ ! -f .env ]; then
            echo "📝 Creating .env file from template..."
            if [ -f .env.example ]; then
                cp .env.example .env
                
                # Generate secure passwords
                MONGO_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
                JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)
                
                # Update .env file
                sed -i "s/your-secure-mongodb-password-here/$MONGO_PASSWORD/g" .env
                sed -i "s/your-super-secure-jwt-secret-key-minimum-32-characters-long/$JWT_SECRET/g" .env
                sed -i "s/your-server-ip/localhost/g" .env
                
                echo "✅ .env file created with secure passwords"
            else
                echo "❌ .env.example template not found!"
                exit 1
            fi
        fi
        
        # Validate Docker Compose configuration
        if ! docker compose config &> /dev/null; then
            echo "❌ Docker Compose configuration is invalid!"
            echo "Run './docker-troubleshoot.sh check' for detailed diagnostics"
            exit 1
        fi
        
        docker compose up --build -d
        
        # Wait for services to start and check health
        echo "⏳ Waiting for services to start..."
        sleep 30
        
        # Check container health
        echo "🔍 Checking container health..."
        unhealthy_containers=$(docker compose ps --filter "health=unhealthy" -q)
        if [ ! -z "$unhealthy_containers" ]; then
            echo "⚠️  Some containers are unhealthy. Run './docker-troubleshoot.sh fix-backend' for diagnosis"
        fi
        
        echo "✅ Production environment started!"
        echo "🌐 Frontend: http://localhost:3000"
        echo "🚀 Backend API: http://localhost:8001"
        echo "📊 API Documentation: http://localhost:8001/docs"
        echo "🔧 For troubleshooting: ./docker-troubleshoot.sh"
        ;;
    "stop")
        echo "🛑 Stopping all services..."
        docker compose down
        docker compose -f docker-compose.dev.yml down
        ;;
    "restart")
        echo "🔄 Restarting services..."
        docker compose restart
        ;;
    "logs")
        echo "📋 Viewing logs (press Ctrl+C to exit)..."
        docker compose logs -f
        ;;
    "status")
        echo "📊 Services status:"
        docker compose ps
        ;;
    "clean")
        echo "🧹 Cleaning up containers and volumes..."
        read -p "⚠️  This will delete all data. Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose down -v
            docker compose -f docker-compose.dev.yml down -v
            docker system prune -f
            echo "✅ Cleanup completed!"
        else
            echo "❌ Cleanup cancelled"
        fi
        ;;
    "backup")
        echo "💾 Creating database backup..."
        timestamp=$(date +%Y%m%d_%H%M%S)
        backup_file="fleetmanager_backup_${timestamp}.tar.gz"
        
        # Create backup directory
        mkdir -p backups
        
        # Backup MongoDB
        docker compose exec -T mongodb mongodump --uri="mongodb://root:$(grep MONGO_PASSWORD .env | cut -d'=' -f2)@localhost:27017/fleetmanager?authSource=admin" --out /data/backup
        docker cp $(docker compose ps -q mongodb):/data/backup ./backups/backup_${timestamp}
        
        # Create compressed archive
        cd backups
        tar -czf ${backup_file} backup_${timestamp}
        rm -rf backup_${timestamp}
        cd ..
        
        echo "✅ Backup created: backups/${backup_file}"
        ;;
    "help"|*)
        show_help
        ;;
esac

if [ "$1" = "dev" ] || [ "$1" = "prod" ]; then
    echo ""
    echo "🎉 Setup complete!"
    echo ""
    echo "📖 Quick Start Guide:"
    echo "1. Open http://localhost:3000 for the web interface"
    echo "2. Visit http://localhost:8001/docs for API documentation"
    echo "3. Register your first company and fleet manager account"
    echo "4. Start adding vehicles to your fleet"
    echo "5. Create additional users as needed"
    echo ""
    echo "📚 For more information, check the README.md file"
    echo ""
fi
