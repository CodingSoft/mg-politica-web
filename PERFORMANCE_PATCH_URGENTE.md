# 🚨 URGENTE: Performance Patch para Carga Lenta

## Problema Detectado
La aplicación está tardando **más de 10 segundos** en cargar debido a que el servidor está **saturado con miles de peticiones de imágenes de modelos** que no existen.

### Evidencia de Logs
````
GET /api/v1/models/model/profile/image?id=meta/llama-3.1-8b-instruct HTTP/1.1" 302
GET /api/v1/models/model/profile/image?id=gpt-5.4-mini HTTP/1.1" 302
GET /api/v1/models/model/profile/image?id=google/gemma-2b HTTP/1.1" 302
... (cientos más)
ERROR | open_webui.routers.ollama:send_get_request:121 - Connection error:
````

Cada modelo intenta cargar su imagen → redirect 302 → más peticiones → colapso del servidor.

## Solución Inmediata (5 minutos)

### Opción A: Deshabilitar imágenes de modelos (Recomendado)

Ejecutar en producción:
```bash
# SSH al servidor
ssh -p 22022 root@74.208.198.240

# Detener contenedor
docker stop mg-firma-legal

# Crear backup
docker run --rm -v mg-firma-legal:/app/backend/data alpine cp /app/backend/open_webui/routers/models.py /app/backend/data/models.py.backup

# Editar archivo y reemplazar la función
docker run --rm -v mg-firma-legal:/app/backend/open_webui/routers alpine sh -c '
cat > /tmp/patch.py << '\''PYEOF'\''
import re
content = open("/app/backend/open_webui/routers/models.py").read()

# Find the function
pattern = r"@router\.get\('/model/profile/image'\)\\s+async def get_model_profile_image\(.*?\):(.+?)(?=@router\.get|@router\.post|def \w+\(|$)"
match = re.search(pattern, content, re.DOTALL | re.MULTILINE)

if match:
    old_func = match.group(0)
    new_func = '''@router.get('/model/profile/image')
async def get_model_profile_image(
    request: Request,
    id: str,
    user=Depends(get_verified_user),
    db: AsyncSession = Depends(get_async_session),
):
    # PERFORMANCE FIX: Return transparent PNG immediately
    # Prevents cascading HTTP requests for non-existent model images
    return Response(
        content=b'\x89PNG\x0d\x0a\x1a\x0a\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82',
        media_type='image/png',
        headers={'Cache-Control': 'public, max-age=86400'}
    )'''
    
    content = content.replace(old_func, new_func)
    open("/app/backend/open_webui/routers/models.py", "w").write(content)
    print("Patched successfully")
else:
    print("Pattern not found")
PYEOF
python3 /tmp/patch.py
'

# Reiniciar contenedor
docker start mg-firma-legal
```

### Opción B: parche manual rápido

1. SSH al servidor: `ssh -p 22022 root@74.208.198.240`
2. Detener: `docker stop mg-firma-legal`
3. Editar: `docker run --rm -it -v mg-firma-legal:/app/backend/data alpine vi /app/backend/open_webui/routers/models.py`
4. Buscar línea 465: `@router.get('/model/profile/image')`
5. Reemplazar TODO el contenido de la función con:
```python
@router.get('/model/profile/image')
async def get_model_profile_image(
    request: Request,
    id: str,
    user=Depends(get_verified_user),
    db: AsyncSession = Depends(get_async_session),
):
    # PERFORMANCE FIX: Return transparent PNG immediately
    return Response(
        content=b'\x89PNG\x0d\x0a\x1a\x0a\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82',
        media_type='image/png',
        headers={'Cache-Control': 'public, max-age=86400'}
    )
```
6. Guardar y salir (`:wq`)
7. Reiniciar: `docker start mg-firma-legal`

## Verificación

Después del parche, la aplicación debería cargar en < 2 segundos.

Verificar en navegador: `mgfirma-legal.codingssoft.org/admin`

## Solución Frontend (Adicional)

También se puede parchear el frontend para que no solicite estas imágenes:

```bash
# En el código local, editar src/lib/constants.ts
# Agregar: export const DISABLE_MODEL_IMAGES = true
```

## Resultado Esperado

- **Antes**: >10 segundos de carga
- **Después**: <2 segundos de carga
- **Mejora**: 5-10x más rápido

---
**Fecha**: 2026-05-13  
**Prioridad**: CRÍTICA  
**Tiempo estimado**: 5-10 minutos
