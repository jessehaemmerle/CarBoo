# FleetManager Pro - Docker Deployment Guide

A complete fleet management system with multilingual support (English, German, Spanish) and free-tier access.

## 🚀 Quick Start

### Prerequisites

- Ubuntu VPS with 2GB+ RAM
- Docker and Docker Compose installed
- Ports 3000, 8001, and 27017 available

### One-Command Setup

```bash
# Clone and deploy
git clone <your-repo-url> fleetmanager
cd fleetmanager
./setup.sh prod
```

## 📋 Manual Setup

### 1. Install Docker & Docker Compose

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login again for group changes
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit configuration (required)
nano .env
```

### 3. Deploy Application

```bash
# Production deployment
./setup.sh prod

# Or development mode
./setup.sh dev
```

## 🔧 Configuration

### Environment Variables (.env)

```bash
# Database Configuration
MONGO_PASSWORD=your-secure-mongodb-password-here

# Security Configuration  
JWT_SECRET=your-super-secure-jwt-secret-key-minimum-32-characters-long

# Backend Configuration
BACKEND_URL=http://your-server-ip:8001
ENVIRONMENT=production

# Frontend Configuration
REACT_APP_BACKEND_URL=http://your-server-ip:8001
```

### Firewall Configuration

```bash
# Ubuntu UFW
sudo ufw allow 3000/tcp  # Frontend
sudo ufw allow 8001/tcp  # Backend API
sudo ufw allow 27017/tcp # MongoDB (optional, for external access)
```

## 🎛️ Management Commands

```bash
# Start services
./setup.sh prod

# Stop services
./setup.sh stop

# View logs
./setup.sh logs

# Check status
./setup.sh status

# Restart services
./setup.sh restart

# Backup database
./setup.sh backup

# Clean everything
./setup.sh clean
```

## 🌐 Access Points

After successful deployment:

- **Frontend Application**: http://your-server-ip:3000
- **Backend API**: http://your-server-ip:8001
- **API Documentation**: http://your-server-ip:8001/docs
- **Health Check**: http://your-server-ip:8001/api/health

## 🔐 First-Time Setup

1. Open http://your-server-ip:3000
2. Click "Get Started" to register
3. Fill in your company information
4. Create your fleet manager account
5. Start adding vehicles and users

## 🌍 Multilingual Support

The application supports:
- 🇺🇸 English (default)
- 🇩🇪 German 
- 🇪🇸 Spanish

Language preferences are saved per user and persist across sessions.

## 📦 Services Overview

### Frontend (Port 3000)
- React application with multilingual support
- Built with Tailwind CSS
- Production-optimized with Nginx

### Backend (Port 8001)
- FastAPI with automatic documentation
- JWT authentication
- Multilingual user preferences
- Health check endpoint

### Database (Port 27017)
- MongoDB 7.0
- Automatic authentication
- Data persistence with Docker volumes

## 🔄 Updates & Maintenance

### Update Application

```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
./setup.sh stop
./setup.sh prod
```

### Backup & Restore

```bash
# Create backup
./setup.sh backup

# Restore from backup (manual process)
# 1. Stop services: ./setup.sh stop
# 2. Extract backup: tar -xzf backups/fleetmanager_backup_YYYYMMDD_HHMMSS.tar.gz
# 3. Restore to MongoDB container
# 4. Start services: ./setup.sh prod
```

### Monitor Logs

```bash
# All services
./setup.sh logs

# Specific service
docker-compose logs -f frontend
docker-compose logs -f backend
docker-compose logs -f mongodb
```

## 🛠️ Troubleshooting

### Common Issues

1. **Port already in use**
   ```bash
   sudo lsof -i :3000  # Check what's using port 3000
   sudo lsof -i :8001  # Check what's using port 8001
   ```

2. **Permission denied**
   ```bash
   sudo chown -R $USER:$USER /path/to/fleetmanager
   ```

3. **Database connection issues**
   ```bash
   # Check MongoDB status
   docker-compose exec mongodb mongosh --eval "db.adminCommand('ping')"
   ```

4. **Frontend build issues**
   ```bash
   # Clear Docker cache and rebuild
   docker system prune -f
   ./setup.sh prod
   ```

### Service Health Checks

```bash
# Check all services
docker-compose ps

# Test backend API
curl http://localhost:8001/api/health

# Test frontend
curl http://localhost:3000
```

## 🔒 Security Considerations

1. **Change default passwords** in .env file
2. **Use strong JWT secret** (50+ characters)
3. **Configure firewall** to restrict access
4. **Regular backups** of database
5. **Monitor logs** for suspicious activity
6. **Update containers** regularly for security patches

## 📊 Performance Optimization

### Production Recommendations

1. **Resource Allocation**
   - Minimum 2GB RAM
   - 2 CPU cores
   - 20GB disk space

2. **Reverse Proxy** (Optional)
   ```bash
   # Use Nginx or Caddy for SSL termination
   # and load balancing if needed
   ```

3. **MongoDB Optimization**
   ```bash
   # Increase MongoDB cache size if needed
   # Add to docker-compose.yml:
   # command: mongod --wiredTigerCacheSizeGB 1
   ```

## 💾 Data Management

### Database Schema
- **Companies**: Multi-tenant isolation
- **Users**: Role-based access (Fleet Manager / Regular User)
- **Cars**: Vehicle information and status
- **Bookings**: Reservation system with approval workflow
- **Downtimes**: Maintenance and unavailability tracking

### Data Retention
- All data is persistent in Docker volumes
- Regular backups recommended
- No automatic data cleanup (by design)

## 🆘 Support

For issues and support:
1. Check logs: `./setup.sh logs`
2. Verify configuration: `.env` file
3. Test services: `./setup.sh status`
4. Review this documentation

## 📝 License

This project is licensed under the MIT License.

---

**FleetManager Pro** - Professional Fleet Management Platform
*Free • Open Source • Multilingual • Production Ready*