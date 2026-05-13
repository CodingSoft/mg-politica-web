#!/bin/bash

# MG-Firma Legal - Build & Push Docker Image
# Usage: ./build-docker.sh

set -e

IMAGE_NAME="ghcr.io/codingsoft/mg-firma-legal"
TAG="main"

echo "🚀 Building MG-Firma Legal Docker Image..."

# 1. Install dependencies and build frontend
echo "📦 Building frontend..."
npm install --force
npm run build

# 2. Build Docker image
echo "🐳 Building Docker image..."
docker build -t ${IMAGE_NAME}:${TAG} .

# 3. Login to GitHub Container Registry
echo "🔐 Logging into GitHub..."
echo "$GH_TOKEN" | docker login ghcr.io -u CodingSoft --password-stdin

# 4. Push to registry
echo "📤 Pushing to GitHub Container Registry..."
docker push ${IMAGE_NAME}:${TAG}

echo "✅ Done! Image available at: ${IMAGE_NAME}:${TAG}"
echo ""
echo "To update production, run on VPS:"
echo "  docker compose -f /opt/mg-firma-legal/docker-compose.yml pull"
echo "  docker compose -f /opt/mg-firma-legal/docker-compose.yml up -d"