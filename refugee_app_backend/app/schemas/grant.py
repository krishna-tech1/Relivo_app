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
