# Docker Installation Scripts

Dieses Verzeichnis enthält automatisierte Skripte für die vollständige Docker-Installation auf Linux-Systemen.

## 🚀 Schnellinstallation

### Für Ubuntu/Debian-Systeme:
```bash
./quick-install-docker.sh
```

**Features:**
- ✅ Ein-Befehl-Installation
- ✅ Schnell und einfach
- ✅ Installiert Docker + Docker Compose
- ✅ Konfiguriert Benutzerberechtigungen
- ⚠️  Nur für Ubuntu/Debian

## 🛠️ Vollständige Installation

### Für alle Linux-Distributionen:
```bash
./install-docker.sh
```

**Features:**
- ✅ Unterstützt alle Linux-Distributionen
- ✅ Automatische OS-Erkennung
- ✅ Interaktive Installations-Optionen
- ✅ Update- und Entfernungs-Optionen
- ✅ Umfassende Konfiguration
- ✅ Installations-Verifikation

**Unterstützte Systeme:**
- Ubuntu/Debian
- CentOS/RHEL/Fedora
- Amazon Linux
- Andere Linux-Distributionen

## 📋 Verfügbare Befehle

### Vollständige Installation
```bash
./install-docker.sh                # Standard-Installation
./install-docker.sh install        # Explizite Installation
./install-docker.sh remove         # Docker entfernen
./install-docker.sh verify         # Installation überprüfen
./install-docker.sh help           # Hilfe anzeigen
```

### Schnellinstallation
```bash
./quick-install-docker.sh          # Schnelle Installation (Ubuntu/Debian)
```

## 🔄 Automatische Installation

Das `docker-start.sh` Skript bietet automatische Docker-Installation an:

```bash
./docker-start.sh docker-prod
```

Wenn Docker nicht installiert ist, erhalten Sie Optionen:
1. **Schnellinstallation** - Ubuntu/Debian nur
2. **Vollständige Installation** - Alle Linux-Distributionen
3. **Manuelle Installation** - Links zur Dokumentation
4. **Beenden**

## ⚙️ Was wird installiert?

### Docker Engine
- Neueste stabile Docker-Version
- Docker CLI-Tools
- Container-Runtime (containerd)
- Docker BuildKit
- Docker Compose Plugin

### Docker Compose
- Neueste Docker Compose Version
- Standalone-Installation (falls benötigt)
- Symbolische Links für einfachen Zugriff

### Konfiguration
- Docker-Dienst aktiviert und gestartet
- Benutzer zur docker-Gruppe hinzugefügt
- Optimierte Daemon-Konfiguration
- Log-Rotation konfiguriert

## 🔍 Installations-Verifikation

Nach der Installation:

```bash
# Docker-Version prüfen
docker --version
docker-compose --version

# Docker-Funktionalität testen
docker run hello-world

# Fleet Management starten
./docker-start.sh docker-prod
```

## 🛠️ Fehlerbehebung

### Häufige Probleme:

**Docker-Daemon läuft nicht:**
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

**Berechtigungsfehler:**
```bash
# Nach Installation: Neu anmelden oder:
newgrp docker
```

**Docker Compose nicht gefunden:**
```bash
# Vollständige Installation erneut ausführen:
./install-docker.sh
```

### Log-Überprüfung:
```bash
# Docker-Service-Logs
sudo journalctl -u docker

# Container-Logs
docker logs <container-name>
```

## 📋 Systemanforderungen

### Mindestanforderungen:
- Linux-basiertes Betriebssystem
- 64-bit Architektur
- Kernel-Version 3.10+
- 2GB RAM (empfohlen: 4GB+)
- 20GB freier Festplattenspeicher

### Unterstützte Architekturen:
- x86_64 (amd64)
- armhf (arm32v7)
- arm64 (arm64v8)

## 🔒 Sicherheitshinweise

### Nach der Installation:
1. **Benutzerberechtigungen** überprüfen
2. **Firewall-Regeln** anpassen (Ports 80, 8001, 27017)
3. **Docker-Daemon-Konfiguration** überprüfen
4. **Regelmäßige Updates** durchführen

### Produktionsumgebung:
- Docker-Registry-Sicherheit konfigurieren
- Container-Sicherheitsrichtlinien festlegen
- Monitoring und Logging einrichten
- Backup-Strategien implementieren

## 📞 Support

Bei Problemen:

1. **Konfiguration validieren:**
   ```bash
   ./validate-docker-config.sh
   ```

2. **Installation überprüfen:**
   ```bash
   ./install-docker.sh verify
   ```

3. **Logs überprüfen:**
   ```bash
   ./docker-start.sh logs
   ```

4. **Neuinstallation:**
   ```bash
   ./install-docker.sh remove
   ./install-docker.sh install
   ```

## 🚗 Fleet Management Integration

Nach erfolgreicher Docker-Installation:

```bash
# Produktion starten (Port 80)
./docker-start.sh docker-prod

# Entwicklung starten (Port 3000)
./docker-start.sh docker-dev

# Status überprüfen
./docker-start.sh status

# Konfiguration validieren
./validate-docker-config.sh
```

Ihre Fleet Management Anwendung ist dann verfügbar unter:
- **Frontend:** http://localhost (Port 80)
- **Backend API:** http://localhost:8001
- **API-Dokumentation:** http://localhost:8001/docs