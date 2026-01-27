# Quick Fix: Health Check Endpoint

## Issue
The `/health` endpoint was returning an error:
```json
{
  "status": "unhealthy",
  "database": "disconnected",
  "error": "Textual SQL expression 'SELECT 1' should be explicitly declared as text('SELECT 1')"
}
```

## Root Cause
SQLAlchemy 2.0+ requires raw SQL queries to be wrapped in `text()` function for safety.

## Fix Applied
Updated `app/main.py` health check endpoint:

**Before:**
```python
db.execute("SELECT 1")
```

**After:**
```python
from sqlalchemy import text
db.execute(text("SELECT 1"))
```

## Deployment Steps

### Option 1: Auto-Deploy (If GitHub is connected)
1. Commit and push changes:
   ```bash
   cd refugee_app_backend
   git add app/main.py
   git commit -m "Fix: Health check endpoint SQLAlchemy 2.0 compatibility"
   git push origin main
   ```
2. Render will auto-deploy
3. Wait 2-3 minutes for deployment
4. Test: `curl https://relivo-app.onrender.com/health`

### Option 2: Manual Deploy on Render
1. Go to Render Dashboard
2. Select your backend service
3. Click "Manual Deploy" → "Deploy latest commit"
4. Wait for deployment to complete
5. Test: `curl https://relivo-app.onrender.com/health`

## Expected Result
After deployment, the health check should return:
```json
{
  "status": "healthy",
  "database": "connected"
}
```

## Testing

### Test Health Endpoint:
```bash
curl https://relivo-app.onrender.com/health
```

### Test Root Endpoint:
```bash
curl https://relivo-app.onrender.com/
```

### Test Grants Endpoint:
```bash
curl https://relivo-app.onrender.com/grants/public
```

## Status
✅ **FIXED** - Code updated, ready for deployment

---
**Date:** 2026-01-27
**Priority:** HIGH - Required for production health checks
