# Upgrade to v16 - Repository Branch Validation & Issues

---

## 🚀 ERPNext v15 → v16 Migration Guide (Reusable Prompt)

**How to use this document:**
1. Reference this file in your chat: `#file:Upgrade to v16.md`
2. AI Agent will read the full migration plan and status
3. Agent will **ALWAYS ask your approval before executing each step**
4. Agent will execute step-by-step with clear progress tracking
5. Update the migration status table below after each successful migration

### ⚠️ IMPORTANT REQUIREMENTS FOR AI AGENT
- **NEVER run critical commands without explicit user approval**
- **ALWAYS explain what each step does before executing**
- **ALWAYS wait for user confirmation after each major step**
- **Ask if user wants to proceed to next step**
- **Keep this document updated with migration progress**
- **Desktop-2 is PRODUCTION - treat with extreme care**

---

## Migration Status Tracker

| Site Domain | V16 Database Name | Status | Date | Notes |
|---|---|---|---|---|
| v15.kainotomo.com | v16_v15_kainotomo_com | ⬜ Not Started | - | Testing site - starts here |
| cyprussportsfever.com | v16_cyprussportsfever_com | ⬜ Not Started | - | |
| kainotomo.com | v16_kainotomo_com | ⬜ Not Started | - | |
| erp.detima.com | v16_erp_detima_com | ⬜ Not Started | - | |
| gpapachristodoulou.com | v16_gpapachristodoulou_com | ⬜ Not Started | - | |
| mozsportstech.com | v16_mozsportstech_com | ⬜ Not Started | - | |
| pakore6.kainotomo.com | v16_pakore6_kainotomo_com | ⬜ Not Started | - | |
| app.swissmedhealth.com | v16_app_swissmedhealth_com | ⬜ Not Started | - | |
| cpl.kainotomo.com | v16_cpl_kainotomo_com | ⬜ Not Started | - | |
| eumariaphysio.com | v16_eumariaphysio_com | ⬜ Not Started | - | |

**Legend:**
- ⬜ Not Started - Pending migration
- 🟨 In Progress - Currently migrating
- ✅ Completed - Migration successful
- ❌ Rollback - Reverted to v15

---

## How to Upgrade a Site from v15 to v16 (safe, step-by-step)

### Option 2: Safe Parallel Upgrade (RECOMMENDED - Separate Databases)

This approach creates isolated v16 databases for each site, allowing parallel v15/v16 operation with zero downtime and full rollback capability.

**EXECUTION FRAMEWORK:**
- Agent will display each step with explanation
- Agent will ask: "Ready to proceed with Step X? (yes/no)"
- Agent will execute only after user confirms
- Agent will show command output and verify success
- Agent will ask to proceed to next step
- User can stop/rollback at any point

### Preconditions (VERIFY BEFORE STARTING)
- ✅ v15 stack runs on port 8084; v16 stack on port 8085 (Traefik routing in place)
- ✅ The site's domain is routed **either** to v15 **or** to v16, never both
- ✅ Both stacks share the **same MariaDB** instance
- ✅ Shell access available to desktop-2
- ✅ Desktop-2 is production - double check before proceeding

**Agent: Before starting, confirm with user that all preconditions are met.**

---

## AGENT VERIFICATION CHECKLIST (Run Automatically)

**Agent: Execute these verification commands. Report findings to user and ask for approval to proceed.**

### Check 1: Verify v15 stack on port 8084
```bash
docker ps -f "name=erpnext-v15-frontend-1" --format "{{.Names}}: {{.Ports}}"
```
**Expected:** `erpnext-v15-frontend-1: 0.0.0.0:8084->8080/tcp`

### Check 2: Verify v16 stack on port 8085
```bash
docker ps -f "name=erpnext-v16-frontend-1" --format "{{.Names}}: {{.Ports}}"
```
**Expected:** `erpnext-v16-frontend-1: 0.0.0.0:8085->8080/tcp`

