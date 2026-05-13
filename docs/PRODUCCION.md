# Guía de Producción - MG-Firma Legal

## 📋 Contenido

1. [Requisitos Previos](#requisitos-previos)
2. [Opción 1: Docker Compose (Recomendado)](#opción-1-docker-compose-recomendado)
3. [Opción 2: Instalación Directa con Systemd](#opción-2-instalación-directa-con-systemd)
4. [Opción 3: Coolify (PaaS)](#opción-3-coolify-paas)
5. [Configuración de Variables de Entorno](#configuración-de-variables-de-entorno)
6. [Seguridad](#seguridad)
7. [Mantenimiento](#mantenimiento)

---

## Requisitos Previos

- **VPS**: Ubuntu 22.04+ o Debian 11+
- **RAM**: Mínimo 4GB (8GB+ recomendado)
- **Almacenamiento**: 20GB+ (depende del uso)
- **CPU**: 2+ cores (4+ recomendado)
- **Dominio**: Para SSL (opcional pero recomendado)

---

## Opción 1: Docker Compose (Recomendado)

### 1. Preparar el Build en Local

```bash
# En tu máquina de desarrollo
cd /Users/codingsoft/GitHub/mg-politica-web
npm run build
```

### 2. Crear Dockerfile Personalizado

```dockerfile
FROM ghcr.io/open-webui/open-webui:main

# Copiar archivos personalizados
COPY build/ /app/frontend/
COPY backend/open_webui/static/ /app/backend/open_webui/static/

# Variables de entorno
ENV WEBUI_NAME="MG-Firma Legal"
ENV WEBUI_SECRET_KEY=""

EXPOSE 8080
```

### 3. Docker Compose

```yaml
version: '3.8'

services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    restart: always

  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: mg-firma-legal
    ports:
      - "8080:8080"
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
      - WEBUI_NAME=MG-Firma Legal
      - WEBUI_SECRET_KEY=${WEBUI_SECRET_KEY:-}
      - ENABLE_SIGNUP=false
      - DEFAULT_USER_ROLE=user
      - ENABLE_COMMUNITY_SHARING=false
    volumes:
      - webui_data:/app/backend/data
    depends_on:
      - ollama
    restart: always

volumes:
  ollama_data:
  webui_data:
```

### 4. Despliegue

```bash
# Generar clave secreta
WEBUI_SECRET_KEY=$(openssl rand -hex 32)

# Crear archivo .env
echo "WEBUI_SECRET_KEY=$WEBUI_SECRET_KEY" > .env

# Desplegar
docker compose up -d

# Ver logs
docker compose logs -f
```

---

## Opción 2: Instalación Directa con Systemd

### 1. Preparar el Servidor

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependencias
sudo apt install -y python3.11 python3.11-venv python3-pip nodejs npm git curl

# Crear usuario para la aplicación
sudo useradd -m -s /bin/bash mgfirma
sudo usermod -aG sudo mgfirma
```

### 2. Configurar la Aplicación

```bash
# Cambiar al usuario
sudo -i -u mgfirma

# Clonar repositorio
cd /home/mgfirma
git clone https://github.com/CodingSoft/mg-politica-web.git
cd mg-politica-web

# Instalar dependencias de Python
python3.11 -m venv venv
source venv/bin/activate
cd backend
pip install -e .

# Construir frontend
cd ..
npm install --force
npm run build
```

### 3. Crear Servicio Systemd

```bash
sudo nano /etc/systemd/system/mg-firma-legal.service
```

Contenido:

```ini
[Unit]
Description=MG-Firma Legal Service
After=network.target

[Service]
Type=exec
User=mgfirma
Group=mgfirma
WorkingDirectory=/home/mgfirma/mg-politica-web/backend
Environment="PATH=/home/mgfirma/mg-politica-web/venv/bin"
Environment="WEBUI_NAME=MG-Firma Legal"
Environment="WEBUI_SECRET_KEY=tu_clave_secreta_aqui"
ExecStart=/home/mgfirma/mg-politica-web/venv/bin/uvicorn open_webui.main:app --host 0.0.0.0 --port 8080
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 4. Iniciar Servicio

```bash
sudo systemctl daemon-reload
sudo systemctl enable mg-firma-legal
sudo systemctl start mg-firma-legal
sudo systemctl status mg-firma-legal
```

---

## Opción 3: Coolify (PaaS)

### 1. Instalar Coolify

```bash
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

### 2. Configurar en Coolify

1. Acceder a `http://tu-servidor:3000`
2. Crear nuevo proyecto
3. Conectar repositorio GitHub: `CodingSoft/mg-politica-web`
4. Coolify detectará automáticamente el `Dockerfile` o `docker-compose.yml`
5. Configurar variables de entorno en la interfaz
6. Desplegar

---

## Configuración de Variables de Entorno

### Variables Críticas

```bash
# Clave secreta para sesiones (OBLIGATORIO)
WEBUI_SECRET_KEY="tu_clave_de_64_caracteres_aqui"

# Nombre de la aplicación
WEBUI_NAME="MG-Firma Legal"

# Base de datos (opcional, por defecto SQLite)
DATABASE_URL="postgresql://usuario:password@localhost:5432/mg_firma_legal"

# Configuración de Ollama (opcional)
OLLAMA_BASE_URL="http://localhost:11434"

# Configuración de OpenAI (opcional)
OPENAI_API_KEY="sk-..."

# Seguridad
ENABLE_SIGNUP="false"
DEFAULT_USER_ROLE="user"
ENABLE_COMMUNITY_SHARING="false"
```

### Generar Clave Secreta

```bash
openssl rand -hex 32
```

---

## Seguridad

### 1. Firewall (UFW)

```bash
sudo ufw enable
sudo ufw default deny incoming
sudo ufw allow from any to any port 22 proto tcp  # SSH
sudo ufw allow from any to any port 80 proto tcp  # HTTP (para SSL)
sudo ufw allow from any to any port 443 proto tcp # HTTPS
sudo ufw allow from any to any port 8080 proto tcp # App (si no usas proxy)
sudo ufw status
```

### 2. Fail2Ban

```bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 3. SSL con Caddy (Recomendado)

```yaml
# docker-compose.yml
services:
  caddy:
    image: caddy:2-alpine
    container_name: caddy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
    restart: always

volumes:
  caddy_data:
```

Caddyfile:

```
mg-firma-legal.com {
    reverse_proxy open-webui:8080
}
```

### 4. SSL con Nginx + Certbot

```bash
sudo apt install nginx certbot python3-certbot-nginx -y

# Configurar Nginx
sudo nano /etc/nginx/sites-available/mg-firma-legal
```

Configuración Nginx:

```nginx
server {
    listen 80;
    server_name mg-firma-legal.com;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
# Obtener SSL
sudo certbot --nginx -d mg-firma-legal.com

# Auto-renovación
sudo certbot renew --dry-run
```

---

## Mantenimiento

### Backup de Datos

```bash
# Docker: guardar volúmenes
docker run --rm \
  -v mg-politica-web_webui_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/webui-backup.tar.gz /data

# Base de datos SQLite
cp /ruta/a/backend/data/webui.db /backup/webui-$(date +%Y%m%d).db
```

### Restaurar Backup

```bash
# Docker
docker run --rm \
  -v mg-politica-web_webui_data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/webui-backup.tar.gz -C /data
```

### Actualizar Aplicación

```bash
# Docker
cd /ruta/a/mg-politica-web
git pull
npm run build
docker compose down
docker compose up -d --build

# Systemd
sudo systemctl stop mg-firma-legal
git pull
npm run build
sudo systemctl start mg-firma-legal
```

### Logs y Monitoreo

```bash
# Docker logs
docker compose logs -f open-webui
docker compose logs -f ollama

# Systemd logs
journalctl -u mg-firma-legal -f

# Verificar estado
sudo systemctl status mg-firma-legal
docker compose ps
```

### Limpieza de Espacio

```bash
# Limpiar Docker
docker system prune -a
docker volume prune

# Limpiar logs antiguos
sudo journalctl --vacuum-time=7d
```

---

## Solución de Problemas

### La aplicación no inicia

```bash
# Verificar logs
sudo journalctl -u mg-firma-legal -n 100
docker compose logs open-webui

# Verificar puerto
sudo lsof -i :8080
sudo netstat -tulpn | grep 8080
```

### Problemas de Base de Datos

```bash
# SQLite: verificar integridad
sqlite3 /ruta/a/webui.db "PRAGMA integrity_check;"

# PostgreSQL: ver conexiones
psql -U usuario -d mg_firma_legal -c "SELECT count(*) FROM pg_stat_activity;"
```

### Errores de Memoria

```bash
# Verificar uso de memoria
free -h
docker stats
htop

# Ajustar límites de Ollama
# Editar docker-compose.yml y agregar:
# environment:
#   - OLLAMA_MAX_LOADED_MODELS=2
```

---

## Recursos Adicionales

- **Repositorio Oficial**: https://github.com/CodingSoft/mg-politica-web
- **Documentación**: https://docs.openwebui.com
- **Soporte**: soporte@mg-firma-legal.com

---

## Checklist de Producción

- [ ] Generar `WEBUI_SECRET_KEY` única
- [ ] Configurar firewall (UFW)
- [ ] Instalar SSL (Caddy o Nginx)
- [ ] Configurar backup automático
- [ ] Establecer `ENABLE_SIGNUP=false` (si no es público)
- [ ] Configurar `DEFAULT_USER_ROLE=user`
- [ ] Verificar logs después del despliegue
- [ ] Probar conexión a Ollama/OpenAI
- [ ] Verificar que el logo y enlaces apunten a `CodingSoft/mg-politica-web`
- [ ] Configurar monitoreo (opcional)
- [ ] Documentar credenciales en lugar seguro

---

**Última actualización**: Mayo 2026  
**Versión**: 1.0.0
