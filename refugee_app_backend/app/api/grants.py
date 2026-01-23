from typing import List, Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from db import models
from app.schemas import grant as schemas
from app.api import deps
from db.session import get_db

router = APIRouter(
    prefix="/grants",
    tags=["grants"]
)

@router.get("/", response_model=List[schemas.Grant])
def read_grants(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_active_user)
):
    """
    Retrieve grants.
    """
    grants = db.query(models.Grant).offset(skip).limit(limit).all()
    return grants

@router.post("/", response_model=schemas.Grant)
def create_grant(
    grant_in: schemas.GrantCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Create new grant (Admin only).
    """
    grant = models.Grant(**grant_in.dict())
    db.add(grant)
    db.commit()
    db.refresh(grant)
    return grant

@router.put("/{grant_id}", response_model=schemas.Grant)
def update_grant(
    grant_id: int,
    grant_in: schemas.GrantUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Update a grant (Admin only).
    """
    grant = db.query(models.Grant).filter(models.Grant.id == grant_id).first()
    if not grant:
        raise HTTPException(status_code=404, detail="Grant not found")
        
    for field, value in grant_in.dict(exclude_unset=True).items():
        setattr(grant, field, value)
        
    db.add(grant)
    db.commit()
    db.refresh(grant)
    return grant

@router.delete("/{grant_id}", response_model=Any)
def delete_grant(
    grant_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Delete a grant (Admin only).
    """
    grant = db.query(models.Grant).filter(models.Grant.id == grant_id).first()
    if not grant:
        raise HTTPException(status_code=404, detail="Grant not found")
        
    db.delete(grant)
    db.commit()
    return {"message": "Grant deleted successfully"}
