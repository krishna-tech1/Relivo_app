# Grants.gov Integration Guide

## Overview
This integration allows importing public grant data from Grants.gov XML extract into your refugee support platform with an admin verification workflow.

---

## 🚀 Quick Start

### 1. Install Dependencies
```bash
cd refugee_app_backend
pip install -r requirements.txt
```

### 2. Run Database Migration
```bash
python migrate_grants_schema.py
```
Type `yes` when prompted to update the database schema.

### 3. Start the Backend
```bash
uvicorn app.main:app --reload
```

### 4. Import Grants (via API or Admin Dashboard)

**Option A: Using API (cURL)**
```bash
curl -X POST "http://localhost:8000/api/grants/admin/import" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

**Option B: Using Admin Dashboard**
- Login as admin
- Click "Import from Grants.gov" button
- Wait for import to complete

---

## 📊 API Endpoints

### Public Endpoints (No Auth)

#### Get Public Grants
```http
GET /api/grants/public?country=Germany&skip=0&limit=100
```
Returns only verified & active grants.

**Query Parameters:**
- `country` (optional): Filter by refugee country
- `skip`: Pagination offset
- `limit`: Max results

---

### Admin Endpoints (Auth Required)

#### Get Verified Grants
```http
GET /api/grants/admin/verified
```

#### Get Unverified Grants
```http
GET /api/grants/admin/unverified
```

#### Get All Grants
```http
GET /api/grants/admin/all
```

#### Create Grant
```http
POST /api/grants/admin
Content-Type: application/json

{
  "title": "Emergency Housing Grant",
  "organizer": "UN Refugee Agency",
  "description": "Financial assistance for housing",
  "eligibility": "Valid refugee status required",
  "deadline": "2026-03-31T00:00:00",
  "apply_url": "https://example.com/apply",
  "refugee_country": "Germany",
  "is_verified": false,
  "is_active": true,
  "source": "manual"
}
```

#### Update Grant
```http
PUT /api/grants/admin/{grant_id}
Content-Type: application/json

{
  "refugee_country": "France",
  "is_verified": true
}
```
Supports partial updates - only send fields you want to change.

#### Delete Grant
```http
DELETE /api/grants/admin/{grant_id}
```

#### Verify Grant
```http
PUT /api/grants/admin/{grant_id}/verify
```
Makes grant visible to public users.

#### Unverify Grant
```http
PUT /api/grants/admin/{grant_id}/unverify
```
Hides grant from public users.

#### Activate/Deactivate Grant
```http
PUT /api/grants/admin/{grant_id}/activate
PUT /api/grants/admin/{grant_id}/deactivate
```

#### Import from Grants.gov
```http
POST /api/grants/admin/import
```
Downloads and imports grants from Grants.gov XML extract.

**Response:**
```json
{
  "imported": 150,
  "skipped": 50,
  "errors": []
}
```

#### Get Statistics
```http
GET /api/grants/admin/stats
```

**Response:**
```json
{
  "total": 200,
  "verified": 100,
  "unverified": 100,
  "active": 190,
  "inactive": 10,
  "from_grants_gov": 150,
  "manual": 50
}
```

---

## 🔄 Admin Workflow

### Importing Grants

1. **Click "Import from Grants.gov"** in admin dashboard
2. System downloads latest XML extract
3. Parses XML and extracts grant data
4. Creates new grants with:
   - `is_verified = false`
   - `is_active = true`
   - `refugee_country = NULL`
   - `source = "grants.gov"`
5. Skips existing grants (matched by `external_id`)

### Verifying Grants

**Unverified Grants Tab:**
1. Review grant details
2. Edit fields as needed:
   - Title, description, eligibility
   - Deadline
   - Assign refugee country
3. Click **"Verify"** button
4. Grant moves to "Verified Grants" tab
5. Grant becomes visible to public users

**Verified Grants Tab:**
- View all verified grants
- Edit details if needed
- Click **"Unverify"** to move back to unverified
- Click **"Deactivate"** to hide from public without unverifying

---

## 🗄️ Database Schema

### Grant Model Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | Integer | Primary key |
| `title` | String | Grant title (required) |
| `organizer` | String | Agency/organization name (required) |
| `description` | String | Grant description |
| `eligibility` | String | Eligibility requirements |
| `deadline` | DateTime | Application deadline |
| `apply_url` | String | Application URL (required) |
| `source` | String | "manual" or "grants.gov" |
| `external_id` | String | Grants.gov opportunity ID (unique) |
| `refugee_country` | String | Admin-assigned country |
| `is_verified` | Boolean | Verification status |
| `is_active` | Boolean | Active/disabled status |
| `amount` | String | Grant amount |
| `location` | String | Geographic location |
| `eligibility_criteria` | JSON | Structured eligibility list |
| `required_documents` | JSON | Required documents list |
| `created_at` | DateTime | Creation timestamp |
| `updated_at` | DateTime | Last update timestamp |

---

## 🔍 How It Works

### Grants.gov XML Source

**URL:** `https://www.grants.gov/xml/extract/GrantsDBExtractv2.zip`

