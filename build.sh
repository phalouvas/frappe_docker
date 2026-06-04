#!/bin/bash

set -e

# Release version - update this for new releases
RELEASE_VERSION="1.37"
BUILD_MANIFEST=".build_manifest"
APP_CACHE_BUST=0

echo "=========================================="
echo "Building ERPNext Multi-Version Images"
echo "Release Version: $RELEASE_VERSION"
echo "=========================================="

print_usage() {
    echo "Usage: ./build.sh [OPTIONS] [VERSIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help                 Show this help and exit"
    echo "  --no-cache                 Disable Docker build cache"
    echo "  --no-push                  Build only; skip Docker push"
    echo "  --refresh-apps             Bust only app install layer cache"
    echo "  --refresh-pins             Refresh pin values from GitHub"
    echo "  --check-pins               Validate refs are pinned (no build)"
    echo "  --allow-unpinned-apps      Override pin enforcement"
    echo ""
    echo "Versions: 14 15 16 (default: all)"
    echo ""
    echo "Examples:"
    echo "  ./build.sh"
    echo "  ./build.sh 16"
    echo "  ./build.sh --refresh-pins --check-pins 16"
    echo "  ./build.sh --no-push 15 16"
}

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

is_pinned_ref() {
    local ref="$1"

    # Commit SHA (short/full)
    if [[ "$ref" =~ ^[0-9a-fA-F]{7,40}$ ]]; then
        return 0
    fi

    # Common immutable tag patterns (v1.2.3, 1.2.3, v16.0.0-rc1)
    if [[ "$ref" =~ ^v?[0-9]+(\.[0-9]+){1,3}([.-][A-Za-z0-9._-]+)?$ ]]; then
        return 0
    fi

    # Explicit tag refs
    if [[ "$ref" =~ ^refs/tags/ ]]; then
        return 0
    fi

    return 1
}

validate_apps_json_pins() {
    local json_file="$1"
    local version="$2"
    local found_unpinned=0

    while IFS=$'\t' read -r line_no app_url branch_ref pin_ref; do
        local check_field="branch"
        local effective_ref="$branch_ref"

        # If pin is present, use it as the immutable build ref and keep branch as indicator.
        if [ -n "$pin_ref" ]; then
            check_field="pin"
            effective_ref="$pin_ref"
        fi

        if [ -z "$branch_ref" ]; then
            echo "✗ Missing branch in $json_file for v$version (line $line_no, url=$app_url)"
            found_unpinned=1
            continue
        fi

        if ! is_pinned_ref "$effective_ref"; then
            echo "✗ Unpinned app ref in $json_file for v$version (line $line_no, url=$app_url): $check_field=$effective_ref"
            found_unpinned=1
        fi
    done < <(awk '
        BEGIN {
            in_obj=0
            start=0
            url=""
            branch=""
            pin=""
        }

        /^[[:space:]]*\{[[:space:]]*$/ {
            in_obj=1
            start=NR
            url=""
            branch=""
            pin=""
        }

        {
            if (in_obj == 1) {
                if (match($0, /"url"[[:space:]]*:[[:space:]]*"([^"]+)"/, m)) {
                    url=m[1]
                }
                if (match($0, /"branch"[[:space:]]*:[[:space:]]*"([^"]+)"/, m)) {
                    branch=m[1]
                }
                if (match($0, /"pin"[[:space:]]*:[[:space:]]*"([^"]+)"/, m)) {
                    pin=m[1]
                }
            }
        }

        /^[[:space:]]*\}[[:space:]]*,?[[:space:]]*$/ {
            if (in_obj == 1 && (url != "" || branch != "" || pin != "")) {
                printf "%s\t%s\t%s\t%s\n", start, url, branch, pin
            }
            in_obj=0
        }
    ' "$json_file")

    if [ "$found_unpinned" -eq 1 ]; then
        return 1
    fi

    return 0
}

