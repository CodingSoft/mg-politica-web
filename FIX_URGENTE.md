# 🚨 FIX URGENTE: Performance - Carga > 10 segundos

## Problema
La aplicación está saturada con **miles de peticiones de imágenes de modelos** que causan:
- Carga > 10 segundos
- Múltiples errores de conexión
- WAL de SQLite creciendo sin control

## Solución Rápida - Aplicar en Producción

### Paso 1: Copiar middleware al servidor

```bash
# Crear archivo de middleware
ssh -p 22022 root@74.208.198.240 "cat > /tmp/middleware.py << 'MIDDLEWARE'
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response

class ModelImageBlockerMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        if '/api/v1/models/model/profile/image' in str(request.url):
            return Response(
                content=b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82',
                media_type='image/png',
                headers={'Cache-Control': 'public, max-age=86400'}
            )
        return await call_next(request)
MIDDLEWARE"
```

### Paso 2: Insertar en main.py

```bash
ssh -p 22022 root@74.208.198.240 "
docker exec mg-firma-legal sh -c '
# Backup
cp /app/backend/open_webui/main.py /app/backend/main.py.backup

# Add import
grep -q \"ModelImageBlockerMiddleware\" /app/backend/open_webui/main.py || \
  sed -i \"/from open_webui.utils.middleware import/a from open_webui.middleware.model_image_blocker import ModelImageBlockerMiddleware\" \
  /app/backend/open_webui/main.py

# Add middleware after RedirectMiddleware
sed -i \"/app.add_middleware(RedirectMiddleware)/a app.add_middleware(ModelImageBlockerMiddleware)\" \
/app/backend/open_webui/main.py
'
"
```

### Paso 3: Reiniciar

```bash
ssh -p 22022 root@74.208.198.240 "docker restart mg-firma-legal"
```

## Verificación

1. Abrir: `mgfirma-legal.codingssoft.org/admin`
2. Debería cargar en < 2 segundos
3. Revisar logs: `docker logs mg-firma-legal | grep -i "model/profile"`

## Rollback (si hay problemas)

```bash
ssh -p 22022 root@74.208.198.240 "
docker exec mg-firma-legal sh -c '
cp /app/backend/main.py.backup /app/backend/open_webui/main.py
'
docker restart mg-firma-legal
"
```

## Resultado Esperado

| Métrica | Antes | Después |
|---------|-------|---------|
| Carga inicial | >10s | <2s |
| Peticiones modelo | Miles | 0 |
| Uso CPU | Alto | Normal |
| WAL SQLite | Creciendo | Estable |
