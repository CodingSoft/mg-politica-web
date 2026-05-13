#!/bin/bash
# Deploy script for MG-Firma Legal Optimized version
# Run this script to deploy the performance-fixed version to production

set -e

echo "========================================="
echo "  MG-Firma Legal - Deploy Optimized"
echo "  Performance Fix for >10s loading"
echo "========================================="
echo ""

# Configuration
SERVER="74.208.198.240"
PORT="22022"
IMAGE_NAME="mg-firma-legal:optimized"
CONTAINER_NAME="mg-firma-legal"

echo "📦 Step 1: Building optimized Docker image..."
docker build -f Dockerfile.optimized -t $IMAGE_NAME . || {
    echo "❌ Build failed. Check Dockerfile.optimized"
    exit 1
}
echo "✓ Build complete"
echo ""

echo "📤 Step 2: Transferring image to production server..."
echo "   This may take 5-10 minutes depending on network speed..."
docker save $IMAGE_NAME | ssh -p $PORT root@$SERVER "docker load" || {
    echo "❌ Transfer failed. Check network connection"
    exit 1
}
echo "✓ Image transferred"
echo ""

echo "🚀 Step 3: Deploying to production..."
ssh -p $PORT root@$SERVER "
    # Stop current container
    echo 'Stopping current container...'
    docker stop $CONTAINER_NAME || true
    docker rm $CONTAINER_NAME || true
    
    # Run new container
    echo 'Starting optimized container...'
    docker run -d --name $CONTAINER_NAME \\
        -p 8080:8080 \\
        -v mg-firma-legal:/app/backend/data \\
        --restart unless-stopped \\
        $IMAGE_NAME
    
    # Wait for startup
    sleep 5
    
    # Check status
    docker ps | grep $CONTAINER_NAME
" || {
    echo "❌ Deploy failed"
    exit 1
}
echo "✓ Deploy complete"
echo ""

echo "🔍 Step 4: Verifying deployment..."
sleep 10
ssh -p $PORT root@$SERVER "docker logs $CONTAINER_NAME --tail 20"
echo ""

echo "========================================="
echo "  ✅ Deploy Successful!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Open: https://mgfirma-legal.codingssoft.org/admin"
echo "2. Verify loading time is < 2 seconds"
echo "3. Check logs: ssh -p 22022 root@74.208.198.240 docker logs mg-firma-legal --tail 50"
echo ""
echo "Rollback (if needed):"
echo "  ssh -p 22022 root@74.208.198.240 'docker stop mg-firma-legal && docker rm mg-firma-legal && docker run -d --name mg-firma-legal -p 8080:8080 -v mg-firma-legal:/app/backend/data --restart unless-stopped ghcr.io/open-webui/open-webui:main'"
echo ""
