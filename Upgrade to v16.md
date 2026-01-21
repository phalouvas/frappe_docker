# Upgrade to v16 - Repository Branch Validation & Issues


## How to Upgrade a Site from v15 to v16 (safe, step-by-step)

### Option 2: Safe Parallel Upgrade (RECOMMENDED - Separate Databases)

This approach creates isolated v16 databases for each site, allowing parallel v15/v16 operation with zero downtime and full rollback capability.

### Preconditions
- v15 stack runs on port 8084; v16 stack on port 8085 (Traefik routing in place).
- The site's domain is routed **either** to v15 **or** to v16, never both.
- Both stacks share the **same MariaDB** instance; isolation is achieved by separate databases per version.
- You have shell access to the host running the stack (desktop-2/docker-1/etc.).

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
```bash
# Example: v15.kainotomo.com
SITE="v15.kainotomo.com"
docker exec erpnext-v15-backend-1 bench --site ${SITE} backup --with-files

# Verify backup created
docker exec erpnext-v15-backend-1 ls -lh /home/frappe/frappe-bench/sites/${SITE}/private/backups/ | tail -5
```

### 2) Create site on v16 with new database name
```bash
# Define variables
SITE="v15.kainotomo.com"
V16_DB_NAME="v16_v15_kainotomo_com"  # Format: v16_<original_site_name_underscored>

# Create site on v16 with specific database name
# bench new-site automatically creates the database
docker exec erpnext-v16-backend-1 bench new-site ${SITE} --db-name ${V16_DB_NAME}

# Verify site directory created
docker exec erpnext-v16-backend-1 ls -lh /home/frappe/frappe-bench/sites/${SITE}/site_config.json
```

### 3) Copy backup files to v16 sites directory
```bash
SITE="v15.kainotomo.com"

# Copy backup files from v15 to v16 backups folder
docker cp erpnext-v15-backend-1:/home/frappe/frappe-bench/sites/${SITE}/private/backups /tmp/backups-${SITE}
docker cp /tmp/backups-${SITE}/* erpnext-v16-backend-1:/home/frappe/frappe-bench/sites/${SITE}/private/backups/

# Verify backup in v16
docker exec erpnext-v16-backend-1 ls -lh /home/frappe/frappe-bench/sites/${SITE}/private/backups/ | tail -3
```

### 4) Adjust routing (Traefik) - move domain from v15 to v16
```bash
# Edit v15 compose: remove site domain from Host() rule
# File: ~/gitops/desktop-2/erpnext-v15.yaml
# Find line with: traefik.http.routers.erpnext-v15-https.rule
# Remove the domain from the Host() list

# Edit v16 compose: add site domain to Host() rule
# File: ~/gitops/desktop-2/erpnext-v16.yaml
# Find line with: traefik.http.routers.erpnext-v16-https.rule
# Add the domain to the Host() list

# After editing both files, apply the changes:
docker compose --project-name erpnext-v15 -f ~/gitops/desktop-2/erpnext-v15.yaml up -d
docker compose --project-name erpnext-v16 -f ~/gitops/desktop-2/erpnext-v16.yaml up -d

# Verify routing changed (wait 5-10 seconds for Traefik to reload)
sleep 10
echo "Traefik routing updated. Domain now points to v16 (port 8085)"
```

### 5) Restore database and files into v16
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

### 6) Run database migration for v16
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

### 7) Validate on v16
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

### 8) If issues → Rollback to v15
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

### 9) Repeat for each site
Cycle through steps 1–8 for each site on the migration list, adjusting variables:
- SITE variable (domain name)
- V16_DB_NAME variable (follows format: v16_<original_name_underscored>)

### Tips & Best Practices
- **One site at a time**: Never migrate all sites simultaneously. Allow 24 hours between migrations.
- **Keep backups**: Store dated backups before and after each migration attempt.
- **Monitor logs**: Watch v16 logs for errors during first 24 hours after cutover.
- **Database naming**: Always use format `v16_<site_name_underscored>` to keep databases organized and identifiable.
- **Disable problematic apps if needed**: If `frappe/payments` or `frappe/webshop` cause issues (using develop branches), disable them with `bench disable-module` before retrying.
- **Rollback window**: Keep v15 stack running for at least 1 week post-migration for emergency rollback.
- **Test custom workflows**: Each site has unique custom apps and workflows - test thoroughly before considering migration complete.
