# UniversalPHP - Production-Ready Docker PHP Images

**Supercharge your PHP experience.** UniversalPHP builds optimized Docker images based on the official PHP images with pre-configured PHP extensions, development tools, and security settings for enhanced performance.

> Built with support for **FrankenPHP**, optimized for **Laravel** and **WordPress**

## Features

- ✅ **Multiple OS Variants**: Alpine, Trixie (Debian), and standard builds
- ✅ **FrankenPHP Support**: High-performance async PHP runtime with Caddy built-in
- ✅ **Pre-configured Extensions**: Common PHP extensions optimized for Laravel/WordPress
- ✅ **Development Tools**: Node.js, npm, pnpm, Composer included
- ✅ **Security Focused**: OWASP secure headers, SSL/TLS configuration
- ✅ **Automated Cron Support**: Built-in cron daemon with task scheduling
- ✅ **Multi-stage Builds**: Optimized image sizes with minimal final layers
- ✅ **Production Ready**: Health checks and runtime validation

## Project Structure

```
.
├── Dockerfile                    # Main production Dockerfile
├── Dockerfile.alpine            # Alpine Linux variant (lightweight)
├── Dockerfile.trixie            # Debian Trixie variant (feature-rich)
├── scripts/                     # Build and deployment scripts
│   ├── build-alpine.sh         # Build Alpine image
│   ├── build-trixie.sh         # Build Trixie image
│   └── push.sh                 # Push images to registry
├── src/
│   ├── common/                 # Shared configuration across all variants
│   │   ├── etc/entrypoint.d/   # Container startup scripts
│   │   └── usr/local/          # PHP config, executables, and utilities
│   ├── utilities-webservers/   # Web server configurations
│   │   └── etc/entrypoint.d/   # SSL/TLS setup scripts
│   └── variations/
│       └── frankenphp/         # FrankenPHP-specific configuration
│           ├── etc/periodic/   # Cron job definitions
│           └── etc/frankenphp/ # Caddy and FrankenPHP configuration
└── README.md                    # This file
```

## Building Images

### Build All Variants

```bash
bash scripts/build-alpine.sh && bash scripts/build-trixie.sh
```

### Build Specific Variant

```bash
# Alpine (lightweight, ~150MB)
bash scripts/build-alpine.sh

# Trixie (full-featured, ~400MB)
bash scripts/build-trixie.sh

# Standard (traditional PHP)
docker build -f Dockerfile -t your-registry/universalphp:latest .
```

### Build with Custom Arguments

```bash
docker build \
  --build-arg PHP_VERSION=8.4 \
  --build-arg NODE_MAJOR=22 \
  -f Dockerfile.alpine \
  -t my-php:8.4-alpine .
```

## Push to Registry

```bash
bash scripts/push.sh
```

## Key Configurations

### Included PHP Extensions

Pre-configured extensions optimized for Laravel and WordPress:
- PDO MySQL/PostgreSQL
- GD (image processing)
- ZIP (compression)
- JSON, cURL, XML
- OPcache (performance)
- And more...

See [src/common/usr/local/etc/php/conf.d/serversideup-docker-php.ini](src/common/usr/local/etc/php/conf.d/serversideup-docker-php.ini) for full list.

### Development Tools

- **Composer** - PHP dependency manager
- **Node.js** - JavaScript runtime
- **npm/pnpm** - Package managers
- **Cron** - Task scheduling (FrankenPHP variant)

### FrankenPHP Variant Features

The FrankenPHP variant includes:
- **Async PHP Runtime** - Process concurrent requests efficiently
- **Caddy Integration** - Built-in web server with automatic HTTPS
- **Configurable SSL Modes** - off, mixed, full support
- **Log Levels** - Customizable logging (debug, info, warn, error, etc.)
- **Auto-HTTPS** - Automatic certificate management options
- **Scheduled Tasks** - Cron job support via periodic scripts

Configure via environment variables:
```bash
docker run \
  -e SSL_MODE=full \
  -e LOG_LEVEL=info \
  -e AUTO_HTTPS=on \
  your-registry/universalphp:frankenphp
```

## Entrypoint Sequence

Containers execute initialization scripts in order:
1. `0-container-info.sh` - Display container information
2. `1-log-output-level.sh` - Configure logging
3. `5-generate-ssl.sh` - Generate SSL certificates
4. `10-cron.sh` - Start cron daemon (FrankenPHP only)
5. `50-laravel-automations.sh` - Laravel-specific setup
6. Main application startup

## Health Checks

FrankenPHP variant includes health check scripts:
- `healthcheck-horizon` - Laravel Horizon queue worker
- `healthcheck-octane` - Laravel Octane server
- `healthcheck-queue` - Queue worker status
- `healthcheck-reverb` - WebSocket server
- `healthcheck-schedule` - Task scheduler
- `healthcheck-cron` - Cron daemon

## Container Initialization

Entrypoint files in `src/common/etc/entrypoint.d/`:
- Automatically executed on container startup
- Scripts run in alphabetical order
- Perfect for database migrations, cache warming, etc.

## Credits & Attribution

This project is derived from [serversideup/docker-php](https://github.com/serversideup/docker-php), a comprehensive Docker PHP image project maintained by Server Side Up. We appreciate their excellent work and have stripped down and customized specific variants for our needs.