generate_build_apps_json() {
    local input_json="$1"
    local output_json="$2"

    # Keep branch as policy metadata in source json, but use pin as build ref when present.
    awk '
        BEGIN {
            in_obj=0
            obj=""
        }

        /^[[:space:]]*\{[[:space:]]*$/ {
            in_obj=1
            obj=$0 ORS
            next
        }

        {
            if (in_obj == 1) {
                obj=obj $0 ORS

                if ($0 ~ /^[[:space:]]*\}[[:space:]]*,?[[:space:]]*$/) {
                    pin=""
                    if (match(obj, /"pin"[[:space:]]*:[[:space:]]*"([^"]+)"/, m)) {
                        pin=m[1]
                    }

                    # bench init clones apps with --branch <ref> --depth 1.
                    # commit SHAs are not valid branch refs for shallow clone.
                    # Use pin only when it looks like a tag-like ref.
                    if (pin != "") {
                        is_commit = (pin ~ /^[0-9a-fA-F]+$/ && length(pin) >= 7 && length(pin) <= 40)
                        if (!is_commit) {
                            gsub(/"branch"[[:space:]]*:[[:space:]]*"[^"]+"/, "\"branch\": \"" pin "\"", obj)
                        }
                    }

                    printf "%s", obj
                    obj=""
                    in_obj=0
                }

                next
            }
        }

        {
            print
        }
    ' "$input_json" > "$output_json"
}

json_file_for_version() {
    local version="$1"

    case "$version" in
        14) echo "$HOME/frappe_docker/images/azure/v14.json" ;;
        15) echo "$HOME/frappe_docker/images/azure/v15.json" ;;
        16) echo "$HOME/frappe_docker/images/azure/v16.json" ;;
        *) return 1 ;;
    esac
}

