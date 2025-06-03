# 🌐 Multi-Domain Setup Guide - FleetManager Pro

Run FleetManager Pro alongside other applications on your VPS with different domains using Traefik reverse proxy.

## 🎯 Overview

This setup allows you to:
- ✅ Run multiple applications on one VPS
- ✅ Use different domains for each application
- ✅ Automatic SSL certificates with Let's Encrypt
- ✅ Easy domain-based routing
- ✅ Share resources efficiently

## 🏗️ Architecture

```
Internet → Traefik (Ports 80/443) → Applications
├── fleet.yourdomain.com     → FleetManager Pro
├── blog.yourdomain.com      → WordPress
├── api.yourdomain.com       → API Application
└── shop.yourdomain.com      → E-commerce App
```

## 🚀 Quick Setup (5 minutes)

### 1. Initialize Traefik Network
```bash
./multi-domain-setup.sh init
```

### 2. Configure Your Domain
```bash
# Edit the domain configuration
nano .env.domain

# Set your domain and email
DOMAIN=fleet.yourdomain.com
ACME_EMAIL=your-email@domain.com
```

### 3. Point DNS to Your VPS
Configure your domain's DNS A record:
```
fleet.yourdomain.com → YOUR_VPS_IP
```

### 4. Deploy FleetManager Pro
```bash
./multi-domain-setup.sh deploy
```

### 5. Access Your Application
Visit: `https://fleet.yourdomain.com`

## 📋 Detailed Setup

### Prerequisites

1. **Domain Name**: You need a domain pointing to your VPS
2. **DNS Access**: Ability to create A records
3. **VPS Requirements**: 
   - Ubuntu 18.04+ or similar
   - 2GB+ RAM
   - Docker & Docker Compose
   - Ports 80 and 443 available

### Step-by-Step Configuration

#### 1. Domain Configuration (.env.domain)

```bash
# Your domain for FleetManager Pro
DOMAIN=fleet.yourdomain.com

# Email for SSL certificates (required by Let's Encrypt)
ACME_EMAIL=admin@yourdomain.com

# Generated automatically (or set manually)
MONGO_PASSWORD=your-secure-mongodb-password
JWT_SECRET=your-super-secure-jwt-secret

# Optional: Traefik dashboard authentication
TRAEFIK_AUTH=admin:$2y$10$hashed-password

ENVIRONMENT=production
```

#### 2. DNS Configuration

Create these DNS records:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | fleet.yourdomain.com | YOUR_VPS_IP | 300 |
| A | traefik.yourdomain.com | YOUR_VPS_IP | 300 |

#### 3. Firewall Configuration

```bash
# Allow HTTP and HTTPS traffic
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp  # SSH
sudo ufw enable
```

## 🎛️ Management Commands

```bash
# Initialize Traefik network
./multi-domain-setup.sh init

# Deploy FleetManager Pro
./multi-domain-setup.sh deploy

# Stop services
./multi-domain-setup.sh stop

# Restart services
./multi-domain-setup.sh restart

# View logs
./multi-domain-setup.sh logs

# Check status
./multi-domain-setup.sh status

# Remove FleetManager (keep Traefik)
./multi-domain-setup.sh remove

# Show help
./multi-domain-setup.sh help
```

## 🔧 Adding Other Applications

### Example: Adding WordPress

1. **Create WordPress compose file:**
```yaml
version: '3.8'
services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress_blog
    environment:
      WORDPRESS_DB_HOST: wordpress_db
      WORDPRESS_DB_PASSWORD: ${WP_DB_PASSWORD}
    networks:
      - traefik-network
      - wordpress-internal
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.wordpress.rule=Host(`blog.yourdomain.com`)"
      - "traefik.http.routers.wordpress.tls.certresolver=letsencrypt"
      - "traefik.http.services.wordpress.loadbalancer.server.port=80"

networks:
  traefik-network:
    external: true
  wordpress-internal:
    driver: bridge
```

2. **Deploy alongside FleetManager:**
```bash
# FleetManager is already running on fleet.yourdomain.com
docker-compose -f wordpress-compose.yml up -d
# WordPress will be available on blog.yourdomain.com
```

### Example: Adding API Application

```yaml
version: '3.8'
services:
  api_app:
    image: node:20-alpine
    container_name: my_api
    networks:
      - traefik-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`api.yourdomain.com`)"
      - "traefik.http.routers.api.tls.certresolver=letsencrypt"
      - "traefik.http.services.api.loadbalancer.server.port=3000"

networks:
  traefik-network:
    external: true
```

## 🔒 SSL/TLS Configuration

### Automatic SSL Certificates

Traefik automatically handles SSL certificates via Let's Encrypt:

1. **First Request**: Certificate is generated automatically
2. **Renewal**: Automatic renewal before expiration
3. **Security**: Modern TLS configuration with A+ rating

