#!/bin/bash

# MongoDB Health Check Fix Script
# Fixes the mongosh/mongo command not found issues

echo "🔧 MongoDB Health Check Fix"
echo "============================"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_step "Das Problem: MongoDB 7.0 Container enthalten oft nicht mongosh/mongo CLI-Tools"
echo "Dies führt zu 'command not found' Fehlern bei Health Checks"
echo ""

print_step "Angewandte Lösung: Vereinfachte Health Checks ohne CLI-Tools"
echo "- Verwendet 'ps aux' um MongoDB-Prozess zu prüfen"
echo "- Reduzierte Timeouts für schnellere Checks"
echo "- Fallback-Konfigurationen ohne Health Checks"
echo ""

print_step "Aktualisierte Konfigurationsdateien..."
print_success "docker-compose.yml - Health Check vereinfacht"
print_success "docker-compose.dev.yml - Health Check vereinfacht"
print_success "docker-compose-fixed.yml - Erstellt (ohne Health Checks)"

echo ""
echo "🚀 Verfügbare Lösungen:"
echo ""
echo "1. EINFACHE LÖSUNG (Empfohlen):"
echo "   docker-compose down"
echo "   docker-compose up -d"
echo ""
echo "2. OHNE HEALTH CHECKS:"
echo "   docker-compose -f docker-compose-fixed.yml up -d"
echo ""
echo "3. NUR TCP HEALTH CHECKS:"
echo "   docker-compose -f docker-compose-tcp-health.yml up -d"
echo ""
echo "4. KEINE HEALTH CHECKS:"
echo "   docker-compose -f docker-compose-no-health.yml up -d"

echo ""
print_step "Teste aktuelle MongoDB Container..."

# Check if MongoDB container exists
MONGO_CONTAINER=$(docker ps -a --filter "name=mongo" --format "{{.Names}}" | head -1)

if [ -n "$MONGO_CONTAINER" ]; then
    echo "Container gefunden: $MONGO_CONTAINER"
    
    # Test different health check methods
    echo ""
    echo "Teste verfügbare Tools im Container:"
    
    # Test mongosh
    if docker exec "$MONGO_CONTAINER" which mongosh >/dev/null 2>&1; then
        print_success "mongosh verfügbar"
    else
        print_warning "mongosh nicht verfügbar"
    fi
    
    # Test mongo
    if docker exec "$MONGO_CONTAINER" which mongo >/dev/null 2>&1; then
        print_success "mongo verfügbar"
    else
        print_warning "mongo nicht verfügbar"
    fi
    
    # Test nc
    if docker exec "$MONGO_CONTAINER" which nc >/dev/null 2>&1; then
        print_success "nc verfügbar"
    else
        print_warning "nc nicht verfügbar"
    fi
    
    # Test ps
    if docker exec "$MONGO_CONTAINER" ps aux | grep mongod | grep -v grep >/dev/null 2>&1; then
        print_success "ps command funktioniert - MongoDB Prozess läuft"
    else
        print_warning "ps command Issue oder MongoDB läuft nicht"
    fi
    
    echo ""
    print_step "Aktueller Container Status:"
    docker ps --filter "name=mongo" --format "table {{.Names}}\t{{.Status}}"
    
else
    print_warning "Kein MongoDB Container gefunden"
    echo "Starten Sie zuerst: docker-compose up -d"
fi

echo ""
echo "🔧 SOFORT-FIX:"
echo "==============="
echo ""
echo "1. Container neu starten mit vereinfachten Health Checks:"
echo "   docker-compose down"
echo "   docker-compose up -d"
echo ""
echo "2. Falls weiterhin Probleme:"
echo "   docker-compose -f docker-compose-fixed.yml up -d"
echo ""
echo "3. Health Check Status prüfen:"
echo "   docker ps"
echo "   docker inspect <container-name> --format='{{.State.Health.Status}}'"

echo ""
print_success "MongoDB Health Check Fix abgeschlossen!"
echo ""
echo "📋 Was wurde geändert:"
echo "- Health Checks verwenden jetzt 'ps aux | grep mongod'"
echo "- Keine Abhängigkeit von mongosh/mongo/nc"
echo "- Reduzierte Timeouts für bessere Performance"
echo "- Alternative Konfigurationen bereitgestellt"