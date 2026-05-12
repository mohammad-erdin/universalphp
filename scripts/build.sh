#!/usr/bin/env bash
set -euo pipefail

####################
# Defaults
####################
PHP_VERSION='8.5'
OS_VERSION='alpine'
PLATFORM='linux/amd64'
PUSH=false
BUILDX_CONTAINER_BUILDER='universalphp-builder'

####################
# Parse arguments
# Supports: --php=8.5  --php 8.5  --os=alpine  --os alpine  --platform=linux/amd64,linux/arm64  --push
####################
while [[ $# -gt 0 ]]; do
    case "$1" in
        --php=*)      PHP_VERSION="${1#*=}"; shift ;;
        --php)        PHP_VERSION="${2:?"--php requires a value"}"; shift 2 ;;
        --os=*)       OS_VERSION="${1#*=}"; shift ;;
        --os)         OS_VERSION="${2:?"--os requires a value"}"; shift 2 ;;
        --platform=*) PLATFORM="${1#*=}"; shift ;;
        --platform)   PLATFORM="${2:?"--platform requires a value"}"; shift 2 ;;
        --push)       PUSH=true; shift ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
 done

ensure_buildx_container_builder() {
    if docker buildx inspect "${BUILDX_CONTAINER_BUILDER}" >/dev/null 2>&1; then
        docker buildx use "${BUILDX_CONTAINER_BUILDER}" >/dev/null
        return 0
    fi

    if docker buildx inspect >/dev/null 2>&1; then
        local current_driver
        current_driver=$(docker buildx inspect | awk '{ if (tolower($1) == "driver:") { print $2; exit } }')
        if [[ "${current_driver:-}" == "docker" ]]; then
            echo "Switching to a docker-container builder for multi-platform build..."
            docker buildx create --name "${BUILDX_CONTAINER_BUILDER}" --driver docker-container --use >/dev/null
            docker buildx inspect --bootstrap >/dev/null
            return 0
        fi
    fi

    echo "Creating a docker-container builder for multi-platform build..."
    docker buildx create --name "${BUILDX_CONTAINER_BUILDER}" --driver docker-container --use >/dev/null
    docker buildx inspect --bootstrap >/dev/null
}

DOCKERFILE="Dockerfile.${OS_VERSION}"

if [[ ! -f "${DOCKERFILE}" ]]; then
    echo "Error: ${DOCKERFILE} not found. Supported values: alpine, trixie" >&2
    exit 1
fi

IMAGE_TAG="ghcr.io/mohammad-erdin/docker-php:${PHP_VERSION}-frankenphp-${OS_VERSION}"

echo "Building: ${IMAGE_TAG}"
echo "  PHP version : ${PHP_VERSION}"
echo "  OS distro   : ${OS_VERSION}"
echo "  Platforms  : ${PLATFORM}"
echo "  Push       : ${PUSH}"
echo "  Dockerfile : ${DOCKERFILE}"
echo ""

if docker buildx version >/dev/null 2>&1; then
    if [[ "${PUSH}" == true ]] || [[ "${PLATFORM}" == *,* ]]; then
        ensure_buildx_container_builder
        BUILD_CMD=(docker buildx build --builder "${BUILDX_CONTAINER_BUILDER}" --platform "${PLATFORM}" --build-arg PHP_VERSION="${PHP_VERSION}" -t "${IMAGE_TAG}" -f "${DOCKERFILE}" . --push)
    else
        BUILD_CMD=(docker buildx build --platform "${PLATFORM}" --build-arg PHP_VERSION="${PHP_VERSION}" -t "${IMAGE_TAG}" -f "${DOCKERFILE}" . --load)
    fi
    echo "Building with buildx"
    "${BUILD_CMD[@]}"
else
    if [[ "${PUSH}" == true ]]; then
        echo "Error: --push requires docker buildx." >&2
        exit 1
    fi
    if [[ "${PLATFORM}" == *,* ]]; then
        echo "Error: multi-platform builds require docker buildx." >&2
        exit 1
    fi
    echo "Building without buildx"
    docker build \
        --platform "${PLATFORM}" \
        --build-arg PHP_VERSION="${PHP_VERSION}" \
        -t "${IMAGE_TAG}" \
        -f "${DOCKERFILE}" \
        .
fi