### Manual Certificate Management

```bash
# View certificates
docker exec traefik cat /acme.json

# Check certificate status
openssl s_client -connect fleet.yourdomain.com:443 -servername fleet.yourdomain.com
```

## 📊 Monitoring & Logging

### Traefik Dashboard

Access the Traefik dashboard (if enabled):
- URL: `https://traefik.yourdomain.com`
- Shows all routes, services, and SSL certificates
- Real-time metrics and health checks

### Application Logs

```bash
# FleetManager logs
./multi-domain-setup.sh logs

# Traefik logs
docker logs traefik

# Specific service logs
docker logs fleetmanager_frontend
docker logs fleetmanager_backend
```

### Health Monitoring

```bash
# Check all services
./multi-domain-setup.sh status

# Test endpoints
curl -I https://fleet.yourdomain.com
curl -I https://fleet.yourdomain.com/api/health
```

## 🔧 Troubleshooting

### Common Issues

1. **Domain not resolving**
   ```bash
   # Check DNS propagation
   dig fleet.yourdomain.com
   nslookup fleet.yourdomain.com
   ```

2. **SSL certificate not generating**
   ```bash
   # Check Traefik logs
   docker logs traefik
   
   # Verify domain points to VPS
   ping fleet.yourdomain.com
   ```

3. **Service not accessible**
   ```bash
   # Check if service is running
   ./multi-domain-setup.sh status
   
   # Check Traefik routes
   curl http://localhost:8080/api/http/routers
   ```

4. **Port conflicts**
   ```bash
   # Check what's using ports 80/443
   sudo lsof -i :80
   sudo lsof -i :443
   ```

### Debug Mode

Enable debug logging in Traefik:
```bash
# Add to Traefik command in docker-compose.traefik.yml
- --log.level=DEBUG
```

## 🚀 Performance Optimization

### Resource Allocation

For multiple applications:
- **4GB RAM minimum** (recommended 8GB)
- **4 CPU cores** for good performance
- **50GB+ disk space** for multiple apps + logs

### Traefik Optimization

```yaml
# Add to Traefik configuration
command:
  # Connection pooling
  - --serversTransport.maxIdleConnsPerHost=100
  # Request timeouts
  - --entrypoints.websecure.transport.respondingTimeouts.readTimeout=60s
  # Rate limiting
  - --http.middlewares.rate-limit.rateLimit.burst=100
```

## 📈 Scaling

### Horizontal Scaling

Run multiple instances of the same application:
```yaml
deploy:
  replicas: 3
labels:
  - "traefik.http.services.app.loadbalancer.sticky.cookie=true"
```

### Load Balancing

Traefik automatically load balances between multiple instances:
```yaml
# Multiple backend instances
backend_1:
  # ... service config
backend_2:
  # ... service config
# Traefik automatically distributes load
```

## 🔄 Backup Strategy

### Application Data
```bash
# Backup FleetManager data
./multi-domain-setup.sh stop
docker run --rm -v fleetmanager_mongodb_data:/data -v $(pwd)/backups:/backup alpine tar czf /backup/fleetmanager-$(date +%Y%m%d).tar.gz /data
```

### Traefik Configuration
```bash
# Backup certificates and config
docker cp traefik:/acme.json ./backups/acme-$(date +%Y%m%d).json
```

## 🎯 Domain Examples

Here are some common domain patterns:

| Application | Domain | Purpose |
|-------------|--------|---------|
| FleetManager Pro | `fleet.company.com` | Fleet management |
| WordPress Blog | `blog.company.com` | Company blog |
| API Service | `api.company.com` | REST API |
| Admin Panel | `admin.company.com` | Administration |
| Documentation | `docs.company.com` | Documentation |
| Status Page | `status.company.com` | System status |

## ✅ Success Checklist

- [ ] Domain DNS pointing to VPS IP
- [ ] Traefik network created
- [ ] .env.domain configured
- [ ] FleetManager Pro deployed
- [ ] SSL certificate generated
- [ ] Application accessible via HTTPS
- [ ] All health checks passing
- [ ] Backup strategy in place

## 🆘 Support

### Quick Diagnostics
```bash
# Run comprehensive check
./multi-domain-setup.sh status

# Check network connectivity
docker network ls | grep traefik
docker ps | grep -E "(traefik|fleetmanager)"

# Test internal connectivity
docker exec fleetmanager_frontend curl -f http://fleetmanager_backend:8001/api/health
```

---

## 🏆 Multi-Domain Benefits

✅ **Cost Effective**: One VPS for multiple applications
✅ **Easy Management**: Single point for SSL and routing
✅ **Scalable**: Add new applications easily
✅ **Secure**: Automatic SSL certificates
✅ **Professional**: Clean domain structure
✅ **Maintainable**: Centralized configuration

**Your VPS is now ready to host multiple applications with professional domain-based routing!**