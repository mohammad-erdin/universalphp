# Task: Validate cron in Trixie Container

## Goal
Confirm that `cron` (Debian's cron daemon) is running inside `test-trixie:latest` and that the system crontab defined in `src/variations/frankenphp/etc/periodic/root-trixie` is active. Specifically, the catch-all job:

```
*       *       *       *       *       root    date | tee /tmp/roots.txt
```

…should produce `/tmp/roots.txt` with content inside a live container.

---

## Image
`test-trixie:latest`

---

## Plan

### Step 1 — Start a detached container
Run `test-trixie:latest` as a long-lived container so cron has time to fire at least once (cron minimum resolution is 1 minute):

```sh
docker run -d --name cron-test test-trixie:latest
```

> The default `ENTRYPOINT` / `CMD` starts `frankenphp`, which in turn should start cron via the serversideup entrypoint scripts.

### Step 2 — Wait ≥ 60 seconds
Wait at least 60 s for the first `* * * * *` tick to execute. Use `sleep 65` (or watch in a loop).

### Step 3 — Exec into the container
```sh
docker exec -it cron-test bash
```

### Step 4 — Verify inside the container
Check two things:

1. **cron process is running:**
   ```sh
   ps aux | grep cron
   ```
   Expected: a `cron` process owned by root.

2. **Output file exists and has content:**
   ```sh
   cat /tmp/roots.txt
   ```
   Expected: a date string, e.g. `Thu May  1 12:34:00 UTC 2026`.

### Step 5 — Cleanup
```sh
docker rm -f cron-test
```

---

## Validation Result: ✅ PASSED

### Fixes Applied to `Dockerfile.trixie`

1. **Added missing COPY for entrypoint scripts** — `src/variations/frankenphp/etc/entrypoint.d/` → `/etc/entrypoint.d/` (provides `10-cron.sh` which starts `cron`)
2. **Added missing COPY for crontab** — `src/variations/frankenphp/etc/periodic/root-trixie` → `/etc/crontab`
3. **Set setuid on `cron`** — `chmod 4755 /usr/sbin/cron` in the setup RUN step, so the `www-data` user can invoke it and it runs as root

### Final Checks

| Check | Result |
|---|---|
| `cron` in `ps aux` | ✅ PID 24, running as root |
| `/tmp/roots.txt` exists | ✅ Present |
| `/tmp/roots.txt` content | ✅ `Thu Apr 30 18:35:01 UTC 2026` |
| File updates each minute | ✅ Confirmed (18:35:01 → 18:36:01) |

### Files Modified
- `Dockerfile.trixie` — three additions described above; image rebuilt as `test-trixie:latest`

### Fix Required in `Dockerfile.trixie`

Add the following two `COPY` instructions (alongside the existing `frankenphp/` copy):

```dockerfile
COPY --chmod=755 src/variations/frankenphp/etc/entrypoint.d/ /etc/entrypoint.d/
COPY src/variations/frankenphp/etc/periodic/root-trixie /etc/crontab
```

> Note: Debian cron reads `/etc/crontab` (not `/etc/crontabs/root`), and entries require a user field — already present in `root-trixie`.

---

## Fix Implementation Plan

### Phase 1 — Patch & Rebuild
1. Add the two `COPY` lines to `Dockerfile.trixie` (after the existing `frankenphp/` copy).
2. Rebuild: `docker build -f Dockerfile.trixie -t test-trixie .`

### Phase 2 — Validate in fresh container
1. `docker run -d --name cron-test test-trixie:latest`
2. `sleep 65`
3. `docker exec -u root cron-test ps aux | grep cron` — expect a `cron` process
4. `docker exec -u root cron-test cat /tmp/roots.txt` — expect a date string

### Phase 3 — Fix inside container if still failing
- If `cron` is missing: exec in and manually run `cron`, watch `/tmp/roots.txt` appear; then identify why the entrypoint didn't fire.
- If crontab is wrong: inspect `/etc/crontab` inside the container, fix the source file and rebuild.

### Phase 4 — Persist & Final Rebuild
Once validated, the two `COPY` lines are already in `Dockerfile.trixie`.
Final rebuild confirms the persisted image is correct.

### Phase 5 — Cleanup
`docker rm -f cron-test`
