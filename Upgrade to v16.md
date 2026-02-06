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
| cyprussportsfever.com | v16_sports | ⬜ Not Started | - | |
| kainotomo.com | v16_kainotomo | ⬜ Not Started | - | |
| erp.detima.com | v16_detima | ✅ Completed | 2026-02-06 | Cutover complete, validation passed |
| gpapachristodoulou.com | v6_gpapa | ✅ Completed | 2026-01-26 | Successfully migrated with preserved DB credentials |
| mozsportstech.com | v16_mozsports | ✅ Completed | 2026-01-26 | Successfully migrated with preserved DB credentials |
| pakore6.kainotomo.com | v16_pakore6 | ✅ Completed | 2026-01-26 | Successfully migrated with preserved DB credentials |
| app.swissmedhealth.com | v16_swissmed | ❌ Rollback | 2026-02-01 | Data migration successful, domain routed back to v15. Issue: Web forms failing on v16 - requires investigation |
| cpl.kainotomo.com | v16_cpl | ✅ Completed | 2026-02-06 | Successfully migrated with preserved DB credentials and files. Domain routed to v16 |
| eumariaphysio.com | v16_eumariaphysio | ✅ Completed | 2026-02-03 | Successfully migrated with preserved DB credentials and files. Domain routed to v16 |

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

### Check 3: Verify kainotomo.com is currently on v15 (not v16)
```bash
grep -A 5 "traefik.http.routers.erpnext-v15-https.rule" ~/gitops/desktop-2/erpnext-v15.yaml | grep kainotomo
```
**Expected:** `kainotomo.com` appears in v15 Host() list

```bash
grep "traefik.http.routers.erpnext-v16-https.rule" ~/gitops/desktop-2/erpnext-v16.yaml
```
**Expected:** kainotomo.com is NOT in v16 Host() list (or only Host(`kainotomo.com`) if pre-configured)

### Check 4: Verify both stacks use same MariaDB
```bash
docker exec erpnext-v15-backend-1 cat /home/frappe/frappe-bench/sites/kainotomo.com/site_config.json | grep db_host
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
| kainotomo.com routed to v15 | ✅/❌ | Domain on v15 not v16 | |
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
- kainotomo.com → v16_kainotomo_com
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
# Example: kainotomo.com
SITE="kainotomo.com"
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
SITE="pakore6.kainotomo.com"
V16_DB_NAME="v16_pakore6"  # Format: v16_<database_name>

# Create site on v16 with specific database name
# bench new-site automatically creates the database
docker exec erpnext-v16-backend-1 bench new-site ${SITE} --db-name ${V16_DB_NAME}

# Verify site directory created
docker exec erpnext-v16-backend-1 ls -lh /home/frappe/frappe-bench/sites/${SITE}/site_config.json
```

**After Step 2:** Verify site_config.json exists. User confirms to proceed to Step 3.

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
SITE="pakore6.kainotomo.com"

