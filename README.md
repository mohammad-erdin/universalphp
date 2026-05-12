# Universal FrankenPHP Docker Images

**UniversalPHP for FrankenPHP.** Optimized Docker images based on the official PHP image.

> Built only for **FrankenPHP**, optimized for **Laravel** and **WordPress**.  
> Simplified/modified from https://github.com/serversideup/docker-php

## Features

- ✅ **Multiple OS Variants**: Alpine, Trixie (Debian), and standard builds
- ✅ **FrankenPHP Support**: High-performance async PHP runtime with Caddy built-in
- ✅ **Pre-configured Extensions**: Common PHP extensions optimized for Laravel/WordPress
- ✅ **Security Focused**: OWASP secure headers, SSL/TLS configuration
- ✅ **Automated Cron Support**: Built-in cron daemon with task scheduling

### Using `docker-compose.yml`

```yaml
services:
  frankenphp:
    image: ghcr.io/mohammad-erdin/docker-php:8.5-frankenphp-alpine
    ports:
      - "80:80"
      - "443:443"
    environment:
      SSL_MODE: full
      LOG_LEVEL: info
      AUTO_HTTPS: on
    volumes:
      - ./:/var/www/html
```

Notes:
- Use `ghcr.io/mohammad-erdin/docker-php:<PHP_VERSION>-frankenphp-<os>`.
- Supported `--os` values are `alpine` and `trixie`.
- The published tag format is `8.5-frankenphp-alpine` or `8.5-frankenphp-trixie`.
- Local builds default to `linux/amd64` so the pushed image can be pulled on CPU `linux/amd64` hosts.

### Building locally

```bash
./scripts/build.sh --php=8.5 --os=alpine
```

- This script now defaults to `--platform=linux/amd64`.
- If `docker buildx` is available, it will use `docker buildx build --platform linux/amd64 --load`.
- Override the platform when needed with `--platform=linux/amd64` or another valid platform string.

### Using `docker run`

```bash
docker run --rm \
  -p 80:80 \
  -p 443:443 \
  -e SSL_MODE=full \
  -e LOG_LEVEL=info \
  -e AUTO_HTTPS=on \
  -v "$PWD":/var/www/html \
  ghcr.io/mohammad-erdin/docker-php:8.5-frankenphp-alpine
```

Tips:
- Replace `alpine` with `trixie` for the Debian-based build.
- Add additional app environment variables as needed for Laravel or WordPress.

## Published Image Package

Prebuilt container images are published on GitHub Container Registry:
https://github.com/mohammad-erdin/universalphp/pkgs/container/docker-php

Use the package page to browse available tags, choose the correct `PHP_VERSION` and OS variant, and pull the matching image directly.

### FrankenPHP Variant Features

The FrankenPHP variant includes:
- **Async PHP Runtime** - Process concurrent requests efficiently
- **Caddy Integration** - Built-in web server with automatic HTTPS
- **Configurable SSL Modes** - off, mixed, full support
- **Log Levels** - Customizable logging (debug, info, warn, error, etc.)
- **Auto-HTTPS** - Automatic certificate management options
- **Scheduled Tasks** - Cron job support via periodic scripts

## Container Initialization

Entrypoint files in `src/common/etc/entrypoint.d/`:
- Automatically executed on container startup
- Scripts run in alphabetical order
- Perfect for database migrations, cache warming, etc.

## Credits & Attribution

This project is derived from [serversideup/docker-php](https://github.com/serversideup/docker-php), a comprehensive Docker PHP image project maintained by Server Side Up. We appreciate their excellent work and have stripped down and customized specific variants for our needs.
