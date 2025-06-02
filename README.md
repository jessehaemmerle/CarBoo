# 🚗 Fleet Management System

A comprehensive web application for managing company vehicle fleets with user authentication, booking system, and approval workflows.

## 📋 Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Docker Installation](#docker-installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [API Documentation](#api-documentation)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## ✨ Features

### 🔐 User Management & Authentication
- **JWT-based authentication** with secure password hashing
- **Role-based access control** (Fleet Managers vs Regular Users)
- **User registration and management** by fleet managers

### 🚙 Vehicle Management
- **Complete CRUD operations** for fleet vehicles
- **Multiple vehicle categories** (Sedan, SUV, Truck, Van, Hatchback, Coupe)
- **Real-time status tracking** (Available, In Use, Downtime, Maintenance)
- **Vehicle details management** (Make, Model, Year, License Plate, VIN, Mileage)

### 📅 Booking System
- **Car booking requests** by regular users
- **Manager approval workflow** with approval/rejection reasons
- **Smart availability checking** preventing double bookings
- **Booking status management** (Pending, Approved, Rejected, Completed, Cancelled)

### 🔧 Downtime Management
- **Maintenance and repair tracking** with multiple reasons
- **Cost tracking** for downtime periods
- **Date range management** with automatic status updates
- **Downtime history** and reporting

### 📊 Dashboard & Analytics
- **Real-time fleet statistics** (Total cars, Available, In use, Downtime)
- **Category breakdown** showing vehicle distribution
- **Professional dashboard** with visual indicators

## 🛠 Prerequisites

Before you begin, ensure you have the following installed:

- **Docker** (version 20.10 or higher)
- **Docker Compose** (version 2.0 or higher)
- **Git** (for cloning the repository)

### Installing Docker

#### On Ubuntu/Debian:
```bash
# Update package index
sudo apt-get update

# Install Docker
sudo apt-get install docker.io docker-compose

# Add user to docker group
sudo usermod -aG docker $USER

# Restart session or run:
newgrp docker
```

#### On CentOS/RHEL:
```bash
# Install Docker
sudo yum install -y docker docker-compose

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
```

#### On macOS:
```bash
# Install Docker Desktop from https://www.docker.com/products/docker-desktop
# Or using Homebrew:
brew install --cask docker
```

#### On Windows:
Download and install Docker Desktop from [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)

## 🚀 Docker Installation

### Step 1: Clone the Repository

```bash
git clone <your-repository-url>
cd fleet-management-system
```

### Step 2: Create Docker Compose File

Create a `docker-compose.yml` file in the project root:

```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: fleet_mongodb
    restart: unless-stopped
    environment:
      MONGO_INITDB_DATABASE: fleet_db
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    networks:
      - fleet_network

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: fleet_backend
    restart: unless-stopped
    environment:
      - MONGO_URL=mongodb://mongodb:27017
      - DB_NAME=fleet_db
      - JWT_SECRET_KEY=your-super-secret-jwt-key-change-this-in-production
    ports:
      - "8001:8001"
    depends_on:
      - mongodb
    volumes:
      - ./backend:/app
    networks:
      - fleet_network

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: fleet_frontend
    restart: unless-stopped
    environment:
      - REACT_APP_BACKEND_URL=http://localhost:8001
    ports:
      - "3000:3000"
    depends_on:
      - backend
    volumes:
      - ./frontend:/app
      - /app/node_modules
    networks:
      - fleet_network

volumes:
  mongodb_data:

networks:
  fleet_network:
    driver: bridge
```

### Step 3: Create Backend Dockerfile

Create `backend/Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port
EXPOSE 8001

# Start the application
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8001", "--reload"]
```

### Step 4: Create Frontend Dockerfile

Create `frontend/Dockerfile`:

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
```

### Step 5: Create Environment Files

Create `backend/.env`:

```env
MONGO_URL=mongodb://mongodb:27017
DB_NAME=fleet_db
JWT_SECRET_KEY=your-super-secret-jwt-key-change-this-in-production
```

Create `frontend/.env`:

```env
REACT_APP_BACKEND_URL=http://localhost:8001
```

### Step 6: Build and Run with Docker Compose

```bash
# Build and start all services
docker-compose up --build