### Check 3: Verify v15.kainotomo.com is currently on v15 (not v16)
```bash
grep -A 5 "traefik.http.routers.erpnext-v15-https.rule" ~/gitops/desktop-2/erpnext-v15.yaml | grep v15.kainotomo
```
**Expected:** `v15.kainotomo.com` appears in v15 Host() list

```bash
grep "traefik.http.routers.erpnext-v16-https.rule" ~/gitops/desktop-2/erpnext-v16.yaml
```
**Expected:** v15.kainotomo.com is NOT in v16 Host() list (or only Host(`v15.kainotomo.com`) if pre-configured)

### Check 4: Verify both stacks use same MariaDB
```bash
docker exec erpnext-v15-backend-1 cat /home/frappe/frappe-bench/sites/v15.kainotomo.com/site_config.json | grep db_host
docker exec erpnext-v16-backend-1 cat /home/frappe/frappe-bench/sites/.env 2>/dev/null || echo "Check compose file..."
```
**Expected:** Both point to `mariadb-database` or same host

### Check 5: Verify shell access to containers works
```bash
docker ps -q | wc -l
```
**Expected:** Non-zero number (containers running)

### Check 6: Get user confirmation this is PRODUCTION
**Agent: Ask user explicitly:**
"Is desktop-2 a PRODUCTION environment with live users? (yes/no)"

---

**Agent: After running all checks above, provide a summary:**

| Check | Status | Finding | Proceed? |
|---|---|---|---|
| v15 on 8084 | ✅/❌ | Port 8084 listening | |
| v16 on 8085 | ✅/❌ | Port 8085 listening | |
| v15.kainotomo.com routed to v15 | ✅/❌ | Domain on v15 not v16 | |
| Both use same MariaDB | ✅/❌ | Shared database instance | |
| Shell access works | ✅/❌ | Can execute commands | |
| Desktop-2 is PRODUCTION | ✅/❌ | User confirmed | |

**If all checks pass:** Ask user "All preconditions verified. Ready to start Step 1? (yes/no)"

**If any check fails:** Report which check failed and why. Ask if user wants to:
1. Troubleshoot the issue
2. Skip this migration
3. Continue anyway at higher risk

---

## STEP-BY-STEP MIGRATION PROCESS

### Sites to Upgrade (Desktop-2)
- v15.kainotomo.com → v16_v15_kainotomo_com
- cyprussportsfever.com → v16_cyprussportsfever_com
- kainotomo.com → v16_kainotomo_com
- erp.detima.com → v16_erp_detima_com
- gpapachristodoulou.com → v16_gpapachristodoulou_com
- mozsportstech.com → v16_mozsportstech_com
- pakore6.kainotomo.com → v16_pakore6_kainotomo_com
- app.swissmedhealth.com → v16_app_swissmedhealth_com
- cpl.kainotomo.com → v16_cpl_kainotomo_com
- eumariaphysio.com → v16_eumariaphysio_com

### 1) Backup on v15 (database + files)

**What this step does:**
- Creates a complete backup of v15 site database
- Includes all files (attachments, custom files)
- Backup files stored in `/private/backups/` directory
- ~1-2 minutes per site, non-blocking

**Agent: Explain this step and wait for user approval before running.**

```bash
# Example: v15.kainotomo.com
SITE="v15.kainotomo.com"
docker exec erpnext-v15-backend-1 bench --site ${SITE} backup --with-files

# Verify backup created
docker exec erpnext-v15-backend-1 ls -lh /home/frappe/frappe-bench/sites/${SITE}/private/backups/ | tail -5
```

**After Step 1:** Verify backup files exist and note the timestamp. User confirms to proceed to Step 2.

---

### 2) Create site on v16 with new database name

**What this step does:**
- Creates new site directory structure on v16
- Automatically creates v16 database (v16_v15_kainotomo_com)
- Initializes site_config.json with defaults
- Creates new empty database (will be replaced in Step 5)
- ~30 seconds

