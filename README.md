# 🚗 FleetManager Pro - Multi-Tenant SaaS Platform

A comprehensive multi-tenant fleet management platform that allows unlimited companies to manage their vehicle fleets with subscription-based pricing, user management, booking systems, and real-time analytics.

## 📋 Table of Contents

- [Features](#features)
- [System Requirements](#system-requirements)
- [Quick Start](#quick-start)
- [Installation Methods](#installation-methods)
- [Configuration](#configuration)
- [Production Deployment](#production-deployment)
- [SSL/HTTPS Setup](#sslhttps-setup)
- [Monitoring & Maintenance](#monitoring--maintenance)
- [API Documentation](#api-documentation)
- [Troubleshooting](#troubleshooting)
- [Backup & Recovery](#backup--recovery)
- [Scaling](#scaling)
- [Support](#support)

## ✨ Features

### 🏢 Multi-Tenant SaaS Architecture
- **Unlimited Companies**: Each company has isolated data and branding
- **Subscription Plans**: Trial, Basic, Professional, Enterprise tiers
- **Usage Monitoring**: Real-time tracking of vehicle and user limits
- **Professional Landing Page**: Marketing website with conversion optimization

### 🚙 Fleet Management
- **Vehicle CRUD**: Complete vehicle lifecycle management
- **Multiple Categories**: Sedan, SUV, Truck, Van, Hatchback, Coupe
- **Real-time Status**: Available, In Use, Downtime, Maintenance tracking
- **Maintenance Scheduling**: Downtime management with cost tracking

### 📅 Booking & Approval System
- **User Booking Requests**: Employees can request vehicle reservations
- **Manager Approval Workflow**: Fleet managers approve/reject requests
- **Availability Checking**: Prevents double-booking conflicts
- **Booking History**: Complete audit trail of all reservations

### 👥 User Management
- **Role-Based Access**: Fleet Managers and Regular Users
- **Company-Scoped Users**: Users belong to specific companies
- **Department Integration**: Users can be organized by departments
- **JWT Authentication**: Secure token-based authentication

### 📊 Analytics & Reporting
- **Real-time Dashboard**: Live fleet statistics and metrics
- **Usage Analytics**: Vehicle utilization and booking patterns
- **Cost Tracking**: Maintenance and operational cost monitoring
- **Company Reports**: Subscription usage and limit tracking

## 🛠 System Requirements

### Minimum Requirements
- **CPU**: 2 cores, 2.4 GHz
- **RAM**: 4 GB
- **Storage**: 20 GB SSD
- **OS**: Ubuntu 20.04+, CentOS 8+, or Docker-compatible OS
- **Network**: Static IP address (recommended)

### Recommended Requirements
- **CPU**: 4+ cores, 2.8 GHz
- **RAM**: 8+ GB
- **Storage**: 50+ GB SSD with backup storage
- **OS**: Ubuntu 22.04 LTS
- **Network**: Static IP with domain name

### Software Dependencies
- **Docker**: 20.10+ and Docker Compose 2.0+
- **Git**: For source code management
- **SSL Certificate**: For HTTPS (Let's Encrypt recommended)

## 🚀 Quick Start

### Option 1: One-Command Docker Setup (Recommended)

```bash
# Clone the repository
git clone https://github.com/your-repo/fleetmanager-pro.git
cd fleetmanager-pro

# Run the setup script
chmod +x setup.sh
./setup.sh dev

# Access the application
# Frontend: http://localhost:3000
# API: http://localhost:8001/docs
```

### Option 2: Production Setup

```bash
# Clone and configure
git clone https://github.com/your-repo/fleetmanager-pro.git
cd fleetmanager-pro

# Setup environment
cp .env.template .env
nano .env  # Edit configuration

# Start production environment
./setup.sh prod

# Access via your domain
# https://your-domain.com
```

## 📦 Installation Methods

### Method 1: Docker Deployment (Recommended)

#### Prerequisites
```bash
# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login to apply group changes
```

#### Installation Steps
```bash
# 1. Clone Repository
git clone https://github.com/your-repo/fleetmanager-pro.git
cd fleetmanager-pro

# 2. Configure Environment
cp .env.template .env

# 3. Edit configuration (see Configuration section below)
nano .env

# 4. Start Services
docker-compose up -d --build

# 5. Check Status
docker-compose ps
./health-check.sh
```

### Method 2: Manual Installation

#### Backend Setup
```bash
# 1. Install Python 3.11+
sudo apt update
sudo apt install python3.11 python3.11-pip python3.11-venv

# 2. Create Virtual Environment
cd backend
python3.11 -m venv venv
source venv/bin/activate

# 3. Install Dependencies
pip install -r requirements.txt

# 4. Configure Environment
cp .env.template .env
nano .env

# 5. Start Backend
uvicorn server:app --host 0.0.0.0 --port 8001
```

#### Frontend Setup
```bash
# 1. Install Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 2. Install Dependencies
cd frontend
npm install

# 3. Configure Environment
cp .env.template .env
nano .env

# 4. Build and Start
npm run build
npm start
```

#### Database Setup
```bash
# 1. Install MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org

# 2. Start MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod

# 3. Create Database and User
mongosh
use fleet_db
db.createUser({
  user: "fleetuser",
  pwd: "secure_password",
  roles: ["readWrite"]
})
```

## ⚙️ Configuration

### Environment Variables

Create and configure your `.env` file:

```bash
cp .env.template .env
```

#### Required Configuration

```env
# Database Configuration
MONGO_URL=mongodb://localhost:27017
DB_NAME=fleet_db

# JWT Security (CHANGE THIS!)
JWT_SECRET_KEY=your-super-secret-jwt-key-minimum-32-characters-long-change-in-production

# Application URLs
BACKEND_URL=http://localhost:8001
FRONTEND_URL=http://localhost:3000

# Email Configuration (Optional)
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=your-email@gmail.com
```

#### Production Configuration

```env
# Production URLs
BACKEND_URL=https://api.your-domain.com
FRONTEND_URL=https://your-domain.com

# Database with Authentication
MONGO_URL=mongodb://fleetuser:secure_password@localhost:27017/fleet_db

# Enhanced Security
JWT_SECRET_KEY=your-super-secure-production-jwt-key-minimum-64-characters-long
SESSION_SECRET=another-secure-session-secret-key

# SSL Configuration
SSL_CERT_PATH=/etc/ssl/certs/your-domain.crt
SSL_KEY_PATH=/etc/ssl/private/your-domain.key

# Monitoring (Optional)
SENTRY_DSN=your-sentry-dsn-for-error-tracking
LOG_LEVEL=INFO

# Rate Limiting
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=900

# File Upload Limits
MAX_FILE_SIZE=10485760  # 10MB
```

### Database Configuration

#### MongoDB Setup with Authentication
```bash
# 1. Connect to MongoDB
mongosh

# 2. Create Admin User
use admin
db.createUser({
  user: "admin",
  pwd: "secure_admin_password",
  roles: ["userAdminAnyDatabase", "dbAdminAnyDatabase"]
})

# 3. Create Application Database and User
use fleet_db
db.createUser({
  user: "fleetuser",
  pwd: "secure_app_password", 
  roles: ["readWrite"]
})

# 4. Create Indexes for Performance
db.companies.createIndex({ "email": 1 }, { unique: true })
db.companies.createIndex({ "slug": 1 }, { unique: true })
db.users.createIndex({ "email": 1 }, { unique: true })
db.users.createIndex({ "company_id": 1 })
db.cars.createIndex({ "company_id": 1 })
db.cars.createIndex({ "license_plate": 1, "company_id": 1 }, { unique: true })
db.downtimes.createIndex({ "company_id": 1 })
db.downtimes.createIndex({ "car_id": 1 })
db.bookings.createIndex({ "company_id": 1 })
db.bookings.createIndex({ "user_id": 1 })
db.bookings.createIndex({ "start_date": 1 })

# 5. Enable Authentication
sudo nano /etc/mongod.conf
# Add:
# security:
#   authorization: enabled

sudo systemctl restart mongod
```

## 🚀 Production Deployment

### Server Preparation

```bash
# 1. Update System
sudo apt update && sudo apt upgrade -y

# 2. Install Essential Tools
sudo apt install -y curl wget git htop nginx certbot python3-certbot-nginx

# 3. Configure Firewall
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable

# 4. Create Application User
sudo useradd -m -s /bin/bash fleetmanager
sudo usermod -aG docker fleetmanager
```

### Deployment Steps

```bash
# 1. Switch to Application User
sudo su - fleetmanager

# 2. Clone and Setup
git clone https://github.com/your-repo/fleetmanager-pro.git
cd fleetmanager-pro

# 3. Configure Production Environment
cp .env.template .env
nano .env  # Configure with production values

# 4. Start Production Services
docker-compose -f docker-compose.prod.yml up -d --build

# 5. Verify Deployment
./health-check.sh
```

### Nginx Reverse Proxy Setup

```bash
# 1. Create Nginx Configuration
sudo nano /etc/nginx/sites-available/fleetmanager

# Add configuration:
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # API Proxy
    location /api/ {
        proxy_pass http://localhost:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Rate Limiting
        limit_req zone=api burst=20 nodelay;
    }
    
    # Frontend Proxy
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Health Check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}

# 2. Enable Site
sudo ln -s /etc/nginx/sites-available/fleetmanager /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 🔒 SSL/HTTPS Setup

### Let's Encrypt (Free SSL)

```bash
# 1. Obtain SSL Certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# 2. Test Auto-renewal
sudo certbot renew --dry-run

# 3. Setup Auto-renewal Cron Job
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### Custom SSL Certificate

```bash
# 1. Upload your certificates
sudo mkdir -p /etc/ssl/certs /etc/ssl/private
sudo cp your-domain.crt /etc/ssl/certs/
sudo cp your-domain.key /etc/ssl/private/
sudo chmod 600 /etc/ssl/private/your-domain.key

# 2. Update Nginx configuration with your certificate paths
```

## 📊 Monitoring & Maintenance

### Health Monitoring

```bash
# 1. Setup Health Check Script
cat > /home/fleetmanager/health-check.sh << 'EOF'
#!/bin/bash
cd /home/fleetmanager/fleetmanager-pro
./health-check.sh
EOF

chmod +x /home/fleetmanager/health-check.sh

# 2. Setup Cron Job for Health Checks
crontab -e
# Add: */5 * * * * /home/fleetmanager/health-check.sh >> /var/log/fleetmanager-health.log 2>&1
```

### Log Management

```bash
# 1. Setup Log Rotation
sudo nano /etc/logrotate.d/fleetmanager

# Add:
/home/fleetmanager/fleetmanager-pro/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    copytruncate
}

# 2. View Logs
docker-compose logs -f                    # All services
docker-compose logs -f backend           # Backend only
docker-compose logs -f frontend          # Frontend only
sudo tail -f /var/log/nginx/access.log   # Nginx access
sudo tail -f /var/log/nginx/error.log    # Nginx errors
```

### Performance Monitoring

```bash
# 1. Monitor Resource Usage
htop                                      # System resources
docker stats                            # Container resources
./health-check.sh                       # Application health

# 2. Database Monitoring
mongosh
use fleet_db
db.stats()                              # Database statistics
db.cars.getIndexes()                    # Index usage
```

## 📖 API Documentation

### Access API Documentation
- **Development**: http://localhost:8001/docs
- **Production**: https://your-domain.com/api/docs

### Key API Endpoints

#### Authentication
```
POST /api/companies/register    # Register new company
POST /api/auth/login           # User login
GET  /api/auth/me             # Get current user
```

#### Company Management
```
GET  /api/companies/me        # Get company info
PUT  /api/companies/me        # Update company
```

#### Fleet Management
```
GET    /api/cars              # List vehicles
POST   /api/cars              # Add vehicle
PUT    /api/cars/{id}         # Update vehicle
DELETE /api/cars/{id}         # Delete vehicle
```

#### Booking System
```
GET  /api/bookings            # List bookings
POST /api/bookings            # Create booking
PUT  /api/bookings/{id}/approve # Approve/reject booking
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Service Won't Start
```bash
# Check logs
docker-compose logs backend
docker-compose logs frontend

# Check ports
sudo netstat -tlnp | grep :3000
sudo netstat -tlnp | grep :8001

# Restart services
docker-compose restart
```

#### 2. Database Connection Issues
```bash
# Check MongoDB status
sudo systemctl status mongod

# Test connection
mongosh mongodb://localhost:27017/fleet_db

# Check logs
sudo tail -f /var/log/mongodb/mongod.log
```

#### 3. SSL Certificate Issues
```bash
# Check certificate
sudo certbot certificates

# Renew certificate
sudo certbot renew

# Check Nginx configuration
sudo nginx -t
```

#### 4. Memory Issues
```bash
# Check memory usage
free -h
docker stats

# Cleanup Docker
docker system prune -a

# Restart services
docker-compose restart
```

### Log Locations

```bash
# Application Logs
/home/fleetmanager/fleetmanager-pro/logs/

# Docker Logs
docker-compose logs

# System Logs
/var/log/nginx/
/var/log/mongodb/
/var/log/syslog
```

### Performance Optimization

```bash
# 1. Database Optimization
mongosh
use fleet_db
db.runCommand({reIndex: "cars"})
db.runCommand({compact: "users"})

# 2. Docker Optimization
docker-compose down
docker system prune -a
docker-compose up -d --build

# 3. Nginx Optimization
sudo nano /etc/nginx/nginx.conf
# Add:
# worker_processes auto;
# worker_connections 1024;
# gzip on;
```

## 💾 Backup & Recovery

### Automated Backup Setup

```bash
# 1. Create Backup Directory
sudo mkdir -p /backup/fleetmanager
sudo chown fleetmanager:fleetmanager /backup/fleetmanager

# 2. Create Backup Script
cat > /home/fleetmanager/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/fleetmanager"
DATE=$(date +%Y%m%d_%H%M%S)

# Database Backup
mongodump --db fleet_db --out $BACKUP_DIR/db_$DATE

# Application Backup
tar -czf $BACKUP_DIR/app_$DATE.tar.gz -C /home/fleetmanager fleetmanager-pro

# Cleanup old backups (keep 7 days)
find $BACKUP_DIR -name "db_*" -mtime +7 -exec rm -rf {} \;
find $BACKUP_DIR -name "app_*" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /home/fleetmanager/backup.sh

# 3. Schedule Daily Backups
crontab -e
# Add: 0 2 * * * /home/fleetmanager/backup.sh >> /var/log/backup.log 2>&1
```

### Manual Backup

```bash
# Database Backup
mongodump --db fleet_db --out /backup/manual_backup_$(date +%Y%m%d)

# Application Backup
tar -czf /backup/app_backup_$(date +%Y%m%d).tar.gz -C /home/fleetmanager fleetmanager-pro
```

### Restore Procedure

```bash
# 1. Stop Services
cd /home/fleetmanager/fleetmanager-pro
docker-compose down

# 2. Restore Database
mongorestore --db fleet_db --drop /backup/fleetmanager/db_YYYYMMDD_HHMMSS/fleet_db

# 3. Restore Application (if needed)
cd /home/fleetmanager
tar -xzf /backup/fleetmanager/app_YYYYMMDD_HHMMSS.tar.gz

# 4. Start Services
cd fleetmanager-pro
docker-compose up -d
```

## 📈 Scaling

### Horizontal Scaling

#### Load Balancer Setup (Nginx)
```bash
# 1. Multiple Backend Instances
docker-compose scale backend=3

# 2. Update Nginx Configuration
upstream backend {
    server localhost:8001;
    server localhost:8002;
    server localhost:8003;
}

server {
    location /api/ {
        proxy_pass http://backend;
        # ... other settings
    }
}
```

#### Database Scaling (MongoDB Replica Set)
```bash
# 1. Setup Replica Set
mongosh
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo1:27017" },
    { _id: 1, host: "mongo2:27017" },
    { _id: 2, host: "mongo3:27017" }
  ]
})

# 2. Update Connection String
MONGO_URL=mongodb://mongo1:27017,mongo2:27017,mongo3:27017/fleet_db?replicaSet=rs0
```

### Vertical Scaling

```bash
# 1. Increase Docker Resources
# Edit docker-compose.yml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G

# 2. Increase MongoDB Cache Size
# Edit /etc/mongod.conf
storage:
  wiredTiger:
    engineConfig:
      cacheSizeGB: 4
```

## 🆘 Support

### Documentation
- **API Docs**: https://your-domain.com/api/docs
- **User Manual**: Available in the application
- **Video Tutorials**: Contact support for access

### Getting Help

1. **Check Logs**: Review application and system logs
2. **Search Issues**: Check GitHub issues for similar problems
3. **Health Check**: Run `./health-check.sh` for system status
4. **Community Forum**: Join our community discussions

### Contact Information
- **Email**: support@fleetmanager-pro.com
- **Documentation**: https://docs.fleetmanager-pro.com
- **GitHub Issues**: https://github.com/your-repo/fleetmanager-pro/issues

### Professional Support
- **Enterprise Support**: 24/7 support for Enterprise customers
- **Professional Services**: Installation, training, and customization
- **SLA Options**: Custom service level agreements available

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

**🚗 Happy Fleet Managing!**

For additional support and enterprise features, visit [FleetManager Pro](https://fleetmanager-pro.com)
