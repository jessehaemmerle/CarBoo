# 🌐 Complete Multi-Domain Deployment Package

## 🎯 What This Provides

**Run FleetManager Pro alongside other applications on your VPS with different domains:**

```
your-vps-ip:443 → Traefik Reverse Proxy
├── fleet.yourdomain.com    → FleetManager Pro
├── blog.yourdomain.com     → WordPress (your other app)
├── api.yourdomain.com      → API Service (your other app)  
└── shop.yourdomain.com     → E-commerce (your other app)
```

## 🚀 Ultra-Quick Setup (2 commands)

```bash
# 1. Setup reverse proxy
./domain-manager.sh setup-traefik

# 2. Deploy FleetManager Pro  
./domain-manager.sh deploy-fleet
```

**Result**: FleetManager Pro runs on your domain with automatic SSL!

## 📦 What's Included

### 🏗️ Infrastructure Files
- **`traefik-only.yml`** - Standalone reverse proxy setup
- **`docker-compose.traefik.yml`** - FleetManager with Traefik integration
- **`docker-compose.multi-app.yml`** - Example multi-application setup

### 🛠️ Management Scripts
- **`domain-manager.sh`** - Complete management system (recommended)
- **`multi-domain-setup.sh`** - FleetManager-specific deployment
- **`setup.sh`** - Original single-domain setup

### 📋 Configuration Templates
- **`.env.traefik.example`** - Traefik configuration template
- **`.env.domain`** - FleetManager domain configuration (auto-generated)
- **`.env.example`** - Original environment template

### 📚 Documentation
- **`MULTI-DOMAIN.md`** - Complete multi-domain guide
- **`DEPLOYMENT.md`** - Original deployment documentation
- **`QUICK-DEPLOY.md`** - Single-domain quick start

## 🎛️ Management Commands

### One-Stop Management (Recommended)
```bash
# Complete system management
./domain-manager.sh help

# Setup everything
./domain-manager.sh setup-traefik
./domain-manager.sh deploy-fleet

# Monitor
./domain-manager.sh status
./domain-manager.sh health
./domain-manager.sh logs
```

### FleetManager-Specific
```bash
# FleetManager only
./multi-domain-setup.sh init
./multi-domain-setup.sh deploy
./multi-domain-setup.sh status
```

### Traditional Single-Domain
```bash
# Original setup (single domain)
./setup.sh prod
./setup.sh stop
./setup.sh logs
```

## 🌍 Domain Configuration Examples

### Option 1: Subdomain per Application
```
fleet.company.com     → FleetManager Pro
blog.company.com      → WordPress
api.company.com       → REST API
admin.company.com     → Admin Panel
```

### Option 2: Different Domains
```
fleetmanager.com      → FleetManager Pro  
companyblog.com       → WordPress
companyapi.com        → REST API
```

### Option 3: Path-Based (Alternative)
```
company.com           → Main website
company.com/fleet     → FleetManager Pro
company.com/blog      → WordPress
company.com/api       → REST API
```

## 🔧 Architecture Benefits

### ✅ Resource Efficiency
- **Single VPS** hosts multiple applications
- **Shared reverse proxy** handles SSL for all
- **Isolated networks** for security
- **Automatic scaling** with Docker

