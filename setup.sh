#!/bin/bash

# Fleet Management System Setup Script
echo "🚗 Fleet Management System Setup"
echo "================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.template .env
    echo "⚠️  Please edit .env file and update the configuration values!"
    echo "   Especially change the passwords and secret keys for security."
else
    echo "✅ .env file already exists"
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p nginx/ssl
mkdir -p nginx/logs
mkdir -p mongo-init

echo "🔧 Setting up MongoDB initialization script..."
cat > mongo-init/init.js << 'EOF'
// MongoDB initialization script
db = db.getSiblingDB('fleet_db');

// Create collections with indexes
db.createCollection('users');
db.createCollection('cars');
db.createCollection('downtimes');
db.createCollection('bookings');

// Create indexes for better performance
db.users.createIndex({ "email": 1 }, { unique: true });
db.cars.createIndex({ "license_plate": 1 }, { unique: true });
db.cars.createIndex({ "status": 1 });
db.downtimes.createIndex({ "car_id": 1 });
db.downtimes.createIndex({ "start_date": 1 });
db.bookings.createIndex({ "car_id": 1 });
db.bookings.createIndex({ "user_id": 1 });
db.bookings.createIndex({ "status": 1 });
db.bookings.createIndex({ "start_date": 1 });

print("Fleet Management Database initialized successfully!");
EOF

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
    echo "  ./setup.sh help     - Show this help message"
}

# Handle command line arguments
case "${1:-help}" in
    "dev")
        echo "🚀 Starting development environment..."
        docker-compose up --build
        ;;
    "prod")
        echo "🚀 Starting production environment..."
        if [ ! -f .env ]; then
            echo "❌ .env file not found. Please create it first!"
            exit 1
        fi
        docker-compose -f docker-compose.prod.yml up --build -d
        echo "✅ Production environment started!"
        echo "🌐 Access the application at: http://localhost"
        ;;
    "stop")
        echo "🛑 Stopping all services..."
        docker-compose down
        docker-compose -f docker-compose.prod.yml down
        ;;
    "restart")
        echo "🔄 Restarting services..."
        docker-compose restart
        ;;
    "logs")
        echo "📋 Viewing logs (press Ctrl+C to exit)..."
        docker-compose logs -f
        ;;
    "clean")
        echo "🧹 Cleaning up containers and volumes..."
        read -p "⚠️  This will delete all data. Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker-compose down -v
            docker-compose -f docker-compose.prod.yml down -v
            docker system prune -f
            echo "✅ Cleanup completed!"
        else
            echo "❌ Cleanup cancelled"
        fi
        ;;
    "backup")
        echo "💾 Creating database backup..."
        timestamp=$(date +%Y%m%d_%H%M%S)
        backup_file="fleet_backup_${timestamp}.tar.gz"
        docker-compose exec mongodb mongodump --db fleet_db --out /data/backup
        docker cp $(docker-compose ps -q mongodb):/data/backup ./backup_${timestamp}
        tar -czf ${backup_file} backup_${timestamp}
        rm -rf backup_${timestamp}
        echo "✅ Backup created: ${backup_file}"
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
    echo "1. Open http://localhost:3000 (or http://localhost for production)"
    echo "2. Register the first user as a Fleet Manager"
    echo "3. Start adding vehicles to your fleet"
    echo "4. Create additional users as needed"
    echo ""
    echo "📚 For more information, check the README.md file"
    echo ""
fi