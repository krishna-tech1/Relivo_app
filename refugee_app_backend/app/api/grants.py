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

from datetime import datetime
from sqlalchemy import or_

@router.get("/public", response_model=List[schemas.Grant])
def get_public_grants(
    skip: int = 0,
    limit: int = 100,
    country: Optional[str] = Query(None, description="Filter by refugee country"),
    db: Session = Depends(get_db)
):
    """
    Get all verified and active grants (public access).
    Excludes grants that have passed their deadline.
    
    Query params:
    - country: Filter by refugee_country
    - skip: Pagination offset
    - limit: Max results
    """
    now = datetime.now()
    
    query = db.query(models.Grant).filter(
        models.Grant.is_verified == True,
        models.Grant.is_active == True,
        or_(
            models.Grant.deadline >= now,
            models.Grant.deadline == None
        )
    )
    
    # Apply country filter if provided
    if country:
        query = query.filter(models.Grant.refugee_country == country)
    
    grants = query.order_by(models.Grant.deadline.asc()).offset(skip).limit(limit).all()
    return grants



# ============================================================================
# USER / ORG ENDPOINTS (Auth Required)
# ============================================================================

@router.post("/submit", response_model=schemas.Grant)
def submit_grant(
    grant_in: schemas.GrantCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    """
    Submit a grant. 
    - Normal Users: Created as unverified (pending review).
    - Approved Organizations: Created as verified (trusted).
    """
    grant_data = grant_in.dict()
    
    # Defaults
    grant_data['creator_id'] = current_user.id
    grant_data['is_verified'] = False 
    grant_data['is_active'] = True

    # Check for Organization Role
    if current_user.role == 'organization':
        org = db.query(models.Organization).filter(models.Organization.user_id == current_user.id).first()
        if org:
            grant_data['organization_id'] = org.id
            if org.status == 'approved':
                grant_data['is_verified'] = True # Trusted Org Auto-Verify

    grant = models.Grant(**grant_data)
    db.add(grant)
    db.commit()
    db.refresh(grant)
    return grant


@router.get("/my-submissions", response_model=List[schemas.Grant])
def get_my_submissions(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    """
    Get grants submitted by the current user.
    """
    grants = db.query(models.Grant).filter(
        models.Grant.creator_id == current_user.id
    ).order_by(models.Grant.created_at.desc()).offset(skip).limit(limit).all()
    return grants


@router.put("/my-submissions/{grant_id}", response_model=schemas.Grant)
def update_my_submission(
    grant_id: int,
    grant_in: schemas.GrantUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    """
    Update own submission. 
    Allowed only if grant is NOT verified (unless trusted org).
    """
    grant = db.query(models.Grant).filter(
        models.Grant.id == grant_id,
        models.Grant.creator_id == current_user.id
    ).first()
    
    if not grant:
        raise HTTPException(status_code=404, detail="Grant not found or access denied")
    
    # If already verified, restrict editing for normal users? 
    # Requirement: "Edit or delete their submitted grants before verification"
    # If verified, maybe allow editing but reset to unverified?
    # For now, strictly follow requirement: "before verification".
    if grant.is_verified:
        # Check if trusted org
        is_trusted_org = False
        if current_user.role == 'organization':
             org = db.query(models.Organization).filter(models.Organization.user_id == current_user.id).first()
             if org and org.status == 'approved':
                 is_trusted_org = True
        
        if not is_trusted_org:
            raise HTTPException(status_code=403, detail="Cannot edit verified grants. Contact admin.")

    # Apply updates
    update_data = grant_in.dict(exclude_unset=True)
    # Security: Prevent user from setting is_verified to True
    if 'is_verified' in update_data:
        del update_data['is_verified'] # Ignore attempts to verify logic here
        
    for field, value in update_data.items():
        setattr(grant, field, value)
    
    db.add(grant)
    db.commit()
    db.refresh(grant)
    return grant


@router.delete("/my-submissions/{grant_id}")
def delete_my_submission(
    grant_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    """
    Delete own submission.
    """
    grant = db.query(models.Grant).filter(
        models.Grant.id == grant_id,
        models.Grant.creator_id == current_user.id
    ).first()
    
    if not grant:
        raise HTTPException(status_code=404, detail="Grant not found or access denied")
    
    if grant.is_verified:
         # Same rule: "before verification". 
         # But usually deletion is allowed? 
         # "Edit or delete their submitted grants before verification" imply restriction.
         pass # Let's allow deletion or restrict? 
         # I'll restrict to be safe per requirements.
         is_trusted_org = False
         if current_user.role == 'organization':
             org = db.query(models.Organization).filter(models.Organization.user_id == current_user.id).first()
             if org and org.status == 'approved':
                 is_trusted_org = True
         
         if not is_trusted_org:
             raise HTTPException(status_code=403, detail="Cannot delete verified grants. Contact admin.")

    db.delete(grant)
    db.commit()
    return {"message": "Grant deleted successfully", "id": grant_id}


# ============================================================================


# ============================================================================
# ADMIN ENDPOINTS - MOVED TO ADMIN BACKEND
# ============================================================================

