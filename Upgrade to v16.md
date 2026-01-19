# Upgrade to v16 - Repository Branch Validation & Issues

## Repository Validation Summary

### ✅ Frappe Official Apps with version-16 Branches

1. **frappe/erpnext** → `version-16` ✓
2. **frappe/hrms** → `version-16` ✓
3. **frappe/health** → `version-16` ✓ (fixed from `main`)

### ⚠️ Frappe Official Apps Using Develop Branch

4. **frappe/payments**
   - **Available Branches:** `develop`, `version-15`, `version-14`, `version-13`
   - **Issue:** No `version-16` branch exists yet
   - **Solution:** Using `develop` branch
   - **Risk:** Unstable, may have breaking changes

5. **frappe/webshop**
   - **Available Branches:** `develop`, `version-15`, `version-14`
   - **Issue:** No `version-16` branch exists yet
   - **Solution:** Using `develop` branch
   - **Risk:** Unstable, may have breaking changes

### 🔒 Custom Apps (22 total) - Private Repositories

All phalouvas/kainotomo-* apps using `master` branch:
- frappe_s3_attachment
- erpnext_otp
- frappe_whatsapp
- phdigital + 18 related modules

**Status:** Cannot validate branches remotely (private repos)
**Risk:** Unknown v16 compatibility - requires testing

---

## Compatibility Matrix

| Category | Total Apps | Proper v16 Branch | Using Develop | Unknown |
|----------|-----------|-------------------|---------------|---------|
| Frappe Official | 4 | 3 ✓ | 2 ⚠️ | 0 |
| Custom Apps | 22 | 0 | 0 | 22 🔒 |
| **TOTAL** | **26** | **3** | **2** | **22** |

---

## Risk Assessment

### Low Risk ✅
- frappe/erpnext - Official version-16 branch
- frappe/hrms - Official version-16 branch
- frappe/health - Official version-16 branch

### Medium Risk ⚠️
- frappe/payments - Using develop (unstable)
- frappe/webshop - Using develop (unstable)

### Unknown Risk 🔒
- All 22 custom apps - Need v16 compatibility testing

---

## Next Steps & Testing Plan

- [x] Validate all Frappe official app branches
- [x] Fix frappe/health from `main` to `version-16`
- [ ] **Build v16 image:** `./build.sh 16`
- [ ] **Deploy to test environment** (localhost or docker-2)
- [ ] **Test core functionality:**
  - [ ] ERPNext basic operations
  - [ ] HRMS modules
  - [ ] Health module
  - [ ] Payment gateway functionality
  - [ ] Webshop functionality
- [ ] **Test all 22 custom apps** in v16 environment
- [ ] Monitor frappe repos for official version-16 releases:
  - [ ] frappe/payments
  - [ ] frappe/webshop
- [ ] **Production deployment** only after full validation

---

## Alternative Options for Payments/Webshop

1. **Current approach:** Use `develop` branches (risky but may work)
2. **Conservative:** Remove apps if not essential, add later when v16 branch exists
3. **Unsafe:** Use `version-15` branches (high incompatibility risk)
4. **Advanced:** Fork and maintain custom v16-compatible branches

**Recommendation:** Test with `develop` first. If issues arise, remove apps temporarily.

---

## How to Upgrade a Site from v15 to v16 (safe, step-by-step)

### Preconditions
- v15 stack runs on port 8084; v16 stack on port 8085 (Traefik routing in place).
- The site’s domain is routed **either** to v15 **or** to v16, never both.
- You have shell access to the host running the stack (desktop-2/docker-1/etc.).

### 1) Backup on v15 (database + files)
```bash
# On v15 backend container
docker exec -it erpnext-v15-backend-1 bench --site <site> backup
# Optional: copy backup out if desired
# docker cp erpnext-v15-backend-1:/home/frappe/frappe-bench/sites/<site>/private/backups ./backups-<site>
```
Confirm backup files exist before proceeding.

### 2) Adjust routing (Traefik) to move the site to v16
- Edit the v15 compose to **remove** the site’s domain from the v15 Host() list.
- Edit the v16 compose to **add** the site’s domain to the v16 Host() list.
- Bring the stacks up to apply labels:
```bash
# Example for desktop-2
docker compose --project-name erpnext-v15 -f ~/gitops/desktop-2/erpnext-v15.yaml up -d
docker compose --project-name erpnext-v16 -f ~/gitops/desktop-2/erpnext-v16.yaml up -d
```
Traefik will now route that domain to v16 (port 8085).