**Risk:** None - can be deleted if migration fails

**Agent: Explain this step and wait for user approval before running.**

```bash
# Define variables
SITE="v15.kainotomo.com"
V16_DB_NAME="v16_kainotomo_com"  # Format: v16_<database_name>
DB_PASSWORD="pRep5v3Nzw_aMMV"
ADMIN_PASSWORD="pRep5v3Nzw_aMMV"

# Create site on v16 with specific database name and passwords
# bench new-site automatically creates the database
docker exec erpnext-v16-backend-1 bench new-site ${SITE} \
  --db-name ${V16_DB_NAME} \
  --admin-password "${ADMIN_PASSWORD}" \
  --db-password "${DB_PASSWORD}" \
  --mariadb-root-password "${DB_PASSWORD}" \
  --force

# Verify site directory created
docker exec erpnext-v16-backend-1 ls -lh /home/frappe/frappe-bench/sites/${SITE}/site_config.json
```

**After Step 2:** Verify site_config.json exists. User confirms to proceed to Step 3.

---

### 2.1) Enable Scheduler (Optional but Recommended)

**What this step does:**
- Re-enables the scheduler for the new site on v16
- The scheduler runs background jobs like email sending, report generation, etc.
- By default, the scheduler is disabled on new sites
- Takes ~5 seconds

**Risk:** None - can be disabled if needed later

**Agent: Explain this step and wait for user approval before running.**

```bash
SITE="v15.kainotomo.com"

# Enable the scheduler for the site
docker exec erpnext-v16-backend-1 bench --site ${SITE} set-config scheduler_disabled 0

# Verify scheduler is enabled
docker exec erpnext-v16-backend-1 bench --site ${SITE} get-config scheduler_disabled
```

**Expected output:** Should return `0` or `null` (meaning scheduler is enabled)

**After Step 2.1:** Scheduler is now enabled. User confirms to proceed to Step 3.

---

### 3) Copy backup files to v16 sites directory

**What this step does:**
- Copies backup SQL database file from v15 to v16
- Copies backup configuration file
- Copies file attachments if any
- ~1-2 minutes, non-blocking

**Risk:** None - just file copies

**Agent: Explain this step and wait for user approval before running.**

```bash
SITE="v15.kainotomo.com"

# Copy backup files from v15 to v16 backups folder
docker cp erpnext-v15-backend-1:/home/frappe/frappe-bench/sites/${SITE}/private/backups /tmp/backups-${SITE}
docker cp /tmp/backups-${SITE}/* erpnext-v16-backend-1:/home/frappe/frappe-bench/sites/${SITE}/private/backups/

# Verify backup in v16
docker exec erpnext-v16-backend-1 ls -lh /home/frappe/frappe-bench/sites/${SITE}/private/backups/ | tail -3
```

**After Step 3:** Verify backup files copied to v16. User confirms to proceed to Step 4.

---

### 4) Adjust routing (Traefik) - move domain from v15 to v16

**What this step does:**
- **MANUAL STEP** - User must edit YAML files
- Removes domain from v15's Traefik routing rules
- Adds domain to v16's Traefik routing rules
- Traefik reloads config and routes domain to v16 port (8085)
- After this: site is NO LONGER accessible on v15
- ~30 seconds after files saved

**⚠️ CRITICAL:** This is the point of no return for domain access. Domain will briefly be unavailable.

**Agent: Provide exact instructions for manual edits and wait for user confirmation.**

**File 1: Edit** `~/gitops/desktop-2/erpnext-v15.yaml`
```
Find this line with your domain (v15.kainotomo.com):
  traefik.http.routers.erpnext-v15-https.rule: Host(`cyprussportsfever.com`,`kainotomo.com`,`erp.detima.com`,`gpapachristodoulou.com`,`mozsportstech.com`,`pakore6.kainotomo.com`,`app.swissmedhealth.com`,`cpl.kainotomo.com`,`eumariaphysio.com`,`v15.kainotomo.com`)

Remove `v15.kainotomo.com` from the list
```