resolve_pin_for_ref() {
    local url="$1"
    local branch="$2"
    local head_sha tag_candidates chosen_tag
    local all_tags

    head_sha=$(git ls-remote "$url" "refs/heads/$branch" | awk '{print $1}')
    if [ -z "$head_sha" ]; then
        # Fallback when an indicator branch no longer exists remotely.
        all_tags=$(git ls-remote --tags "$url" | awk '
            $2 ~ /^refs\/tags\// {
                name = $2
                sub(/^refs\/tags\//, "", name)
                sub(/\^\{\}$/, "", name)
                print name
            }
        ' | sort -u)

        if [ -z "$all_tags" ]; then
            return 1
        fi

        chosen_tag=$(echo "$all_tags" | sort -V | tail -n 1)
        echo "⚠ Branch $branch not found for $url; using latest tag $chosen_tag" >&2
        echo "$chosen_tag"
        return 0
    fi

    tag_candidates=$(git ls-remote --tags "$url" | awk -v h="$head_sha" '
        $1 == h && $2 ~ /^refs\/tags\// {
            name = $2
            sub(/^refs\/tags\//, "", name)
            sub(/\^\{\}$/, "", name)
            print name
        }
    ' | sort -u)

    if [ -n "$tag_candidates" ]; then
        chosen_tag=$(echo "$tag_candidates" | sort -V | tail -n 1)
        echo "$chosen_tag"
    else
        echo "$head_sha"
    fi
}

refresh_pins_in_json() {
    local json_file="$1"
    local version="$2"
    local tmp_out
    local -A pin_map

    while IFS=$'\t' read -r url branch; do
        if [ -z "$url" ] || [ -z "$branch" ]; then
            continue
        fi

        local resolved_pin
        if ! resolved_pin=$(resolve_pin_for_ref "$url" "$branch"); then
            echo "✗ Could not resolve HEAD for $url on branch $branch"
            return 1
        fi

        pin_map["$url|$branch"]="$resolved_pin"
        echo "  v$version: $url@$branch -> $resolved_pin"
    done < <(awk '
        match($0, /"url"[[:space:]]*:[[:space:]]*"([^"]+)"/, m) { url=m[1] }
        match($0, /"branch"[[:space:]]*:[[:space:]]*"([^"]+)"/, m) {
            branch=m[1]
            if (url != "" && branch != "") {
                printf "%s\t%s\n", url, branch
                url=""
            }
        }
    ' "$json_file")

    tmp_out=$(mktemp)
    local current_url=""

    while IFS= read -r line || [ -n "$line" ]; do
        if echo "$line" | grep -qE '"url"[[:space:]]*:[[:space:]]*"[^"]+"'; then
            current_url=$(echo "$line" | sed -E 's/.*"url"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
            echo "$line" >> "$tmp_out"
            continue
        fi

        # Always rewrite pin from resolved source of truth.
        if echo "$line" | grep -qE '"pin"[[:space:]]*:'; then
            continue
        fi

        if echo "$line" | grep -qE '"branch"[[:space:]]*:[[:space:]]*"[^"]+"'; then
            local indent
            local branch_ref
            indent=$(echo "$line" | sed -E 's/^([[:space:]]*).*/\1/')
            branch_ref=$(echo "$line" | sed -E 's/.*"branch"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
            local key="$current_url|$branch_ref"
            local resolved_pin="${pin_map[$key]}"

            if [ -z "$resolved_pin" ]; then
                echo "✗ Missing resolved pin for $current_url on branch $branch_ref"
                rm -f "$tmp_out"
                return 1
            fi

            local branch_line="${line%,}"
            echo "${branch_line}," >> "$tmp_out"
            echo "${indent}\"pin\": \"$resolved_pin\"" >> "$tmp_out"
            continue
        fi

        if [[ "$line" =~ ^[[:space:]]*\}[[:space:]]*,?[[:space:]]*$ ]]; then
            current_url=""
        fi

        echo "$line" >> "$tmp_out"
    done < "$json_file"

    mv "$tmp_out" "$json_file"
}

refresh_pins_for_versions() {
    local version
    local refresh_failed=false

    echo "Refreshing pins from remote refs (tag preferred, commit fallback)..."
    for version in "${VERSIONS_TO_BUILD[@]}"; do
        local json_file
        if ! json_file=$(json_file_for_version "$version"); then
            echo "⚠ Unknown version for pin refresh: $version"
            continue
        fi

        if [ ! -f "$json_file" ]; then
            echo "⚠ Skipping pin refresh for v$version - $(basename "$json_file") not found"
            continue
        fi

        echo "Refreshing v$version pins in $json_file"
        if ! refresh_pins_in_json "$json_file" "$version"; then
            echo "⚠ Pin refresh incomplete for v$version; leaving file unchanged"
            refresh_failed=true
        fi
    done

    if [ "$refresh_failed" = true ]; then
        echo "⚠ Some pin refresh operations failed"
    fi
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
    
    local build_json_file="$json_file"
    local generated_build_json=""

    if grep -q '"pin"[[:space:]]*:' "$json_file"; then
        generated_build_json=$(mktemp)
        generate_build_apps_json "$json_file" "$generated_build_json"
        build_json_file="$generated_build_json"
    fi

    local cache_bust_value="$APP_CACHE_BUST"
    cache_bust_value="${cache_bust_value}:$(sha256sum "$build_json_file" | awk '{print $1}')"
    export APPS_JSON_BASE64=$(base64 -w 0 "$build_json_file")
    
    # Build image with release tag (e.g., 14-1.0)
    docker build $CACHE_OPTION \
        --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
        --build-arg=FRAPPE_BRANCH=$frappe_branch \
        --build-arg=PYTHON_VERSION=$python_version \
        --build-arg=NODE_VERSION=$node_version \
        --build-arg=APPS_CACHE_BUST=$cache_bust_value \
        --build-arg=APPS_JSON_BASE64=$APPS_JSON_BASE64 \
        --tag=phalouvas/erpnext-worker:$version-$RELEASE_VERSION \
        --file=$containerfile .

    if [ -n "$generated_build_json" ]; then
        rm -f "$generated_build_json"
    fi
    
    echo "✓ v$version build complete"
    
    # Tag as latest for this version (e.g., 15-latest)
    docker tag phalouvas/erpnext-worker:$version-$RELEASE_VERSION phalouvas/erpnext-worker:$version-latest
    echo "✓ Tagged as: phalouvas/erpnext-worker:$version-latest"
    
    # Push both tags (if enabled)
    if [ "$SHOULD_PUSH" = true ]; then
        echo "Pushing images..."
        docker push phalouvas/erpnext-worker:$version-$RELEASE_VERSION
        docker push phalouvas/erpnext-worker:$version-latest
        echo "✓ v$version pushed successfully"
    else
        echo "⊘ Push skipped (--no-push)"
    fi
    
    # Record build
    record_build $version
}

# Parse arguments for build behavior flags and versions
USE_CACHE=true
SHOULD_PUSH=true
REFRESH_APPS=false
ALLOW_UNPINNED_APPS=false
CHECK_PINS_ONLY=false
REFRESH_PINS=false
VERSIONS_TO_BUILD=()

for arg in "$@"; do
    case "$arg" in
        -h|--help)
            print_usage
            exit 0
            ;;
        --cache)
            # Kept for backward compatibility; cache is enabled by default.
            USE_CACHE=true
            ;;
        --no-cache)
            USE_CACHE=false
            ;;
        --no-push)
            SHOULD_PUSH=false
            ;;
        --refresh-apps)
            REFRESH_APPS=true
            ;;
        --allow-unpinned-apps)
            ALLOW_UNPINNED_APPS=true
            ;;
        --check-pins)
            CHECK_PINS_ONLY=true
            ;;
        --refresh-pins)
            REFRESH_PINS=true
            ;;
        --*)
            echo "Unknown option: $arg"
            echo ""
            print_usage
            exit 1
            ;;
        *)
            # Treat as version number
            VERSIONS_TO_BUILD+=("$arg")
            ;;
    esac
