# Task: Production-Ready Trixie Image (Multi-Stage + Runtime Validation)

## Goal
Refactor and validate the Trixie image so it is production-ready with a strict multi-stage strategy:

1. Use at least 2 stages (`build`, `final`)
2. Keep heavy build/install work in `build` for caching efficiency
3. Copy only runtime binaries/assets into `final`
4. Significantly reduce final image size
5. Validate runtime behavior in a temporary container:
   - `frankenphp` works
   - `node`, `npm`, `pnpm` work
   - `cron` runs and executes the catch-all job in `root-trixie`

---

## Image
- Candidate: `test-trixie:latest`
- Baseline: `ghcr.io/mohammad-erdin/docker-php:8.4-frankenphp-trixie`

---

## Implementation Summary

### `Dockerfile.trixie` Refactor

Applied a true multi-stage design:

1. `build` stage
- Installs build dependencies and compilers
- Builds FrankenPHP via `xcaddy`
- Installs PHP extensions
- Installs Node toolchain and pnpm

2. `final` stage
- Starts from clean `php:8.5-zts-trixie`
- Installs only runtime packages
- Copies only runtime artifacts from `build`:
  - `/usr/local/bin/frankenphp`
  - `/usr/local/bin/composer`
  - `/usr/local/bin/node`
  - `/usr/local/lib/node_modules`
  - `/usr/local/lib/php/extensions`
  - `/usr/local/etc/php/conf.d`
  - `/usr/local/lib/libwatcher-c.so*`
- Keeps Trixie cron wiring (`/etc/crontab` + entrypoint script)

### Runtime Dependency Set (Final Stage)

Final runtime package set in Trixie:

- `procps`
- `libstdc++6`
- `ca-certificates`
- `cron`
- `libpq5`
- `libzip5`
- `liblz4-1`

### Build Guard Added

To prevent false-green builds, final stage dependency installation now validates runtime commands during build:

- `command -v cron`
- `command -v ps`

If either binary is missing, the build fails immediately.

---

## Validation Commands Used

### Build

```sh
docker build --build-arg FINAL_RUNTIME_PACKAGES_VERSION=2026-05-01c -f Dockerfile.trixie -t test-trixie:latest .
```

### Run temporary container

```sh
docker run -d --name cron-test-trixie test-trixie:latest
```

### Verify runtime tools

```sh
docker exec cron-test-trixie sh -lc 'frankenphp version'
docker exec cron-test-trixie sh -lc 'node --version && npm --version && pnpm --version'
docker exec cron-test-trixie sh -lc 'mkdir -p /tmp/npm-init && cd /tmp/npm-init && npm init -y'
docker exec cron-test-trixie sh -lc 'mkdir -p /tmp/pnpm-init && cd /tmp/pnpm-init && pnpm init </dev/null'
```

### Verify cron daemon and job output

```sh
docker exec -u root cron-test-trixie sh -lc 'command -v cron && command -v ps && ps aux | grep [c]ron'
docker exec -u root cron-test-trixie sh -lc 'cat /etc/crontab'

# Wait/poll for cron tick to generate /tmp/roots.txt
docker exec -u root cron-test-trixie sh -lc '
  for i in $(seq 1 16); do
    if [ -s /tmp/roots.txt ]; then cat /tmp/roots.txt; exit 0; fi
    sleep 5
  done
  exit 1
'
```

### Confirm recurring execution

```sh
docker exec -u root cron-test-trixie sh -lc '
  first=$(cat /tmp/roots.txt)
  for i in $(seq 1 16); do
    now=$(cat /tmp/roots.txt)
    [ "$now" != "$first" ] && echo "$now" && exit 0
    sleep 5
  done
  exit 1
'
```

### Cleanup

```sh
docker rm -f cron-test-trixie
```

---

## Validation Result: ✅ PASSED

### Tooling Checks

| Check | Result |
|---|---|
| `frankenphp version` | ✅ `v2.11.2` |
| `node --version` | ✅ `v24.15.0` |
| `npm --version` | ✅ `11.12.1` |
| `pnpm --version` | ✅ `10.33.2` |
| `npm init -y` | ✅ `package.json` created |
| `pnpm init` | ✅ `package.json` created |

### Cron Checks

| Check | Result |
|---|---|
| `cron` binary present | ✅ `/usr/sbin/cron` |
| `ps` binary present | ✅ `/usr/bin/ps` |
| `cron` in process list | ✅ running as `root` |
| `/tmp/roots.txt` generated | ✅ `Thu Apr 30 19:28:01 UTC 2026` |
| `/tmp/roots.txt` updates each minute | ✅ `19:28:01` -> `19:29:02` |

### Size Reduction

| Image | Size |
|---|---|
| `ghcr.io/mohammad-erdin/docker-php:8.4-frankenphp-trixie` | `4.19GB` |
| `test-trixie:latest` | `804MB` |

Reduction: ~`80.8%` smaller final image.

---

## Files Modified

- `Dockerfile.trixie` (multi-stage production refactor + runtime dependency hardening)