### 3) Restore the site into v16
```bash
# Copy or place the backup (.sql.gz and files) into v16 sites folder if needed
# Then inside v16 backend
docker exec -it erpnext-v16-backend-1 bash -lc "bench --site <site> restore /home/frappe/frappe-bench/sites/<site>/private/backups/<backup>.sql.gz"
docker exec -it erpnext-v16-backend-1 bench --site <site> migrate
docker exec -it erpnext-v16-backend-1 bench --site <site> clear-cache
docker exec -it erpnext-v16-backend-1 bench --site <site> clear-website-cache
```

### 4) Validate on v16
- Quick checks: login, desk load, key doctypes, reports, print, email, attachments.
- Custom apps: run through critical flows specific to the site.
- Logs to watch:
```bash
docker compose --project-name erpnext-v16 -f ~/gitops/desktop-2/erpnext-v16.yaml logs -f frontend backend queue-long queue-short scheduler
```

### 5) If issues → Rollback to v15
- Revert routing: remove the domain from v16 Host() list, add back to v15 Host().
- Bring stacks up to apply labels:
```bash
docker compose --project-name erpnext-v15 -f ~/gitops/desktop-2/erpnext-v15.yaml up -d
docker compose --project-name erpnext-v16 -f ~/gitops/desktop-2/erpnext-v16.yaml up -d
```
- Restore the last v15 backup if data was changed during the failed v16 attempt:
```bash
docker exec -it erpnext-v15-backend-1 bash -lc "bench --site <site> restore /home/frappe/frappe-bench/sites/<site>/private/backups/<backup>.sql.gz"
```

### 6) Rinse-and-repeat per site
- Migrate sites one-by-one; keep untouched sites on v15 until validated.
- Never have the same site served by both stacks concurrently.

### Tips
- Keep a dated backup per migration attempt.
- If payments/webshop misbehave (using develop branches), consider disabling those apps for that site before retrying.
- After all sites migrate cleanly, you can decommission v15 routing.

---

## Desktop-2 Execution Plan (with AI agent assistance)

Goal: Run v15 (8084) and v16 (8085) side-by-side on desktop-2, migrating sites one-by-one using the steps above, with the agent executing commands safely.

What the agent (or human) must know:
- v15 compose: `~/gitops/desktop-2/erpnext-v15.yaml` (port 8084, hosts: all except v15.kainotomo.com)
- v16 compose: `~/gitops/desktop-2/erpnext-v16.yaml` (port 8085, hosts: only v15.kainotomo.com right now)
- Never serve the same site from both stacks at once. Route a domain to exactly one stack.
- Redis/DB are shared endpoints; the isolation is achieved by not running the same site on both benches simultaneously.

Typical agent workflow per site:
1) **Backup on v15**
  - `docker exec -it erpnext-v15-backend-1 bench --site <site> backup`
  - Optionally `docker cp` backups out.
2) **Routing swap**
  - Remove domain from v15 Host() list, add to v16 Host() list in the compose files.
  - Apply labels: `docker compose --project-name erpnext-v15 -f ~/gitops/desktop-2/erpnext-v15.yaml up -d`
              `docker compose --project-name erpnext-v16 -f ~/gitops/desktop-2/erpnext-v16.yaml up -d`
3) **Restore + migrate on v16**
  - `docker exec -it erpnext-v16-backend-1 bash -lc "bench --site <site> restore /home/frappe/frappe-bench/sites/<site>/private/backups/<backup>.sql.gz"`
  - `docker exec -it erpnext-v16-backend-1 bench --site <site> migrate`
  - `docker exec -it erpnext-v16-backend-1 bench --site <site> clear-cache`
  - `docker exec -it erpnext-v16-backend-1 bench --site <site> clear-website-cache`
4) **Validate**
  - Logs: `docker compose --project-name erpnext-v16 -f ~/gitops/desktop-2/erpnext-v16.yaml logs -f frontend backend queue-long queue-short scheduler`
  - Manual smoke tests for the site.
5) **Rollback if needed**
  - Swap domains back to v15; apply labels with the same compose commands as above.
  - Restore the v15 backup: `docker exec -it erpnext-v15-backend-1 bash -lc "bench --site <site> restore /home/frappe/frappe-bench/sites/<site>/private/backups/<backup>.sql.gz"`

Important guardrails for the agent:
- Do not edit hosts/ports for other environments (docker-1, docker-2, localhost).
- Do not run both v15 and v16 for the same domain at the same time.
- Always take/verify backup before migrating a site.
- Make routing changes before restore/migrate to ensure the site isn’t reachable from the wrong stack during migration.
