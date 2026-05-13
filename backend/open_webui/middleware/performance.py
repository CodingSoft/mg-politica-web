"""
Performance middleware for MG-Firma Legal
Blocks unnecessary requests and adds caching headers
"""
from fastapi import Request, Response
from fastapi.responses import RedirectResponse
import time

# Cache for blocking repeated model image requests
_model_image_cache = {}

async def performance_middleware(request: Request, call_next):
    """Optimize performance by blocking unnecessary model image requests"""
    path = request.url.path
    
    # Block model profile image requests that cause cascading failures
    if '/api/v1/models/model/profile/image' in path:
        # Return empty response instead of redirect
        return Response(content='', status_code=200, media_type='image/png')
    
    # Add cache headers to version check to reduce polling
    response = await call_next(request)
    
    # Add performance headers
    if path.endswith(('.js', '.css', '.json')):
        response.headers['Cache-Control'] = 'public, max-age=300'  # 5 minutes
    
    return response