# Or run in background
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Stop and remove volumes (WARNING: This will delete all data)
docker-compose down -v
```

### Step 7: Access the Application

Once all containers are running:

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8001
- **API Documentation**: http://localhost:8001/docs
- **MongoDB**: localhost:27017

## ⚙️ Configuration

### Environment Variables

#### Backend Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MONGO_URL` | MongoDB connection string | `mongodb://localhost:27017` |
| `DB_NAME` | Database name | `fleet_db` |
| `JWT_SECRET_KEY` | JWT signing secret | `fleet-management-secret-key-2024` |

#### Frontend Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `REACT_APP_BACKEND_URL` | Backend API URL | `http://localhost:8001` |

### Database Configuration

The application uses MongoDB with the following collections:
- `users` - User accounts and authentication
- `cars` - Vehicle information and status
- `downtimes` - Maintenance and repair records
- `bookings` - Car booking requests and approvals

## 📖 Usage

### Initial Setup

1. **Start the application** using Docker Compose
2. **Access the frontend** at http://localhost:3000
3. **Register the first user** as a Fleet Manager
4. **Add vehicles** to the fleet
5. **Create additional users** as needed

### User Roles

#### Fleet Manager Capabilities:
- ✅ Manage all vehicles (add, edit, delete)
- ✅ Manage downtimes and maintenance
- ✅ Create and manage user accounts
- ✅ Approve/reject booking requests
- ✅ View all fleet statistics and reports

#### Regular User Capabilities:
- ✅ View available vehicles
- ✅ Request car bookings
- ✅ View personal booking history
- ✅ View fleet statistics
- ❌ Cannot manage vehicles or users

### Typical Workflows

#### Adding a Vehicle (Fleet Manager):
1. Navigate to **Cars** tab
2. Click **Add New Car**
3. Fill in vehicle details
4. Submit to add to fleet

#### Requesting a Car (Regular User):
1. Navigate to **Cars** tab
2. Find available vehicle
3. Click **Book Car**
4. Select dates and purpose
5. Submit request for approval

#### Approving Bookings (Fleet Manager):
1. Navigate to **Bookings** tab
2. Review pending requests
3. Click **Approve** or **Reject**
4. Add rejection reason if rejecting

## 🔌 API Documentation

### Authentication Endpoints

```
POST /api/auth/register     # Register new user
POST /api/auth/login        # User login
GET  /api/auth/me          # Get current user info
```

### Car Management Endpoints

```
GET    /api/cars           # List all cars
POST   /api/cars           # Create new car (Manager only)
GET    /api/cars/{id}      # Get car details
PUT    /api/cars/{id}      # Update car (Manager only)
DELETE /api/cars/{id}      # Delete car (Manager only)
```

### Booking Endpoints

```
GET    /api/bookings                    # List bookings
POST   /api/bookings                    # Create booking request
GET    /api/bookings/{id}               # Get booking details
PUT    /api/bookings/{id}               # Update booking
DELETE /api/bookings/{id}               # Cancel booking
PUT    /api/bookings/{id}/approve       # Approve/reject booking (Manager only)
```

### Downtime Endpoints

```
GET    /api/downtimes           # List downtimes
POST   /api/downtimes           # Create downtime (Manager only)
GET    /api/downtimes/car/{id}  # Get car downtimes
PUT    /api/downtimes/{id}      # Update downtime (Manager only)
DELETE /api/downtimes/{id}      # Delete downtime (Manager only)
```

### Fleet Statistics

```
GET /api/fleet/stats        # Get fleet statistics
GET /api/fleet/categories   # Get category breakdown
```

### User Management (Manager Only)

```
GET    /api/users           # List all users
POST   /api/users           # Create new user
DELETE /api/users/{id}      # Delete user
```

## 🐛 Troubleshooting

### Common Issues

#### Container Build Issues

**Problem**: Docker build fails with dependency errors
```bash
# Solution: Clear Docker cache and rebuild
docker-compose down
docker system prune -a
docker-compose up --build
```

#### Database Connection Issues

**Problem**: Backend cannot connect to MongoDB
```bash
# Check if MongoDB container is running
docker-compose ps

# Check MongoDB logs
docker-compose logs mongodb

# Restart MongoDB service
docker-compose restart mongodb
```

