# MongoDB Container Health Check Troubleshooting Guide

## 🔧 Quick Fixes for Unhealthy MongoDB Container

### Option 1: Use Alternative Docker Compose (Recommended)

If you're experiencing MongoDB health check issues, use one of these alternative configurations:

#### A) Simple TCP Health Check:
```bash
# Use TCP-based health check (more reliable)
docker-compose -f docker-compose-tcp-health.yml up --build -d
```

#### B) No Health Check Dependencies:
```bash
# Remove health check dependencies entirely
docker-compose -f docker-compose-no-health.yml up --build -d
```

### Option 2: Debug Current Setup

Run the debug script to identify the issue:
```bash
./debug-mongodb-health.sh
```

### Option 3: Manual MongoDB Health Check Test

Test MongoDB connectivity manually:
```bash
# Check if container is running
docker ps | grep mongo

# Test MongoDB connection directly
docker exec <container-name> mongosh --eval "db.adminCommand('ping')"
```

## 🚨 Common Issues and Solutions

### Issue 1: `mongosh` Command Not Found
**Problem**: MongoDB 7.0 container doesn't have `mongosh`
**Solution**: Use legacy `mongo` command or TCP check

### Issue 2: Authentication Required
**Problem**: Health check can't connect without authentication
**Solution**: Use TCP check or configure authentication in health check

### Issue 3: Container Takes Too Long to Start
**Problem**: MongoDB initialization takes longer than health check timeout
**Solution**: Increase `start_period` to 60+ seconds

### Issue 4: Health Check Command Syntax Error
**Problem**: Incorrect command syntax for health check
**Solution**: Use simplified command format

## 🔄 Health Check Configurations

### Current Configuration (if working):
```yaml
healthcheck:
  test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### Alternative 1: TCP Check Only
```yaml
healthcheck:
  test: ["CMD-SHELL", "nc -z localhost 27017 || exit 1"]
  interval: 30s
  timeout: 5s
  retries: 5
  start_period: 30s
```

### Alternative 2: Legacy Mongo Command
```yaml
healthcheck:
  test: ["CMD", "mongo", "--eval", "db.adminCommand('ping')"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### Alternative 3: No Health Check
```yaml
# Remove healthcheck section entirely
# Use depends_on without condition: service_healthy
depends_on:
  - mongodb
```

## 🛠️ Step-by-Step Troubleshooting

### Step 1: Check Container Status
```bash
docker ps | grep mongo
docker logs <mongodb-container-name>
```

### Step 2: Test MongoDB Connectivity
```bash
# From host machine
docker exec <container-name> mongosh --eval "db.adminCommand('ping')"

# Check if mongosh exists
docker exec <container-name> which mongosh
```

### Step 3: Check Health Status
```bash
# Inspect health check logs
docker inspect <container-name> --format='{{.State.Health.Status}}'
docker inspect <container-name> --format='{{range .State.Health.Log}}{{.Output}}{{end}}'
```

### Step 4: Try Alternative Commands
```bash
# Test different health check commands
docker exec <container-name> mongo --eval "db.adminCommand('ping')"
docker exec <container-name> nc -z localhost 27017
```

## 🚀 Immediate Solutions

### Quick Fix 1: Remove Health Check Dependencies
Edit your docker-compose.yml and change:
```yaml
depends_on:
  mongodb:
    condition: service_healthy
```
To:
```yaml
depends_on:
  - mongodb
```

### Quick Fix 2: Use Simple TCP Check
Replace the health check with:
```yaml
healthcheck:
  test: ["CMD-SHELL", "timeout 5 bash -c 'cat < /dev/null > /dev/tcp/localhost/27017'"]
  interval: 30s
  timeout: 5s
  retries: 5
  start_period: 30s
```

### Quick Fix 3: Disable Health Checks Temporarily
Comment out the entire healthcheck section:
```yaml
# healthcheck:
#   test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
#   interval: 30s
#   timeout: 10s
#   retries: 3
#   start_period: 40s
```

## 📊 Testing Your Fix

After applying any fix:

1. **Stop existing containers:**
   ```bash
   docker-compose down
   ```

2. **Start with new configuration:**
   ```bash
   docker-compose up --build -d
   ```

3. **Monitor health status:**
   ```bash
   watch 'docker ps --format "table {{.Names}}\t{{.Status}}"'
   ```

4. **Test application:**
   ```bash
   curl http://localhost:8001/api/health
   curl http://localhost/health
   ```

## 🆘 Emergency Deployment (No Health Checks)

If you need to deploy immediately without health checks:

```bash
# Use the no-health-check version
docker-compose -f docker-compose-no-health.yml up --build -d

# Or temporarily modify main compose file
# Comment out all healthcheck sections and change depends_on conditions
```

## 📞 Support Commands

```bash
# Debug MongoDB health
./debug-mongodb-health.sh

# Validate Docker configuration
./validate-docker-config.sh

# Check application status
./docker-start.sh status

# View logs
./docker-start.sh logs
```