# MG-Firma Legal - Custom Docker Image
# Based on Open WebUI

FROM ghcr.io/open-webui/open-webui:main

# Copy custom static files (logo, favicon, etc.) to /app/build/static/
COPY build/static/ /app/build/static/

# Copy backend static files (logo, favicon)
COPY backend/open_webui/static/ /app/backend/open_webui/static/

# Set environment variables
ENV WEBUI_NAME="MG-Firma Legal"
ENV ENABLE_SIGNUP=false
ENV DEFAULT_USER_ROLE=user
ENV ENABLE_COMMUNITY_SHARING=false
ENV ENABLE_RAG_WEB_SEARCH=true

# Expose port
EXPOSE 8080

# Run the application
CMD ["bash", "start.sh"]