#### Frontend Connection Issues

**Problem**: Frontend cannot reach backend API
```bash
# Check backend logs
docker-compose logs backend

# Verify backend is running on port 8001
curl http://localhost:8001/docs

# Check environment variables
docker-compose exec frontend env | grep REACT_APP_BACKEND_URL
```

#### Port Conflicts

**Problem**: Port already in use
```bash
# Check what's using the port
sudo lsof -i :3000
sudo lsof -i :8001
sudo lsof -i :27017

# Kill the process or change ports in docker-compose.yml
```

### Docker Commands

```bash
# View running containers
docker-compose ps

# View logs for specific service
docker-compose logs backend
docker-compose logs frontend
docker-compose logs mongodb

# Restart specific service
docker-compose restart backend

# Execute commands in running container
docker-compose exec backend bash
docker-compose exec frontend sh

# Remove all containers and volumes (CAUTION: Data loss)
docker-compose down -v
docker system prune -a
```

### Database Management

```bash
# Access MongoDB shell
docker-compose exec mongodb mongosh fleet_db

# Basic MongoDB commands
show collections
db.cars.find()
db.users.find()
db.bookings.find()

# Backup database
docker-compose exec mongodb mongodump --db fleet_db --out /data/backup

# Restore database
docker-compose exec mongodb mongorestore --db fleet_db /data/backup/fleet_db
```

## 🧪 Development

### Running in Development Mode

```bash
# Start only MongoDB
docker-compose up mongodb -d

# Run backend locally
cd backend
pip install -r requirements.txt
uvicorn server:app --reload --port 8001

# Run frontend locally
cd frontend
npm install
npm start
```

### Testing

```bash
# Run backend tests
cd backend
python -m pytest

# Run frontend tests
cd frontend
npm test
```

### Code Structure

```
fleet-management-system/
├── backend/
│   ├── server.py           # FastAPI application
│   ├── requirements.txt    # Python dependencies
│   ├── .env               # Backend environment variables
│   └── Dockerfile         # Backend Docker configuration
├── frontend/
│   ├── src/
│   │   ├── App.js         # Main React component
│   │   ├── App.css        # Styling
│   │   └── index.js       # Entry point
│   ├── package.json       # Node.js dependencies
│   ├── .env              # Frontend environment variables
│   └── Dockerfile        # Frontend Docker configuration
├── docker-compose.yml    # Docker Compose configuration
└── README.md             # This file
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

If you encounter any issues or have questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review the [API Documentation](#api-documentation)
3. Create an issue in the GitHub repository
4. Contact the development team

## 🚀 Deployment

### Production Deployment

For production deployment, consider:

1. **Security**:
   - Change default JWT secret key
   - Use environment-specific configurations
   - Enable HTTPS/SSL
   - Set up proper firewall rules

2. **Performance**:
   - Use production-grade databases
   - Set up load balancing
   - Configure caching
   - Optimize Docker images

3. **Monitoring**:
   - Set up logging and monitoring
   - Configure health checks
   - Set up backup strategies
   - Monitor resource usage

### Example Production docker-compose.yml

```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    restart: always
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_ROOT_PASSWORD}
      MONGO_INITDB_DATABASE: fleet_db
    volumes:
      - mongodb_data:/data/db
    networks:
      - fleet_network

  backend:
    build: ./backend
    restart: always
    environment:
      - MONGO_URL=mongodb://root:${MONGO_ROOT_PASSWORD}@mongodb:27017/fleet_db?authSource=admin
      - DB_NAME=fleet_db
      - JWT_SECRET_KEY=${JWT_SECRET_KEY}
    depends_on:
      - mongodb
    networks:
      - fleet_network

  frontend:
    build: ./frontend
    restart: always
    environment:
      - REACT_APP_BACKEND_URL=${BACKEND_URL}
    depends_on:
      - backend
    networks:
      - fleet_network

  nginx:
    image: nginx:alpine
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - frontend
      - backend
    networks:
      - fleet_network

volumes:
  mongodb_data:

networks:
  fleet_network:
    driver: bridge
```

---

**Happy Fleet Managing! 🚗💨**
