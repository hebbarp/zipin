# Deployment Guide

## Environment Setup

We use a two-stage deployment process:

### 1. Staging Environment
- **Branch**: `develop`
- **App Name**: `zipin-staging` 
- **Database**: `zipin-staging-db`
- **URL**: Will be assigned by DigitalOcean (e.g., `zipin-staging-xyz.ondigitalocean.app`)
- **Auto-deploy**: Enabled on push to `develop` branch

### 2. Production Environment  
- **Branch**: `main`
- **App Name**: `zipin-production`
- **Database**: `zipin-production-db` 
- **URL**: https://zipin.app (custom domain)
- **Auto-deploy**: Disabled (manual deployments only)

## Workflow

### For Development & Testing:
1. Work on feature branches
2. Merge to `develop` branch
3. Push to trigger staging deployment
4. Test thoroughly on staging
5. Once approved, merge `develop` to `main`
6. Manually deploy to production

### Commands:

```bash
# Push to staging
git checkout develop
git push origin develop

# Deploy to production (after staging approval)
git checkout main  
git merge develop
git push origin main
# Then manually trigger production deployment in DigitalOcean
```

## Creating the Apps

You'll need to create both apps in DigitalOcean:

1. **Staging App**: Use `.do/staging-app.yaml`
2. **Production App**: Use `.do/app.yaml` 

## Environment Variables

Both apps need these secrets (with different values):
- `PHX_HOST` (staging-app.com vs zipin.app)
- `SECRET_KEY_BASE` (generate separate keys)
- `DATABASE_URL` (automatically set by DO databases)