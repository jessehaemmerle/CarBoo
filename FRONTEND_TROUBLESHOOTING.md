# Frontend Container Restart Troubleshooting Guide

## 🚨 Frontend Container Keeps Restarting - Solutions

### Quick Diagnosis
Run the debug script first:
```bash
./debug-frontend.sh
```

## 🔧 Immediate Fixes

### Fix 1: Nginx Configuration Issue (Most Likely Cause)
**Problem**: The nginx.conf had an incorrect `http` block causing startup failures.
**Solution**: Updated nginx configuration (already fixed)

```bash
# Apply the fix
docker-compose down
docker-compose up --build -d
```

### Fix 2: Use Alternative Frontend Build
**Problem**: Memory or build issues with production Dockerfile
**Solution**: Use the enhanced Dockerfile

```bash
# Use the fixed production Dockerfile
docker-compose down
docker build -t fleetmanager-frontend-fixed -f frontend/Dockerfile.prod.fixed frontend/
docker-compose up -d
```

### Fix 3: Debug Mode Deployment
**Problem**: Need detailed logging to identify the issue
**Solution**: Use debug configuration

```bash
# Use debug configuration with enhanced logging
docker-compose -f docker-compose-frontend-debug.yml up -d
```

### Fix 4: Simple Fallback (Development Mode)
**Problem**: Production build issues
**Solution**: Use simple Node.js development server

```bash
# Start simple development server on port 3000
docker-compose -f docker-compose-frontend-debug.yml --profile debug up frontend-simple
```

## 🔍 Common Issues and Solutions

### Issue 1: Nginx Configuration Conflicts
**Symptoms**: Container exits immediately with nginx errors
**Cause**: Duplicate `http` blocks in nginx configuration
**Solution**: ✅ Already fixed in nginx.conf

### Issue 2: Memory Issues During Build
**Symptoms**: Build process crashes, "heap out of memory" errors
**Solutions**:
```bash
# Option A: Increase Docker memory limits
# In Docker Desktop: Settings > Resources > Memory > 4GB+

# Option B: Use memory-optimized build
docker build --memory=2g -f frontend/Dockerfile.prod.fixed frontend/

# Option C: Use swap space on server
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Issue 3: Port 80 Permission Issues
**Symptoms**: Permission denied errors, port conflicts
**Solutions**:
```bash
# Check what's using port 80
sudo netstat -tulnp | grep :80

# Stop conflicting services
sudo systemctl stop apache2 nginx

# Use alternative port
echo "FRONTEND_HOST_PORT=8080" >> .env
docker-compose up -d
```

### Issue 4: Build Dependencies Missing
**Symptoms**: "Module not found" errors during build
**Solutions**:
```bash
# Clean rebuild with fresh dependencies
docker-compose down
docker system prune -f
rm -rf frontend/node_modules
docker-compose up --build --no-cache -d
```

### Issue 5: Environment Variable Issues
**Symptoms**: Blank pages, API connection errors
**Solutions**:
```bash
# Check environment variables
cat frontend/.env
cat .env

# Ensure REACT_APP_BACKEND_URL is set correctly
echo "REACT_APP_BACKEND_URL=http://localhost:8001" > frontend/.env
```

## 🛠️ Step-by-Step Debugging

### Step 1: Check Container Status
```bash
# Check if container is running
docker ps | grep frontend

# Check restart count
docker inspect <container-name> --format='{{.RestartCount}}'

# Check exit code
docker inspect <container-name> --format='{{.State.ExitCode}}'
```

### Step 2: Examine Logs
```bash
# View recent logs
docker logs --tail 50 <frontend-container>

# Follow logs in real-time
docker logs -f <frontend-container>

# Check nginx error logs (if using nginx)
docker exec <frontend-container> cat /var/log/nginx/error.log
```

### Step 3: Test Manual Build
```bash
# Test build manually
docker build -t test-frontend frontend/

# Test with debug Dockerfile
docker build -t test-frontend-debug -f frontend/Dockerfile.debug frontend/

# Run interactively to debug
docker run -it --rm test-frontend-debug /bin/sh
```

### Step 4: Check System Resources
```bash
# Check available memory
free -h

# Check disk space
df -h

# Check Docker system usage
docker system df
```

## 🚀 Alternative Deployment Methods

### Method 1: Debug Configuration
```bash
# Use enhanced debug configuration
docker-compose -f docker-compose-frontend-debug.yml up -d

# Check logs
docker-compose -f docker-compose-frontend-debug.yml logs frontend
```

### Method 2: Development Mode Fallback
```bash
# Use simple development server
docker run -d --name frontend-dev \
  -p 3000:3000 \
  -v $(pwd)/frontend:/app \
  -e REACT_APP_BACKEND_URL=http://localhost:8001 \
  node:20-alpine sh -c "cd /app && yarn install && yarn start"
```

### Method 3: Host-Based Deployment (Emergency)
```bash
# Install Node.js on host if needed
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Run frontend on host
cd frontend
npm install
REACT_APP_BACKEND_URL=http://localhost:8001 npm run build
sudo npm install -g serve
serve -s build -l 80
```

## 📋 Configuration Files Reference

### Fixed nginx.conf
- ✅ Removed duplicate `http` block
- ✅ Added proper proxy headers
- ✅ Enhanced gzip configuration
- ✅ Better health check endpoint

### Enhanced Dockerfile.prod.fixed
- ✅ Memory optimization for build process
- ✅ Better error handling
- ✅ Enhanced logging
- ✅ Proper permissions setup

### Debug Configuration
- ✅ Enhanced logging volumes
- ✅ Fallback development server
- ✅ No auto-restart for debugging
- ✅ Multiple frontend options

## 🆘 Emergency Fixes

### If frontend still won't start:

1. **Bypass frontend container entirely:**
```bash
# Stop frontend container
docker stop <frontend-container>

# Serve static files directly
cd frontend && npm run build
python3 -m http.server 80 --directory build
```

2. **Use nginx on host:**
```bash
sudo apt install nginx
sudo cp frontend/build/* /var/www/html/
sudo systemctl start nginx
```

3. **Port forwarding workaround:**
```bash
# Run on different port and forward
docker run -d -p 8080:80 <frontend-image>
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
```

## 📞 Get Help

```bash
# Run comprehensive debug
./debug-frontend.sh

# Check all configurations
./validate-docker-config.sh

# View all logs
docker-compose logs

# System information
docker system info
docker version
```

## ✅ Success Indicators

Your frontend is working correctly when:
- ✅ Container status shows "healthy" or "running"
- ✅ No restart loops (restart count stays at 0)
- ✅ HTTP 200 response: `curl http://localhost/health`
- ✅ Frontend loads: `curl http://localhost`
- ✅ API connectivity: Check browser developer tools for API calls

## 🎯 Most Likely Solutions for Your Case

Based on fresh Ubuntu server with Docker installation:

1. **Fixed nginx configuration** (already applied)
2. **Memory allocation** for Docker/build process
3. **Port 80 permissions** or conflicts
4. **Missing environment variables**

Try these in order:
```bash
# 1. Apply nginx fix and rebuild
docker-compose down && docker-compose up --build -d

# 2. If still failing, use debug mode
docker-compose -f docker-compose-frontend-debug.yml up -d

# 3. Check logs and system resources
./debug-frontend.sh
```