done

# If no versions specified, build all
if [ ${#VERSIONS_TO_BUILD[@]} -eq 0 ]; then
    VERSIONS_TO_BUILD=(14 15 16)
fi

# Set docker build cache option
if [ "$USE_CACHE" = true ]; then
    CACHE_OPTION=""
    echo "Docker cache enabled (default)"
else
    CACHE_OPTION="--no-cache"
    echo "Docker cache disabled (--no-cache)"
fi

if [ "$REFRESH_APPS" = true ]; then
    APP_CACHE_BUST=$(date -u +"%Y%m%d%H%M%S")
    echo "App refresh enabled (--refresh-apps)"
else
    echo "App refresh disabled (stable app layer cache)"
fi

# Set push option
if [ "$SHOULD_PUSH" = true ]; then
    echo "Push to Docker Hub: enabled"
else
    echo "Push to Docker Hub: disabled (--no-push)"
fi

echo "Versions to build: ${VERSIONS_TO_BUILD[*]}"
echo ""

if [ "$REFRESH_PINS" = true ]; then
    refresh_pins_for_versions
    echo ""
fi

# Validate pinning before build (production safety)
PIN_CHECK_FAILED=false
for version in "${VERSIONS_TO_BUILD[@]}"; do
    if ! json_file=$(json_file_for_version "$version"); then
        continue
    fi

    if [ ! -f "$json_file" ]; then
        continue
    fi

    if ! validate_apps_json_pins "$json_file" "$version"; then
        PIN_CHECK_FAILED=true
    fi
done

if [ "$PIN_CHECK_FAILED" = true ] && [ "$ALLOW_UNPINNED_APPS" = false ]; then
    echo ""
    echo "Build aborted due to unpinned app refs."
    echo "Use pinned tags/commits in apps json, or run with --allow-unpinned-apps to override."
    exit 1
fi

if [ "$CHECK_PINS_ONLY" = true ]; then
    if [ "$PIN_CHECK_FAILED" = true ]; then
        exit 1
    fi
    echo "✓ Pin check passed"
    exit 0
fi

# Build requested versions
for version in "${VERSIONS_TO_BUILD[@]}"; do
    case $version in
        14)
            build_and_push 14 \
                "$HOME/frappe_docker/images/azure/v14.json" \
                images/azure/Containerfile \
                version-14 \
                3.10.13 \
                16.20.2
            ;;
        15)
            build_and_push 15 \
                "$HOME/frappe_docker/images/azure/v15.json" \
                images/azure/Containerfile \
                version-15 \
                3.11.6 \
                20.19.2
            ;;
        16)
            build_and_push 16 \
                "$HOME/frappe_docker/images/azure/v16.json" \
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
echo "  ./build.sh                    # Build all versions with cache (default), push enabled"
echo "  ./build.sh --no-cache         # Build all versions without cache"
echo "  ./build.sh --no-push          # Build all versions with cache, no push"
echo "  ./build.sh 16                 # Build only v16 with cache, push enabled"
echo "  ./build.sh --refresh-apps 16  # Refresh app layer for v16 and keep other cache"
echo "  ./build.sh --refresh-pins 16  # Refresh v16 pin values from GitHub"
echo "  ./build.sh --check-pins 16    # Validate v16 app refs are pinned (no build)"
echo "  ./build.sh --allow-unpinned-apps 16 # Override pin enforcement"
