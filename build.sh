#!/bin/bash

set -e

# Release version - update this for new releases
RELEASE_VERSION="1.8"
BUILD_MANIFEST=".build_manifest"

echo "=========================================="
echo "Building ERPNext Multi-Version Images"
echo "Release Version: $RELEASE_VERSION"
echo "=========================================="

# Function to check if image was already built
image_exists() {
    local version=$1
    docker image inspect "phalouvas/erpnext-worker:$version-$RELEASE_VERSION" &>/dev/null
    return $?
}

# Function to get last build timestamp for a version
get_last_build() {
    local version=$1
    if [ -f "$BUILD_MANIFEST" ]; then
        grep "^v$version:" "$BUILD_MANIFEST" 2>/dev/null | cut -d':' -f2
    fi
}

# Function to record build in manifest
record_build() {
    local version=$1
    local timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    # Remove old entry if exists
    sed -i "/^v$version:/d" "$BUILD_MANIFEST" 2>/dev/null || true
    # Add new entry
    echo "v$version:$timestamp:$RELEASE_VERSION" >> "$BUILD_MANIFEST"
}

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
    
    # Check if already built
    if image_exists $version; then
        local last_build=$(get_last_build $version)
        echo "⚠ Image already exists for v$version with release $RELEASE_VERSION"
        if [ -n "$last_build" ]; then
            echo "  Last built: $last_build"
        fi
        read -p "  Rebuild? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "✓ Skipped v$version"
            return
        fi
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
    
    # Record build
    record_build $version
}

# Determine which versions to build
VERSIONS_TO_BUILD=()

if [ $# -eq 0 ]; then
    # No arguments - build all versions
    VERSIONS_TO_BUILD=(14 15 16)
else
    # Build specific versions passed as arguments
    VERSIONS_TO_BUILD=("$@")
fi

echo "Versions to build: ${VERSIONS_TO_BUILD[*]}"
echo ""

# Build requested versions
for version in "${VERSIONS_TO_BUILD[@]}"; do
    case $version in
        14)
            build_and_push 14 \
                ~/frappe_docker/images/azure/v14.json \
                images/azure/Containerfile \
                version-14 \
                3.10.13 \
                16.20.2
            ;;
        15)
            build_and_push 15 \
                ~/frappe_docker/images/azure/v15.json \
                images/azure/Containerfile \
                version-15 \
                3.11.6 \
                20.19.2
            ;;
        16)
            build_and_push 16 \
                ~/frappe_docker/images/azure/v16.json \
                images/azure/Containerfile \
                version-16 \
                3.14.2 \
                24.2.0
            ;;
        *)
            echo "⚠ Unknown version: $version (use 14, 15, or 16)"
            ;;
    esac
done

echo ""
echo "=========================================="
echo "Build & Push Summary:"
echo "=========================================="
docker images | grep "phalouvas/erpnext-worker" || echo "No images found"

if [ -f "$BUILD_MANIFEST" ]; then
    echo ""
    echo "Build History (.build_manifest):"
    cat "$BUILD_MANIFEST"
fi

echo ""
echo "All builds and pushes complete!"
echo "Release Version: $RELEASE_VERSION"
echo ""
echo "Usage examples:"
echo "  ./build.sh          # Build all versions (14, 15, 16)"
echo "  ./build.sh 16       # Build only v16"
echo "  ./build.sh 15 16    # Build only v15 and v16"
