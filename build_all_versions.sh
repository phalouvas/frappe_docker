#!/bin/bash

set -e

# Release version - update this for new releases
RELEASE_VERSION="1.0"

echo "=========================================="
echo "Building ERPNext Multi-Version Images"
echo "Release Version: $RELEASE_VERSION"
echo "=========================================="

# Function to build, tag, and push image
build_and_push() {
    local version=$1
    local json_file=$2
    local containerfile=$3
    local frappe_branch=$4
    local python_version=$5
    local node_version=$6
    
    echo ""
    echo "Building ERPNext v$version..."
    
    if [ ! -f "$json_file" ]; then
        echo "⚠ Skipping v$version - $(basename $json_file) not found"
        return
    fi
    
    export APPS_JSON_BASE64=$(base64 -w 0 "$json_file")
    
    # Build image with release tag (e.g., 14-1.0)
    docker build --no-cache \
        --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
        --build-arg=FRAPPE_BRANCH=$frappe_branch \
        --build-arg=PYTHON_VERSION=$python_version \
        --build-arg=NODE_VERSION=$node_version \
        --build-arg=APPS_JSON_BASE64=$APPS_JSON_BASE64 \
        --tag=phalouvas/erpnext-worker:$version-$RELEASE_VERSION \
        --file=$containerfile .
    
    echo "✓ v$version build complete"
    
    # Tag as latest for this version (e.g., 15-latest)
    docker tag phalouvas/erpnext-worker:$version-$RELEASE_VERSION phalouvas/erpnext-worker:$version-latest
    echo "✓ Tagged as: phalouvas/erpnext-worker:$version-latest"
    
    # Push both tags
    echo "Pushing images..."
    docker push phalouvas/erpnext-worker:$version-$RELEASE_VERSION
    docker push phalouvas/erpnext-worker:$version-latest
    echo "✓ v$version pushed successfully"
}

# Build v14
build_and_push 14 \
    ~/frappe_docker/images/custom/v14.json \
    images/custom/Containerfile \
    version-14 \
    3.10.13 \
    16.20.2

# Build v15
build_and_push 15 \
    ~/frappe_docker/images/azure/v15.json \
    images/azure/Containerfile \
    version-15 \
    3.11.6 \
    20.19.2

# Build v16
build_and_push 16 \
    ~/frappe_docker/images/azure/v16.json \
    images/azure/Containerfile \
    version-16 \
    3.12.8 \
    22.12.0

echo ""
echo "=========================================="
echo "Build & Push Summary:"
echo "=========================================="
docker images | grep "phalouvas/erpnext-worker"

echo ""
echo "All builds and pushes complete!"
echo "Release Version: $RELEASE_VERSION"
