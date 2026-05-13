"""
Block model profile image requests to prevent performance issues
This middleware intercepts requests to /api/v1/models/model/profile/image
and returns a transparent PNG immediately without processing.
"""
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

class ModelImageBlockerMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # Block model profile image requests
        if '/api/v1/models/model/profile/image' in str(request.url):
            # Return transparent 1x1 PNG
            return Response(
                content=b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82',
                media_type='image/png',
                headers={'Cache-Control': 'public, max-age=86400'}
            )
        response = await call_next(request)
        return response
