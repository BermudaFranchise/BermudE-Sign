# BermudE-Sign Deployment Guide

## What's Included

### Branding Cleanup (30+ files)
- AGPL-3.0 license → Proprietary
- All DocuSeal, "open source", GitHub references removed
- Clean across views, JS, i18n (14 languages), docs, config

### RBAC System (6 files)
Four roles with enforced hierarchy:

| Role | Templates | Submissions | Users | Settings |
|------|-----------|-------------|-------|----------|
| **Admin** | Full CRUD | Full CRUD | Full CRUD | Full access |
| **Manager** | Full CRUD | Full CRUD | Invite & edit | Notifications, personalization |
| **Editor** | Create & edit | Full CRUD | View only | No access |
| **Viewer** | Read only | Read only | View only | No access |

- Role hierarchy enforced: managers can't promote to admin, etc.
- Color-coded badges in user list (red=admin, yellow=manager, blue=editor, gray=viewer)
- Dynamic role descriptions in user form
- First user always defaults to Admin
- Existing users auto-assigned Admin role via migration

### Files Changed for RBAC
- `app/models/user.rb` — 4 roles + helper methods
- `lib/ability.rb` — Full CanCanCan RBAC matrix
- `app/views/users/_role_select.html.erb` — Hierarchy-aware dropdown
- `app/views/users/index.html.erb` — Color-coded role badges
- `config/locales/i18n.yml` — Role translations (7 languages)
- `db/migrate/20260215120000_add_rbac_roles_to_users.rb` — Index + defaults

## Deployment Steps

```bash
# 1. Go to your cloned repo
cd ~/Documents/GitHub/BermudE-Sign

# 2. Remove all existing files (keep .git)
find . -maxdepth 1 ! -name '.git' ! -name '.' -exec rm -rf {} +

# 3. Extract the new codebase
tar xzf ~/Downloads/bermude-sign-deploy.tar.gz -C .

# 4. Commit and push
git add -A
git commit -m "SignSuite v1: branding cleanup + RBAC system"
git push origin main

# Railway will auto-deploy from the push.
# The migration runs automatically on deploy.
```

## Post-Deploy

1. Visit your BermudE-Sign URL
2. First user setup creates an Admin account
3. Go to Settings → Users to invite team members with appropriate roles
4. Verify settings pages are hidden for non-admin roles
