from sqlalchemy import Column, Integer, String, Boolean, DateTime, JSON
from sqlalchemy.sql import func
from .session import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    role = Column(String, default="user")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class VerificationCode(Base):
    __tablename__ = "verification_codes"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, index=True)
    code = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class Grant(Base):
    __tablename__ = "grants"

    # Core Fields
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True, nullable=False)
    organizer = Column(String, nullable=False)  # Agency/Organization name (renamed from provider)
    deadline = Column(DateTime, nullable=True)
    description = Column(String, nullable=True)
    eligibility = Column(String, nullable=True)  # Text description of eligibility
    apply_url = Column(String, nullable=False)
    
    # Source & Tracking
    source = Column(String, default="manual", index=True)  # "manual" or "grants.gov"
    external_id = Column(String, unique=True, nullable=True, index=True)  # Grants.gov opportunity ID for deduplication
    
    # Admin Curation Fields
    refugee_country = Column(String, nullable=True, index=True)  # Manually assigned by admin
    is_verified = Column(Boolean, default=False, index=True)  # Admin verification status
    is_active = Column(Boolean, default=True, index=True)  # Active/disabled status
    
    # Legacy/Optional Fields (for backward compatibility)
    amount = Column(String, nullable=True)  # Grant amount as string
    location = Column(String, nullable=True)  # Geographic location
    eligibility_criteria = Column(JSON, nullable=True)  # Structured eligibility list
    required_documents = Column(JSON, nullable=True)  # Required documents list
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