**File 2: Edit** `~/gitops/desktop-2/erpnext-v16.yaml`
```
Find this line:
  traefik.http.routers.erpnext-v16-https.rule: Host(`v15.kainotomo.com`)

Add your site if not already there. Example:
  traefik.http.routers.erpnext-v16-https.rule: Host(`v15.kainotomo.com`,`new-site.com`)
```

**After manual edits, run these commands:**

```bash
# Apply the changes
docker compose --project-name erpnext-v15 -f ~/gitops/desktop-2/erpnext-v15.yaml up -d
docker compose --project-name erpnext-v16 -f ~/gitops/desktop-2/erpnext-v16.yaml up -d

# Verify routing changed (wait 5-10 seconds for Traefik to reload)
sleep 10
echo "Traefik routing updated. Domain now points to v16 (port 8085)"
```

**After Step 4:** Domain is now pointing to v16. User confirms to proceed to Step 5.

---

### 5) Restore database and files into v16

**What this step does:**
- Reads v15 backup SQL file
- Imports all v15 data into v16 database
- Restores site_config.json with all original encryption keys
- Restores file attachments to correct locations
- Replaces empty v16 database with v15 data
- **CRITICAL:** This is when v15 data enters v16
- ~5-10 minutes depending on data size

**Risk:** Medium - if fails, domain is on v16 but DB not restored (site broken)
**Mitigation:** Can rollback by reverting routing in Step 4 and restoring v15 backup

**Agent: Explain this step and wait for user approval before running.**

```bash
SITE="v15.kainotomo.com"

# Find latest backup file
BACKUP_FILE=$(docker exec erpnext-v16-backend-1 ls -t /home/frappe/frappe-bench/sites/${SITE}/private/backups/*-database.sql.gz | head -1)
echo "Using backup: ${BACKUP_FILE}"

# Restore database (replaces empty DB with v15 data)
# Also restores files and site_config.json with all original settings/encryption keys
docker exec erpnext-v16-backend-1 bash -lc "bench restore ${BACKUP_FILE}"

# Verify restore completed
docker exec erpnext-v16-backend-1 cat /home/frappe/frappe-bench/sites/${SITE}/site_config.json | grep db_name
```

**After Step 5:** Verify restore completed and database name shows v16_* version. User confirms to proceed to Step 6.

---

### 6) Run database migration for v16

**What this step does:**
- Upgrades database schema from v15 format to v16 format
- Runs all pending migrations
- Updates document types, fields, etc.
- Clears all caches (Redis)
- **CRITICAL:** Makes data compatible with v16 code
- ~5-15 minutes depending on data complexity

**Risk:** High - if migration fails, site is broken on v16
**Mitigation:** Rollback to v15 (Step 8)

**Agent: Warn user about risk and wait for approval before running.**

```bash
SITE="v15.kainotomo.com"

# Run migrate to upgrade database schema for v16
echo "Running migration on ${SITE}..."
docker exec erpnext-v16-backend-1 bench --site ${SITE} migrate

# Clear all caches
docker exec erpnext-v16-backend-1 bench --site ${SITE} clear-cache
docker exec erpnext-v16-backend-1 bench --site ${SITE} clear-website-cache

echo "Migration and cache clear completed for ${SITE}"
```

**After Step 6:** Watch for any errors in console output. User confirms to proceed to Step 7.

---

### 7) Validate on v16

**What this step does:**
- Checks v16 logs for errors
- Tests basic CLI commands (lists users)
- User performs manual browser tests
- Verifies custom apps work
- **NO CHANGES** - just checking everything works

**Risk:** None - read-only validation

**Agent: Explain validation checklist and wait for user feedback.**

