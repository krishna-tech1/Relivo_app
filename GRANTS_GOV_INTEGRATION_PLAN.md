# Grants.gov XML Integration - Implementation Plan

## Overview
Integration of public grant data from Grants.gov XML extract into the refugee support platform with admin verification workflow.

---

## 1. Database Schema Updates

### Updated Grant Model
```python
class Grant(Base):
    __tablename__ = "grants"
    
    # Core Fields
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False, index=True)
    organizer = Column(String, nullable=False)  # Agency name
    deadline = Column(DateTime, nullable=True)
    description = Column(String, nullable=True)
    eligibility = Column(String, nullable=True)  # Text description
    apply_url = Column(String, nullable=False)
    
    # Source & Tracking
    source = Column(String, default="manual", index=True)  # "manual" or "grants.gov"
    external_id = Column(String, unique=True, nullable=True, index=True)  # Grants.gov opportunity ID
    
    # Admin Curation
    refugee_country = Column(String, nullable=True, index=True)  # Manually assigned
    is_verified = Column(Boolean, default=False, index=True)
    is_active = Column(Boolean, default=True, index=True)
    
    # Legacy/Optional Fields
    amount = Column(String, nullable=True)
    location = Column(String, nullable=True)
    eligibility_criteria = Column(JSON, nullable=True)  # Structured list
    required_documents = Column(JSON, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
```

**Key Changes:**
- `provider` → `organizer` (consistent with requirements)
- Added `source` field to track origin
- Added `external_id` for Grants.gov opportunity ID (prevents duplicates)
- Added `is_verified` and `is_active` flags
- Added `refugee_country` for admin assignment
- Added `eligibility` as text field (parsed from XML)

---

## 2. Backend Architecture

### File Structure
```
refugee_app_backend/
├── app/
│   ├── api/
│   │   ├── grants.py (updated)
│   │   └── grants_import.py (NEW)
│   ├── services/
│   │   └── grants_gov_importer.py (NEW)
│   └── schemas/
│       └── grant.py (updated)
├── db/
│   └── models.py (updated)
└── requirements.txt (updated)
```

### New Dependencies
```txt
requests
lxml  # For XML parsing
```

---

## 3. API Endpoints

### Public Endpoints (Users)
```
GET /api/grants/public
- Returns only verified & active grants
- Query params: ?country=<refugee_country>
- No authentication required
```

### Admin Endpoints
```
GET /api/grants/admin/verified
- Returns all verified grants
- Admin auth required

GET /api/grants/admin/unverified
- Returns all unverified grants
- Admin auth required

POST /api/grants/admin/import
- Triggers Grants.gov XML import
- Admin auth required
- Returns: { imported: 10, skipped: 5, errors: [] }

PUT /api/grants/admin/{grant_id}/verify
- Sets is_verified = true
- Admin auth required

PUT /api/grants/admin/{grant_id}/unverify
- Sets is_verified = false
- Admin auth required

PUT /api/grants/admin/{grant_id}
- Update grant fields
- Admin auth required

DELETE /api/grants/admin/{grant_id}
- Delete grant
- Admin auth required
```

---

## 4. Grants.gov XML Import Service

### XML Source
**URL**: `https://www.grants.gov/xml/extract/GrantsDBExtract<YYYYMMDD>v2.zip`
- Example: `https://www.grants.gov/xml/extract/GrantsDBExtractv2.zip` (latest)
- Contains XML file with all active opportunities

### XML Structure (Key Fields)
```xml
<OpportunityForecastDetail>
    <OpportunityID>123456</OpportunityID>
    <OpportunityTitle>Grant Title</OpportunityTitle>
    <AgencyName>Department of Health</AgencyName>
    <Description>Grant description...</Description>
    <CloseDate>01/31/2026</CloseDate>
    <EligibilityCategory>Nonprofits, State Governments</EligibilityCategory>
    <AdditionalInformation>Apply at grants.gov</AdditionalInformation>
</OpportunityForecastDetail>
```

