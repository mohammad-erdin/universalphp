#!/usr/bin/env bash
set -euo pipefail

####################
# Defaults
####################
PHP_VERSION='8.5'
OS_VERSION='alpine'

####################
# Parse arguments
# Supports: --php=8.5  --php 8.5  --os=alpine  --os alpine
####################
while [[ $# -gt 0 ]]; do
    case "$1" in
        --php=*)  PHP_VERSION="${1#*=}"; shift ;;
        --php)    PHP_VERSION="${2:?'--php requires a value'}"; shift 2 ;;
        --os=*)   OS_VERSION="${1#*=}"; shift ;;
        --os)     OS_VERSION="${2:?'--os requires a value'}"; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

DOCKERFILE="Dockerfile.${OS_VERSION}"

if [[ ! -f "${DOCKERFILE}" ]]; then
    echo "Error: ${DOCKERFILE} not found. Supported values: alpine, trixie" >&2
    exit 1
fi

IMAGE_TAG="ghcr.io/mohammad-erdin/docker-php:${PHP_VERSION}-frankenphp-${OS_VERSION}"

echo "Building: ${IMAGE_TAG}"
echo "  PHP version : ${PHP_VERSION}"
echo "  OS distro   : ${OS_VERSION}"
echo "  Dockerfile  : ${DOCKERFILE}"
echo ""

docker build \
    --build-arg PHP_VERSION="${PHP_VERSION}" \
    -t "${IMAGE_TAG}" \
    -f "${DOCKERFILE}" \
    .