# Copy backup files from v15 to v16 backups folder
docker cp erpnext-v15-backend-1:/home/frappe/frappe-bench/sites/${SITE}/private/backups /tmp/backups-${SITE}
docker cp /tmp/backups-${SITE}/* erpnext-v16-backend-1:/home/frappe/frappe-bench/sites/${SITE}/private/backups/

# Also copy the original v15 site_config.json for preservation (will update db_name in Step 5)
docker cp erpnext-v15-backend-1:/home/frappe/frappe-bench/sites/${SITE}/site_config.json /tmp/v15-site_config-${SITE}.json

# Verify backup in v16
docker exec erpnext-v16-backend-1 ls -lh /home/frappe/frappe-bench/sites/${SITE}/private/backups/ | tail -3
```

**After Step 3:** Verify backup files copied to v16. Domain still on v15. User confirms to proceed to Step 4.

---

### 4) Restore database and update site_config with v16 database credentials

**⚠️ CRITICAL ISSUE: Database Password Mismatch Prevention**

When we created the v16 site in Step 2, `bench new-site` automatically generated a database user `v16_pakore6` with a random password. However, the v15 backup's site_config.json contains the OLD v15 database password. **These passwords DO NOT match**, which will cause database connection errors after restore.

**Solution:**
1. **BEFORE restore:** Capture the auto-generated v16_pakore6 password from the fresh site_config.json
2. **AFTER restore:** Update the restored site_config.json to use the v16 database password (not the v15 password)

**What this step does:**
- Captures v16_pakore6 database password (auto-generated in Step 2)
- Reads v15 backup SQL file
- Imports all v15 data into v16 database
- Restores site_config.json with all original encryption keys and custom settings
- Restores file attachments to correct locations
- Updates database name from `pakore6` to `v16_pakore6`
- **CRITICAL:** Updates database password to match the v16 database user
- ~5-10 minutes depending on data size

**Risk:** Low - if fails, domain stays on v15, can retry (no user impact)
**Mitigation:** Domain still on v15 means users unaffected if this step fails

**Agent: Explain this step and wait for user approval before running.**

```bash
SITE="pakore6.kainotomo.com"
V15_DB_NAME="pakore6"  # Original v15 database name (simpler than pakore6_kainotomo_com)
V16_DB_NAME="v16_pakore6"  # New v16 database name
BACKUP_FILE="/home/frappe/frappe-bench/sites/${SITE}/private/backups/20260126_103859-pakore6_kainotomo_com-database.sql.gz"
DB_ROOT_PASSWORD="pRep5v3Nzw_aMMV"

# STEP 1: Capture v16 database password BEFORE restore
echo "Step 1: Capturing v16 database password..."
V16_DB_PASSWORD=$(docker exec erpnext-v16-backend-1 cat /home/frappe/frappe-bench/sites/${SITE}/site_config.json | grep '"db_password"' | cut -d'"' -f4)
echo "✓ Captured v16_pakore6 password: ${V16_DB_PASSWORD}"

# STEP 2: Restore v15 backup to v16
echo ""
echo "Step 2: Restoring v15 backup to v16 database..."
docker exec -e MYSQL_PWD="${DB_ROOT_PASSWORD}" erpnext-v16-backend-1 bash -lc \
  "bench --site ${SITE} restore ${BACKUP_FILE} --mariadb-root-password ${DB_ROOT_PASSWORD}"

# STEP 3: Update site_config.json with v16 database name AND password
echo ""
echo "Step 3: Updating site_config.json with v16 credentials..."
docker exec erpnext-v16-backend-1 bash -lc \
  "cd /home/frappe/frappe-bench && python -c \"import json; config = json.load(open('sites/${SITE}/site_config.json')); config['db_name'] = '${V16_DB_NAME}'; config['db_password'] = '${V16_DB_PASSWORD}'; json.dump(config, open('sites/${SITE}/site_config.json', 'w'), indent=1)\""

# STEP 4: Verify restore completed with correct credentials
echo ""
echo "Step 4: Verifying restore and credentials..."
docker exec erpnext-v16-backend-1 cat /home/frappe/frappe-bench/sites/${SITE}/site_config.json | grep -E '"db_name"|"db_password"'

echo ""
echo "✓ Restore completed with correct v16 credentials!"
```

**After Step 4:** 
- ✅ Verify restore completed
- ✅ Verify db_name shows `"db_name": "v16_pakore6"`
- ✅ Verify db_password matches the captured v16_pakore6 password
- Domain still on v15
- User confirms to proceed to Step 5

---

### 5) Run database migration for v16

**What this step does:**
- Upgrades database schema from v15 format to v16 format
- Runs all pending migrations
- Updates document types, fields, etc.
- Clears all caches (Redis)
- **CRITICAL:** Makes data compatible with v16 code
- Domain still routes to v15 (no downtime yet)
- ~5-15 minutes depending on data complexity

**Risk:** Low - if migration fails, domain stays on v15, can retry
**Mitigation:** Domain still on v15 means users unaffected if this step fails

**Agent: Warn user about risk and wait for approval before running.**

```bash
SITE="kainotomo.com"

# Run migrate to upgrade database schema for v16
echo "Running migration on ${SITE}..."
docker exec erpnext-v16-backend-1 bench --site ${SITE} migrate

# Clear all caches
docker exec erpnext-v16-backend-1 bench --site ${SITE} clear-cache
docker exec erpnext-v16-backend-1 bench --site ${SITE} clear-website-cache

echo "Migration and cache clear completed for ${SITE}"
```

**After Step 5:** Watch for any errors in console output. Domain still on v15. User confirms to proceed to Step 6.

---

### 6) Validate v16 is fully functional

**What this step does:**
- Checks v16 logs for errors
- Tests basic CLI commands (lists users)
- User performs manual browser tests on direct v16 port (8085)
- Verifies custom apps work
- **NO CHANGES** - just checking everything works
- Domain still routes to v15 (safe to test)

```bash
SITE="kainotomo.com"

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

**Manual validation checklist (test on v16 port 8085 - domain still on v15):**
- [ ] Visit `http://localhost:8085` and test site (or via `:8085/app/...` URL)
- [ ] Login works with valid credentials
- [ ] Desk/UI loads without errors
- [ ] Core doctypes visible (Invoice, Purchase Order, etc.)
- [ ] Custom apps appear in modules list
- [ ] Test critical site-specific workflows
- [ ] Check file attachments and downloads work
- [ ] Test email/notification sending (if applicable)

**IMPORTANT:** You're testing on port 8085 (direct v16 access). The domain still points to v15!

**After Step 6:** User confirms all tests pass or reports issues. If all tests pass, proceed to Step 7 (Cutover). If issues, proceed to Step 10 (Rollback).

---

### 7) Adjust routing (Traefik) - move domain from v15 to v16 - **FINAL CUTOVER**

**What this step does:**
- **THIS IS THE ONLY TIME USERS EXPERIENCE DOWNTIME**
- Removes domain from v15's Traefik routing rules
- Adds domain to v16's Traefik routing rules
- Traefik reloads config and routes domain to v16 port (8085)
- After this: site is NO LONGER accessible on v15
- After this: domain now serves v16 (fully tested and ready)
- ~30 seconds total downtime (routing change + Traefik reload)

**⚠️ CRITICAL:** This is the final cutover. **Only proceed if Step 6 validation passed completely.** If there were any issues, do NOT proceed - go to Step 10 (Rollback) instead.

**Agent: Provide exact instructions for manual edits and wait for user confirmation.**

**File 1: Edit** `~/gitops/desktop-2/erpnext-v15.yaml`
```
Find this line with your domain (kainotomo.com):
  traefik.http.routers.erpnext-v15-https.rule: Host(`cyprussportsfever.com`,`kainotomo.com`,`erp.detima.com`,`gpapachristodoulou.com`,`mozsportstech.com`,`pakore6.kainotomo.com`,`app.swissmedhealth.com`,`cpl.kainotomo.com`,`eumariaphysio.com`)

Remove `kainotomo.com` from the list
```

**File 2: Edit** `~/gitops/desktop-2/erpnext-v16.yaml`
```
Find this line:
  traefik.http.routers.erpnext-v16-https.rule: Host(`kainotomo.com`)

Add your site if not already there. Example:
  traefik.http.routers.erpnext-v16-https.rule: Host(`kainotomo.com`,`new-site.com`)
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

**After Step 7:** Domain now points to v16. Cutover complete. User confirms to proceed to Step 8 (Enable Scheduler).

---

### 8) Enable Scheduler

**What this step does:**
- Enables the background scheduler for the site
- Scheduler runs automated tasks (emails, reports, background jobs)
- By default, scheduler is disabled after migration
- **CRITICAL:** Without this, automated tasks won't run
- ~5 seconds

**Risk:** None - just enables background jobs

**Agent: Explain this step and wait for user approval before running.**

```bash
SITE="pakore6.kainotomo.com"

# Enable scheduler
echo "Enabling scheduler for ${SITE}..."
docker exec erpnext-v16-backend-1 bench --site ${SITE} scheduler enable

# Verify scheduler is enabled
docker exec erpnext-v16-backend-1 bench --site ${SITE} scheduler status

echo "✓ Scheduler enabled for ${SITE}"
```

**After Step 8:** Verify scheduler shows as "enabled". User confirms to proceed to Step 9.

---

### 9) Cleanup v15 Site (Optional - Recommended after 1-7 days)

**What this step does:**
- Removes the site directory from v15 stack
- Drops the old v15 database from MariaDB
- Automatically archives site backup to `/archived/sites`
- Frees up disk space
- Prevents confusion about which version is active
- ⚠️ **IRREVERSIBLE** - Only do this after confirming v16 works perfectly

**Risk:** High if done prematurely - cannot easily rollback after cleanup
**Mitigation:** Wait 1-7 days after migration, ensure backups exist, test thoroughly

**Agent: ONLY proceed with this step if:**
- User explicitly requests cleanup
- Migration completed successfully (Step 8 passed)
- Site has been running on v16 for at least 24 hours
- User confirms site is working perfectly on v16

```bash
SITE="kainotomo.com"

echo "⚠️ WARNING: This will permanently delete the v15 site and database!"
echo "Site: ${SITE}"
echo ""
echo "Before proceeding, confirm:"
echo "1. Site has been running successfully on v16 for at least 24 hours"
echo "2. You have tested all critical workflows on v16"
echo "3. You will NOT need to rollback to v15"
echo ""
read -p "Type 'DELETE' to confirm cleanup (Ctrl+C to cancel): " CONFIRM

if [ "$CONFIRM" != "DELETE" ]; then
  echo "Cleanup cancelled."
  exit 1
fi

echo "Starting cleanup process..."

# Single command that handles everything:
# - Creates final backup
# - Drops database and user
# - Archives site directory
echo "Removing v15 site: ${SITE}..."
echo "${MYSQL_ROOT_PASSWORD:-pRep5v3Nzw_aMMV}" | docker exec -i erpnext-v15-backend-1 bench drop-site ${SITE}
echo "✓ Site cleanup completed - archived to /home/frappe/frappe-bench/archived/sites"

echo ""
echo "✅ Cleanup completed for ${SITE}"
echo "v15 site and database have been permanently removed."
echo "Final backup archived in v15 container."
echo "Site continues running on v16 only."
```

**Important Notes:**
- **DO NOT run this step immediately after migration**
- Recommended wait time: 1-7 days depending on site criticality
- Keep v15 stack running for at least 1 week for emergency rollback capability
- Final backup is automatically created and archived
- Use `bench drop-site` which handles database, files, and cleanup automatically

**After Step 9:** Site cleanup complete. v15 resources freed. Site runs exclusively on v16.

---

### 10) If issues in Step 6 → Emergency Rollback to v15

**What this step does:**
- Reverts routing back to v15
- Optionally restores v15 database if needed
- Optionally cleans up v16 database
- Site returns to v15, no data loss

**Risk:** None - reverses changes

**Agent: Only offer rollback if user reports issues in Step 6 BEFORE proceeding to Step 7.**

```bash
SITE="kainotomo.com"
V16_DB_NAME="v16_kainotomo_com"
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

**After Step 10:** Site is back on v15. Analyze issues and decide whether to retry or skip this site for now.

---

### 11) Success! Update migration tracker and repeat for next site

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
