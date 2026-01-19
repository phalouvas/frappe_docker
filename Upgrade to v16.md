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