```bash
SITE="v15.kainotomo.com"

# Check logs for errors (Ctrl+C to stop)
echo "Checking v16 logs for errors (Ctrl+C to stop)..."
docker compose --project-name erpnext-v16 -f ~/gitops/desktop-2/erpnext-v16.yaml logs -f frontend backend queue-long queue-short scheduler --tail 50 &
LOGS_PID=$!
sleep 10
kill $LOGS_PID 2>/dev/null || true

# Quick validation commands:
echo "Validating site: ${SITE}"
docker exec erpnext-v16-backend-1 bench --site ${SITE} execute frappe.desk.page.setup_wizard.setup_wizard.get_setup_complete
docker exec erpnext-v16-backend-1 bench --site ${SITE} list User --limit 3

echo "✓ Command validation passed"
```

**Manual validation checklist (in browser at site domain):**
- [ ] Login works with valid credentials
- [ ] Desk/UI loads without errors
- [ ] Core doctypes visible (Invoice, Purchase Order, etc.)
- [ ] Custom apps appear in modules list
- [ ] Test critical site-specific workflows
- [ ] Check file attachments and downloads work
- [ ] Test email/notification sending (if applicable)

**After Step 7:** User confirms all tests pass or reports issues. If issues, proceed to Step 8 (Rollback).

---

### 8) If issues → Rollback to v15

**What this step does:**
- Reverts routing back to v15
- Optionally restores v15 database if needed
- Optionally cleans up v16 database
- Site returns to v15, no data loss

**Risk:** None - reverses changes

**Agent: Only offer rollback if user reports issues in Step 7.**

```bash
SITE="v15.kainotomo.com"
V16_DB_NAME="v16_v15_kainotomo_com"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-root}"

echo "Rolling back ${SITE} to v15..."

# Step 1: Revert routing (move domain back to v15)
# Edit v15 compose: add site domain back to Host() rule
# Edit v16 compose: remove site domain from Host() rule
docker compose --project-name erpnext-v15 -f ~/gitops/desktop-2/erpnext-v15.yaml up -d
docker compose --project-name erpnext-v16 -f ~/gitops/desktop-2/erpnext-v16.yaml up -d

sleep 10
echo "✓ Routing reverted to v15"

# Step 2: Restore v15 database if data was modified
# (Optional: only if data changed during failed v16 attempt)
BACKUP_V15=$(docker exec erpnext-v15-backend-1 ls -t /home/frappe/frappe-bench/sites/${SITE}/private/backups/*-database.sql.gz | head -1)
echo "Restoring v15 backup from: ${BACKUP_V15}"
docker exec erpnext-v15-backend-1 bash -lc "bench --site ${SITE} restore ${BACKUP_V15}"

# Step 3: Clean up v16 database (optional - keeps for forensics)
# docker exec mariadb-database mariadb -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "DROP DATABASE \`${V16_DB_NAME}\`;"
# echo "✓ V16 database deleted"

echo "✓ Rollback to v15 completed for ${SITE}"
```

**After Step 8:** Site is back on v15. Analyze issues and decide whether to retry or skip this site for now.

---

### 9) Success! Update migration tracker and repeat for next site

**Agent: Update the Migration Status Tracker table above with:**
- Status: ✅ Completed
- Date: Today's date
- Notes: Any issues encountered during migration

**Then ask:** Ready to migrate next site? (list remaining sites)

---

## Tips & Best Practices
- **One site at a time**: Never migrate all sites simultaneously. Allow 24 hours between migrations.
- **Keep backups**: Backups stored for 72 hours by default (check keep_backups_for_hours in site_config.json)
- **Monitor logs**: Watch v16 logs for errors during first 24 hours after cutover.
- **Database naming**: Always use format `v16_<site_name_underscored>` to keep databases organized.
- **Disable problematic apps if needed**: If `frappe/payments` or `frappe/webshop` cause issues, disable with `bench disable-module` before retrying.
- **Rollback window**: Keep v15 stack running for at least 1 week post-migration for emergency rollback.
- **Test custom workflows**: Each site has unique custom apps and workflows - test thoroughly before declaring success.
