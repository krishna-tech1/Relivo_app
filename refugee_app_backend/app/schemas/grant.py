from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class GrantBase(BaseModel):
    title: str
    provider: str
    description: Optional[str] = None
    amount: Optional[str] = None
    deadline: Optional[datetime] = None
    location: Optional[str] = None
    apply_url: Optional[str] = None
    eligibility_criteria: Optional[list[str]] = []
    required_documents: Optional[list[str]] = []

class GrantCreate(GrantBase):
    pass

class GrantUpdate(GrantBase):
    pass

class Grant(GrantBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