### ✅ Professional Setup
- **Custom domains** for each application
- **Automatic SSL certificates** (Let's Encrypt)
- **Load balancing** built-in
- **Health monitoring** included

### ✅ Easy Management
- **One-command deployment** for new apps
- **Centralized logging** and monitoring
- **Simple backup** and restore
- **Zero-downtime updates**

## 📋 Prerequisites

### VPS Requirements
- **OS**: Ubuntu 18.04+ (or any Docker-compatible Linux)
- **RAM**: 4GB minimum (2GB per application)
- **CPU**: 2+ cores
- **Storage**: 50GB+ for multiple applications
- **Network**: Static IP with domain access

### Domain Requirements
- **Domain ownership** with DNS management access
- **A records** pointing to your VPS IP
- **Email address** for SSL certificate notifications

### Software Requirements
- **Docker** 20.10+ installed
- **Docker Compose** 2.0+ installed
- **Basic Linux** command line knowledge

## 🚀 Deployment Scenarios

### Scenario 1: Fresh VPS Setup
```bash
# Upload files to VPS
scp -r /app user@vps-ip:~/fleetmanager

# SSH and deploy
ssh user@vps-ip
cd fleetmanager
./domain-manager.sh setup-traefik
./domain-manager.sh deploy-fleet
```

### Scenario 2: Existing Applications
```bash
# Add FleetManager to existing Traefik setup
docker network connect traefik-network existing-traefik-container
./multi-domain-setup.sh deploy
```

### Scenario 3: Migration from Single Domain
```bash
# Stop current setup
./setup.sh stop

# Deploy with Traefik
./domain-manager.sh setup-traefik
./domain-manager.sh deploy-fleet
```

## 🔒 Security Features

### Automatic SSL/TLS
- **Let's Encrypt** certificates auto-generated
- **HTTP to HTTPS** redirect enforced
- **Modern TLS** configuration (A+ rating)
- **Certificate renewal** automated

### Network Security
- **Container isolation** with internal networks
- **No direct port exposure** (except 80/443)
- **Reverse proxy filtering** for all requests
- **Security headers** automatically applied

### Access Control
- **Dashboard authentication** for Traefik
- **Per-application** access controls
- **Rate limiting** capabilities
- **IP whitelisting** options

## 📊 Monitoring & Maintenance

### Built-in Monitoring
```bash
# System health
./domain-manager.sh health

# Service status  
./domain-manager.sh status

# Real-time logs
./domain-manager.sh logs
```

### Traefik Dashboard
- **URL**: `https://traefik.yourdomain.com`
- **Features**: Route visualization, SSL status, health checks
- **Metrics**: Request rates, response times, error rates

### Log Management
- **Centralized logging** for all applications
- **Automatic rotation** prevents disk filling
- **Structured logs** for easy analysis

## 🔄 Adding More Applications

### WordPress Example
```yaml
wordpress:
  image: wordpress:latest
  networks:
    - traefik-network
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.wordpress.rule=Host(`blog.yourdomain.com`)"
    - "traefik.http.routers.wordpress.tls.certresolver=letsencrypt"
```

### API Service Example
```yaml
api-service:
  image: node:18-alpine
  networks:
    - traefik-network
  labels:
    - "traefik.enable=true" 
    - "traefik.http.routers.api.rule=Host(`api.yourdomain.com`)"
    - "traefik.http.routers.api.tls.certresolver=letsencrypt"
```

## 🎯 Success Verification

### Quick Tests
```bash
# Check all services
./domain-manager.sh health

# Test HTTPS access
curl -I https://fleet.yourdomain.com
curl -I https://fleet.yourdomain.com/api/health

# Verify SSL certificate
openssl s_client -connect fleet.yourdomain.com:443
```

### Expected Results
- ✅ All containers running healthy
- ✅ HTTPS responds with valid SSL certificate
- ✅ API endpoints accessible
- ✅ Frontend loads correctly
- ✅ Language switching works
- ✅ User registration/login functional

## 🆘 Troubleshooting Guide

### Common Issues & Solutions

1. **Domain not accessible**
   ```bash
   # Check DNS
   dig fleet.yourdomain.com
   
   # Check Traefik routes
   docker logs traefik | grep -i error
   ```

2. **SSL certificate issues**
   ```bash
   # Check Let's Encrypt logs
   docker logs traefik | grep -i acme
   
   # Verify domain ownership
   curl -I http://fleet.yourdomain.com/.well-known/acme-challenge/test
   ```

3. **Application not responding**
   ```bash
   # Check application health
   ./domain-manager.sh fleet-status
   
   # Check internal connectivity
   docker exec traefik wget -O- http://fleetmanager_frontend:3000
   ```

## 🏆 Final Result

**You now have a professional, production-ready setup that can:**

✅ **Host multiple applications** on one VPS
✅ **Use custom domains** for each application  
✅ **Automatic SSL certificates** for all domains
✅ **Easy application management** with simple commands
✅ **Professional monitoring** and logging
✅ **Zero-downtime deployments** for updates
✅ **Cost-effective scaling** as you grow

**Your VPS is now a powerful, multi-application hosting platform!** 🚀

---

## 📞 Quick Reference

### Essential Commands
```bash
./domain-manager.sh setup-traefik    # One-time setup
./domain-manager.sh deploy-fleet     # Deploy FleetManager
./domain-manager.sh status           # Check everything
./domain-manager.sh health           # Run health checks
```

### Key URLs (replace with your domain)
- FleetManager: `https://fleet.yourdomain.com`
- API Docs: `https://fleet.yourdomain.com/docs`
- Traefik Dashboard: `https://traefik.yourdomain.com`

### Support Files
- Configuration: `.env.domain` and `.env.traefik`
- Logs: `./domain-manager.sh logs`
- Documentation: `MULTI-DOMAIN.md`