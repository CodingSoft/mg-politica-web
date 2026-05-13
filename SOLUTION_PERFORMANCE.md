# Solución Completa - Performance Issue (>10s carga)

## 🔍 Diagnóstico Final

El problema NO era solo la base de datos SQLite. El problema principal es que el **frontend está solicitando miles de imágenes de modelos** que no existen, causando:

1. **Cascada de peticiones HTTP**: Cada modelo solicita su imagen → redirect 302 → más peticiones
2. **Saturación del servidor**: Cientos de peticiones por segundo a `/api/v1/models/model/profile/image`
3. **Errores de Ollama**: Al no haber Ollama configurado, genera reintentos que colapsan el servidor

### Evidencia de Logs
```
GET /api/v1/models/model/profile/image?id=meta/llama-3.1-8b-instruct 302
GET /api/v1/models/model/profile/image?id=gpt-5.4-mini 302  
GET /api/v1/models/model/profile/image?id=google/gemma-2b 302
ERROR | open_webui.routers.ollama:send_get_request:121 - Connection error:
```

## ✅ Soluciones Disponibles

### Opción 1: Rebuild del Frontend (Recomendado)

El código local ya tiene el fix (`DISABLE_MODEL_PROFILE_IMAGES = true`).

```bash
# 1. Build del frontend
cd /Users/codingsoft/GitHub/mg-politica-web
npm run build

# 2. Rebuild Docker image
docker build -t mg-firma-legal:optimized .

# 3. Deploy a producción
docker save mg-firma-legal:optimized | ssh -p 22022 root@74.208.198.240 docker load

# 4. Recrear contenedor
ssh -p 22022 root@74.208.198.240 "
  docker stop mg-firma-legal
  docker rm mg-firma-legal
  docker run -d --name mg-firma-legal \
    -p 8080:8080 \
    -v mg-firma-legal:/app/backend/data \
    mg-firma-legal:optimized
"
```

### Opción 2: parche Backend (Rápido)

Crear imagen personalizada con middleware:

```dockerfile
FROM ghcr.io/open-webui/open-webui:main

# Add performance middleware
COPY backend/open_webui/middleware /app/backend/open_webui/middleware/

# Patch main.py to include middleware
RUN echo "from open_webui.middleware.model_image_blocker import ModelImageBlockerMiddleware" >> /app/backend/open_webui/main.py && \
    echo "app.add_middleware(ModelImageBlockerMiddleware)" >> /app/backend/open_webui/main.py

COPY build/static/ /app/build/static/
COPY backend/open_webui/static/ /app/backend/open_webui/static/

ENV WEBUI_NAME="MG-Firma Legal"
EXPOSE 8080
CMD ["bash", "start.sh"]
```

### Opción 3: parche Manual en Producción (Inmediato)

```bash
ssh -p 22022 root@74.208.198.240

# Detener
docker stop mg-firma-legal

# Crear script de bloqueo
docker run --rm -v mg-firma-legal:/data python:3.11-slim python3 << 'PY'
import re
content = open('/data/open_webui/routers/models.py').read()

# Find function
start = content.find("@router.get('/model/profile/image')")
if start == -1:
    print('Not found')
    exit(1)

# Find end (next function after 10 lines)
end = content.find('@router.get', start + 500)
if end == -1:
    end = start + 1500

# Replace
new_func = '''@router.get('/model/profile/image')
async def get_model_profile_image(
    request: Request,
    id: str,
    user=Depends(get_verified_user),
    db: AsyncSession = Depends(get_async_session),
):
    # PERFORMANCE FIX: Return transparent PNG
    return Response(
        content=b'\\x89PNG\\r\\n\\x1a\\n\\x00\\x00\\x00\\rIHDR\\x00\\x00\\x00\\x01\\x00\\x00\\x00\\x01\\x08\\x06\\x00\\x00\\x00\\x1f\\x15\\xc4\\x89\\x00\\x00\\x00\\nIDATx\\x9cc\\x00\\x01\\x00\\x00\\x05\\x00\\x01\\r\\n-\\xb4\\x00\\x00\\x00\\x00IEND\\xaeB`\\x82',
        media_type='image/png',
        headers={'Cache-Control': 'public, max-age=86400'}
    )
'''

content = content[:start] + new_func + content[end:]
open('/data/open_webui/routers/models.py', 'w').write(content)
print('✓ Patched')
PY

# Reiniciar
docker start mg-firma-legal
```

## 📊 Resultados Esperados

| Métrica | Antes | Después |
|---------|-------|---------|
| Tiempo de carga | >10s | <2s |
| Peticiones imagen | Miles | 0 |
| Errores Ollama | Muchos | Normales |
| Uso CPU | Alto | Normal |
| WAL SQLite | Creciendo | Estable |

## 🔧 Mantenimiento Continuo

1. **Optimizar DB cada 6 horas**:
```bash
0 */6 * * * docker exec mg-firma-legal python3 /app/backend/open_webui/db_optimize.py
```

2. **Monitorear logs**:
```bash
docker logs mg-firma-legal | grep -i "error\|slow"
```

3. **Verificar performance**:
```bash
curl -w '%{time_total}s\n' -o /dev/null -s http://localhost:8080/api/config
# Debería ser < 0.1s
```

## 📝 Archivos Creados

- `src/lib/constants.ts` - Constante DISABLE_MODEL_PROFILE_IMAGES
- `backend/open_webui/db_optimize.py` - Optimización DB
- `backend/open_webui/start_optimized.sh` - Inicio optimizado
- `backend/open_webui/middleware/` - Middlewares de performance

---
**Fecha**: 2026-05-13  
**Estado**: Fix local listo, pendiente deploy a producción  
**Impacto**: Crítico - aplicación inutilizable sin fix