### Import Logic
1. Download ZIP file from Grants.gov
2. Extract XML file
3. Parse XML using lxml
4. For each opportunity:
   - Check if `external_id` (OpportunityID) exists
   - If exists: skip (no updates to avoid overwriting admin edits)
   - If new: create grant with:
     - `source = "grants.gov"`
     - `is_verified = false`
     - `is_active = true`
     - `refugee_country = NULL`
     - `external_id = OpportunityID`
     - `apply_url = "https://www.grants.gov/search-results-detail/{OpportunityID}"`

### Duplicate Prevention
- Use `external_id` (unique constraint)
- Skip existing records during import

---

## 5. Admin Dashboard Flow

### A. Unverified Grants Tab
**Shows**: `WHERE is_verified = false`

**Actions**:
- View grant details
- Edit all fields (title, organizer, deadline, description, eligibility, etc.)
- Assign `refugee_country` (dropdown: Germany, France, Sweden, etc.)
- Set `is_active = false` to disable
- Click "Verify" → moves to Verified tab + becomes public
- Delete grant

### B. Verified Grants Tab
**Shows**: `WHERE is_verified = true`

**Actions**:
- View grant details
- Edit fields
- Click "Unverify" → moves back to Unverified tab + hidden from public
- Set `is_active = false` to hide from public
- Delete grant

### C. Import Button
- Button: "Import from Grants.gov"
- Shows progress/spinner
- Displays result: "Imported 25 new grants, skipped 100 existing"

---

## 6. Public User Flow

### Home / Grants Page
**Query**: `WHERE is_verified = true AND is_active = true`

**Display**:
- Grant card showing: title, organizer, deadline, country (if assigned)
- "Apply" button → redirects to `apply_url`

**Filters**:
- By refugee country (if assigned)
- By deadline
- By organizer

---

## 7. Verification Logic

### When Admin Clicks "Verify"
```python
def verify_grant(grant_id: int, db: Session):
    grant = db.query(Grant).filter(Grant.id == grant_id).first()
    if not grant:
        raise HTTPException(404, "Grant not found")
    
    grant.is_verified = True
    grant.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(grant)
    return grant
```

**Result**:
- Grant appears in "Verified Grants" tab
- Grant appears on public grants page
- Grant removed from "Unverified Grants" tab

---

## 8. Implementation Steps

### Step 1: Update Database
- [ ] Update `models.py` with new Grant schema
- [ ] Create migration script
- [ ] Run migration on Neon DB

### Step 2: Update Schemas
- [ ] Update `schemas/grant.py` with new fields
- [ ] Add validation rules

### Step 3: Create Import Service
- [ ] Create `services/grants_gov_importer.py`
- [ ] Implement XML download, parse, and import logic
- [ ] Add error handling and logging

### Step 4: Update API Endpoints
- [ ] Update `api/grants.py` with new endpoints
- [ ] Create `api/grants_import.py` for import endpoint
- [ ] Add admin authentication checks

### Step 5: Update Frontend (Flutter)
- [ ] Update Grant model in Dart
- [ ] Update admin dashboard tabs
- [ ] Add import button
- [ ] Add verify/unverify buttons
- [ ] Update public grants page query

### Step 6: Testing
- [ ] Test XML import
- [ ] Test verification flow
- [ ] Test public visibility
- [ ] Test filters

---

## 9. Future AI Integration (Placeholder)

**Goal**: Auto-suggest `refugee_country` based on grant content

**Approach**:
- Add `suggested_country` field (nullable)
- AI service analyzes description/eligibility
- Populates `suggested_country`
- Admin reviews and assigns to `refugee_country`
- No schema changes needed

---

## 10. Security & Performance

### Security
- Import endpoint: Admin-only
- Verify/Unverify: Admin-only
- Public endpoint: No auth, read-only
- Input validation on all fields

### Performance
- Index on: `is_verified`, `is_active`, `source`, `refugee_country`
- Pagination on all list endpoints
- Cache public grants list (optional)

---

## 11. Error Handling

### Import Errors
- Network failure: Retry with exponential backoff
- XML parse error: Log and skip malformed records
- Database error: Rollback transaction

### Admin Errors
- Invalid country: Validate against allowed list
- Missing required fields: Return 400 with details

---

## Summary

This architecture provides:
✅ Clean separation between raw imported data and verified public data
✅ Admin curation workflow
✅ Duplicate prevention
✅ Extensible for future AI integration
✅ Simple, auditable logic
✅ Scalable for large datasets