The system:
1. Downloads ZIP file
2. Extracts XML file
3. Parses opportunities using XML parser
4. Maps XML fields to database fields:
   - `OpportunityID` → `external_id`
   - `OpportunityTitle` → `title`
   - `AgencyName` → `organizer`
   - `Description` → `description`
   - `CloseDate` → `deadline`
   - `EligibilityCategory` → `eligibility`

### Duplicate Prevention

- Uses `external_id` (Grants.gov opportunity ID)
- Database constraint: `UNIQUE` on `external_id`
- Import skips existing records
- Preserves admin edits

### Verification Flow

```
┌─────────────────────┐
│  Import from        │
│  Grants.gov         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Unverified Grants  │
│  is_verified=false  │
│  refugee_country=   │
│  NULL               │
└──────────┬──────────┘
           │
           │ Admin reviews & edits
           │ Assigns refugee_country
           │ Clicks "Verify"
           ▼
┌─────────────────────┐
│  Verified Grants    │
│  is_verified=true   │
│  refugee_country=   │
│  Germany            │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Public Grants Page │
│  (Users can see)    │
└─────────────────────┘
```

---

## 🎯 Public User Experience

### What Users See
- Only grants where `is_verified = true` AND `is_active = true`
- Can filter by `refugee_country`
- Can sort by deadline
- "Apply" button redirects to `apply_url`

### What Users Don't See
- Unverified grants
- Inactive grants
- Admin-only fields (source, external_id)

---

## 🔐 Security

- Import endpoint: **Admin-only**
- Verify/Unverify: **Admin-only**
- CRUD operations: **Admin-only**
- Public endpoint: **Read-only, no auth**
- Input validation on all fields
- SQL injection protection via SQLAlchemy ORM

---

## 🧪 Testing

### Test Import Locally
```python
from app.services.grants_gov_importer import GrantsGovImporter
from db.session import SessionLocal

db = SessionLocal()
importer = GrantsGovImporter(db)
result = importer.import_grants()
print(f"Imported: {result['imported']}, Skipped: {result['skipped']}")
```

### Test Verification Flow
1. Import grants
2. Check unverified count: `GET /api/grants/admin/unverified`
3. Verify a grant: `PUT /api/grants/admin/{id}/verify`
4. Check public grants: `GET /api/grants/public`
5. Confirm grant appears

---

## 🚨 Troubleshooting

### Import Fails
- **Check internet connection** - needs to download from Grants.gov
- **Check XML URL** - may change over time
- **Check logs** - errors are returned in response

### Grants Not Appearing Publicly
- Verify `is_verified = true`
- Verify `is_active = true`
- Check filters (country, etc.)

### Duplicate Grants
- Should not happen due to `external_id` constraint
- If manual grants conflict, they'll have different IDs

---

## 🔮 Future Enhancements

### AI Country Suggestion
Add `suggested_country` field populated by AI analysis:
```python
# Analyze grant description/eligibility
suggested_country = ai_service.suggest_country(grant.description)
grant.suggested_country = suggested_country
# Admin reviews and assigns to refugee_country
```

### Scheduled Imports
Set up cron job to import daily:
```bash
0 2 * * * curl -X POST http://localhost:8000/api/grants/admin/import \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### Email Notifications
Notify admins when new grants are imported:
```python
if result['imported'] > 0:
    send_email(admin_email, f"{result['imported']} new grants imported")
```

---

## 📝 Summary

✅ **Clean separation** between raw imported data and verified public data  
✅ **Admin curation** workflow before public visibility  
✅ **Duplicate prevention** via external_id  
✅ **Extensible** for future AI integration  
✅ **Simple, auditable** logic  
✅ **Scalable** for large datasets  

---

## 📞 Support

For issues or questions:
1. Check this README
2. Review implementation plan: `GRANTS_GOV_INTEGRATION_PLAN.md`
3. Check API documentation: `http://localhost:8000/docs`
