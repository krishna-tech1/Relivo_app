"""
Grants API Endpoints

Provides endpoints for:
- Public grant access (verified & active only)
- Admin grant management (CRUD)
- Grant verification workflow
- Grants.gov import
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from db import models
from app.schemas import grant as schemas
from app.api import deps
from db.session import get_db
from app.services.grants_gov_importer import GrantsGovImporter

router = APIRouter(
    prefix="/grants",
    tags=["grants"]
)

# ============================================================================
# PUBLIC ENDPOINTS (No Auth Required)
# ============================================================================

@router.get("/public", response_model=List[schemas.Grant])
def get_public_grants(
    skip: int = 0,
    limit: int = 100,
    country: Optional[str] = Query(None, description="Filter by refugee country"),
    db: Session = Depends(get_db)
):
    """
    Get all verified and active grants (public access).
    
    Query params:
    - country: Filter by refugee_country
    - skip: Pagination offset
    - limit: Max results
    """
    query = db.query(models.Grant).filter(
        models.Grant.is_verified == True,
        models.Grant.is_active == True
    )
    
    # Apply country filter if provided
    if country:
        query = query.filter(models.Grant.refugee_country == country)
    
    grants = query.order_by(models.Grant.deadline.asc()).offset(skip).limit(limit).all()
    return grants


# ============================================================================
# ADMIN ENDPOINTS (Auth Required)
# ============================================================================

@router.get("/admin/verified", response_model=List[schemas.Grant])
def get_verified_grants(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Get all verified grants (admin only).
    """
    grants = db.query(models.Grant).filter(
        models.Grant.is_verified == True
    ).order_by(models.Grant.created_at.desc()).offset(skip).limit(limit).all()
    return grants


@router.get("/admin/unverified", response_model=List[schemas.Grant])
def get_unverified_grants(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Get all unverified grants (admin only).
    """
    grants = db.query(models.Grant).filter(
        models.Grant.is_verified == False
    ).order_by(models.Grant.created_at.desc()).offset(skip).limit(limit).all()
    return grants


@router.get("/admin/all", response_model=List[schemas.Grant])
def get_all_grants_admin(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Get all grants regardless of verification status (admin only).
    """
    grants = db.query(models.Grant).order_by(
        models.Grant.created_at.desc()
    ).offset(skip).limit(limit).all()
    return grants


@router.post("/admin", response_model=schemas.Grant)
def create_grant(
    grant_in: schemas.GrantCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Create new grant (admin only).
    """
    grant = models.Grant(**grant_in.dict())
    db.add(grant)
    db.commit()
    db.refresh(grant)
    return grant


@router.put("/admin/{grant_id}", response_model=schemas.Grant)
def update_grant(
    grant_id: int,
    grant_in: schemas.GrantUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Update a grant (admin only).
    Supports partial updates - only provided fields are updated.
    """
    grant = db.query(models.Grant).filter(models.Grant.id == grant_id).first()
    if not grant:
        raise HTTPException(status_code=404, detail="Grant not found")
    
    # Update only provided fields
    update_data = grant_in.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(grant, field, value)
    
    db.add(grant)
    db.commit()
    db.refresh(grant)
    return grant


@router.delete("/admin/{grant_id}")
def delete_grant(
    grant_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Delete a grant (admin only).
    """
    grant = db.query(models.Grant).filter(models.Grant.id == grant_id).first()
    if not grant:
        raise HTTPException(status_code=404, detail="Grant not found")
    
    db.delete(grant)
    db.commit()
    return {"message": "Grant deleted successfully", "id": grant_id}


# ============================================================================
# VERIFICATION ENDPOINTS
# ============================================================================

@router.put("/admin/{grant_id}/verify", response_model=schemas.Grant)
def verify_grant(
    grant_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Verify a grant - makes it visible to public users.
    Sets is_verified = True.
    """
    grant = db.query(models.Grant).filter(models.Grant.id == grant_id).first()
    if not grant:
        raise HTTPException(status_code=404, detail="Grant not found")
    
    grant.is_verified = True
    db.commit()
    db.refresh(grant)
    return grant


@router.put("/admin/{grant_id}/unverify", response_model=schemas.Grant)
def unverify_grant(
    grant_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Unverify a grant - hides it from public users.
    Sets is_verified = False.
    """
    grant = db.query(models.Grant).filter(models.Grant.id == grant_id).first()
    if not grant:
        raise HTTPException(status_code=404, detail="Grant not found")
    
    grant.is_verified = False
    db.commit()
    db.refresh(grant)
    return grant


@router.put("/admin/{grant_id}/activate", response_model=schemas.Grant)
def activate_grant(
    grant_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Activate a grant.
    Sets is_active = True.
    """
    grant = db.query(models.Grant).filter(models.Grant.id == grant_id).first()
    if not grant:
        raise HTTPException(status_code=404, detail="Grant not found")
    
    grant.is_active = True
    db.commit()
    db.refresh(grant)
    return grant


@router.put("/admin/{grant_id}/deactivate", response_model=schemas.Grant)
def deactivate_grant(
    grant_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Deactivate a grant - hides it from public even if verified.
    Sets is_active = False.
    """
    grant = db.query(models.Grant).filter(models.Grant.id == grant_id).first()
    if not grant:
        raise HTTPException(status_code=404, detail="Grant not found")
    
    grant.is_active = False
    db.commit()
    db.refresh(grant)
    return grant


# ============================================================================
# GRANTS.GOV IMPORT ENDPOINT
# ============================================================================

@router.post("/admin/import", response_model=schemas.GrantImportResult)
def import_grants_from_grants_gov(
    xml_url: Optional[str] = Query(None, description="Optional custom URL for XML extract"),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Import grants from Grants.gov XML extract (admin only).
    
    Downloads the latest XML extract, parses it, and imports new grants.
    Existing grants (matched by external_id) are skipped to preserve admin edits.
    
    Returns:
        GrantImportResult with counts of imported, skipped, and errors
    """
    importer = GrantsGovImporter(db)
    result = importer.import_grants(xml_url=xml_url)
    
    return schemas.GrantImportResult(
        imported=result["imported"],
        skipped=result["skipped"],
        errors=result["errors"]
    )


# ============================================================================
# STATISTICS ENDPOINT
# ============================================================================

@router.get("/admin/stats")
def get_grant_statistics(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Get grant statistics (admin only).
    """
    total = db.query(models.Grant).count()
    verified = db.query(models.Grant).filter(models.Grant.is_verified == True).count()
    unverified = db.query(models.Grant).filter(models.Grant.is_verified == False).count()
    active = db.query(models.Grant).filter(models.Grant.is_active == True).count()
    from_grants_gov = db.query(models.Grant).filter(models.Grant.source == "grants.gov").count()
    manual = db.query(models.Grant).filter(models.Grant.source == "manual").count()
    
    return {
        "total": total,
        "verified": verified,
        "unverified": unverified,
        "active": active,
        "inactive": total - active,
        "from_grants_gov": from_grants_gov,
        "manual": manual
    }
