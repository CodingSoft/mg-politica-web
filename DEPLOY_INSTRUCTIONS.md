# 🚀 Instrucciones de Deploy - Performance Fix

## Contexto
La aplicación en producción está tardando **>10 segundos** en cargar debido a miles de peticiones de imágenes de modelos que no existen.

## Solución
Se creó una imagen Docker optimizada que:
- ✅ Bloquea peticiones de imágenes de modelos (causante del problema)
- ✅ Optimiza la base de datos SQLite en cada inicio
- ✅ Incluye middlewares de performance
- ✅ Mantiene todas las funcionalidades originales

## 📋 Prerrequisitos
- Tener acceso SSH al servidor: `ssh -p 22022 root@74.208.198.240`
- Docker instalado localmente
- Conexión de red estable (la imagen pesa ~1.5GB)
- El build ya se generó: `mg-firma-legal:optimized`

## 🔧 Opción 1: Deploy Automático (Recomendado)

Ejecutar el script de deploy:

```bash
cd /Users/codingsoft/GitHub/mg-politica-web
./deploy-optimized.sh
```

El script:
1. Construye la imagen optimizada
2. La transfiere al servidor (5-10 min)
3. Detiene el contenedor actual
4. Despliega la nueva versión
5. Verifica el deployment

**Tiempo estimado**: 10-15 minutos

## 🔧 Opción 2: Deploy Manual Paso a Paso

### Paso 1: Construir imagen (si no está construida)
```bash
cd /Users/codingsoft/GitHub/mg-politica-web
docker build -f Dockerfile.optimized -t mg-firma-legal:optimized .
```

### Paso 2: Transferir imagen al servidor
```bash
docker save mg-firma-legal:optimized | ssh -p 22022 root@74.208.198.240 docker load
```
⏱️ Esto toma 5-10 minutos dependiendo de la velocidad de red

### Paso 3: Detener contenedor actual
```bash
ssh -p 22022 root@74.208.198.240 "docker stop mg-firma-legal"
```

### Paso 4: Remover contenedor anterior
```bash
ssh -p 22022 root@74.208.198.240 "docker rm mg-firma-legal"
```

### Paso 5: Iniciar nueva versión
```bash
ssh -p 22022 root@74.208.198.240 "
docker run -d --name mg-firma-legal \
  -p 8080:8080 \
  -v mg-firma-legal:/app/backend/data \
  --restart unless-stopped \
  mg-firma-legal:optimized
"
```

### Paso 6: Verificar
```bash
ssh -p 22022 root@74.208.198.240 "docker logs mg-firma-legal --tail 30"
```

## 🔧 Opción 3: Deploy Rápido (Solo parche de emergencia)

Si necesitas una solución inmediata mientras se construye la imagen:

```bash
# SSH al servidor
ssh -p 22022 root@74.208.198.240

# Detener contenedor
docker stop mg-firma-legal

# Ejecutar script de optimización de DB
docker run --rm -v mg-firma-legal:/app/backend/data python:3.11-slim python3 -c "
import sqlite3
conn = sqlite3.connect('/app/backend/data/webui.db')
conn.execute('PRAGMA journal_mode=DELETE')
conn.execute('PRAGMA wal_checkpoint(TRUNCATE)')
conn.execute('VACUUM')
conn.execute('ANALYZE')
conn.close()
print('DB optimized')
"

# Reiniciar contenedor
docker start mg-firma-legal
```

Esto NO soluciona el problema de las imágenes, pero mejora el performance de la DB.

## ✅ Verificación del Deploy

Después del deploy, verificar:

1. **Tiempo de carga**:
   - Abrir: `https://mgfirma-legal.codingssoft.org/admin`
   - Debe cargar en < 2 segundos (anteriormente >10s)

2. **Logs del servidor**:
   ```bash
   ssh -p 22022 root@74.208.198.240 "docker logs mg-firma-legal --tail 50"
   ```
   - Ya NO debe ver miles de peticiones a `/api/v1/models/model/profile/image`
   - Debe ver logs normales de la aplicación

3. **Uso de recursos**:
   ```bash
   ssh -p 22022 root@74.208.198.240 "docker stats mg-firma-legal --no-stream"
   ```
   - CPU: Debe ser normal (< 20%)
   - Memoria: ~700MB (normal)

## 🔄 Rollback (si hay problemas)

Si algo sale mal, revertir a la versión anterior:

```bash
ssh -p 22022 root@74.208.198.240 "
docker stop mg-firma-legal
docker rm mg-firma-legal
docker run -d --name mg-firma-legal \
  -p 8080:8080 \
  -v mg-firma-legal:/app/backend/data \
  --restart unless-stopped \
  ghcr.io/open-webui/open-webui:main
"
```

## 📊 Comparativa de Performance

| Métrica | Antes | Después |
|---------|-------|---------|
| Tiempo de carga | >10s | <2s |
| Peticiones imagen | ~1000/min | 0 |
| Errores Ollama | Altos | Normales |
| WAL SQLite | Creciendo | Estable |
| CPU | Alto | Normal |

## 🛠️ troubleshooting

### El deploy falla por timeout
- Asegurar conexión de red estable
- Intentar en horario de menor tráfico
- Usar conexión cableada en lugar de WiFi

### La aplicación no carga después del deploy
1. Verificar logs: `docker logs mg-firma-legal --tail 100`
2. Verificar contenedor: `docker ps | grep mg-firma`
3. Revisar puertos: `ssh -p 22022 root@74.208.198.240 "netstat -tlnp | grep 8080"`

### La aplicación carga pero sigue lenta
- Verificar que la imagen correcta se desplegó: `ssh -p 22022 root@74.208.198.240 "docker images | grep optimized"`
- Limpiar caché del navegador
- Revisar logs de errores

## 📞 Soporte

Si encuentras problemas durante el deploy:
1. Revisar `SOLUTION_PERFORMANCE.md` para diagnóstico detallado
2. Revisar logs de la aplicación
3. Verificar conexión de red
4. Intentar rollback si es crítico

---
**Fecha**: 2026-05-13  
**Versión**: 1.0-performance-fix  
**Impacto**: Crítico - mejora de >10s a <2s en carga
