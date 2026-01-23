from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
import random
import string
from typing import Any

from db.session import get_db
from db import models
from app.core import security
from app.api import deps
from app.schemas import user as schemas
from app.core.email_utils import send_verification_email
from pydantic import BaseModel, EmailStr

router = APIRouter(
    prefix="/auth",
    tags=["auth"]
)

def generate_verification_code():
    return ''.join(random.choices(string.digits, k=6))

@router.post("/register", response_model=Any)
def register(
    user_in: schemas.UserCreate, 
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """
    Register a new user.
    """
    try:
        # Check if user already exists
        user = db.query(models.User).filter(models.User.email == user_in.email).first()
        if user:
            raise HTTPException(status_code=400, detail="Email already registered")
        
        # Create user
        db_user = models.User(
            email=user_in.email,
            hashed_password=security.get_password_hash(user_in.password),
            full_name=user_in.full_name,
            role=user_in.role, 
            is_verified=False
        )
        db.add(db_user)
        
        # Create verification code
        code = generate_verification_code()
        db_code = models.VerificationCode(email=user_in.email, code=code)
        db.add(db_code)
        
        db.commit()
        db.refresh(db_user)
        
        # Send verification email in background
        background_tasks.add_task(send_verification_email, user_in.email, code)
        
        # PRINT CODE TO CONSOLE FOR EASY DEVELOPMENT
        print(f"\nExample App: Registration Code for {user_in.email} is: ===> {code} <===\n")
        
        return {
            "message": "User registered successfully", 
            "debug_code": code 
        }
    except HTTPException as he:
        # Re-raise HTTP exceptions (like 400 Email already registered)
        raise he
    except Exception as e:
        print(f"❌ REGISTRATION ERROR: {str(e)}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {str(e)}")

class VerifyCodeSchema(BaseModel):
    email: EmailStr
    code: str

class EmailSchema(BaseModel):
    email: EmailStr

@router.post("/verify")
def verify_email_route(data: VerifyCodeSchema, db: Session = Depends(get_db)):
    db_code = db.query(models.VerificationCode).filter(
        models.VerificationCode.email == data.email,
        models.VerificationCode.code == data.code
    ).first()
    
    if not db_code:
        raise HTTPException(status_code=400, detail="Invalid verification code")
    
    user = db.query(models.User).filter(models.User.email == data.email).first()
    if user:
        user.is_verified = True
        db.delete(db_code) # Remove used code
        db.commit()
        db.refresh(user)
        
        # Generate token after verification
        access_token = security.create_access_token(
            subject=user.email,
            user_id=user.id,
            role=user.role
        )
        return {"access_token": access_token, "token_type": "bearer"}
    
    raise HTTPException(status_code=404, detail="User not found")

@router.post("/resend-code")
def resend_code(
    data: EmailSchema,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    user = db.query(models.User).filter(models.User.email == data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    if user.is_verified:
        raise HTTPException(status_code=400, detail="User already verified")
        
    # Remove old codes
    db.query(models.VerificationCode).filter(models.VerificationCode.email == data.email).delete()
    
    # Create new code
    code = generate_verification_code()
    db_code = models.VerificationCode(email=data.email, code=code)
    db.add(db_code)
    db.commit()
    
    # Send email
    background_tasks.add_task(send_verification_email, data.email, code)
    print(f"\nExample App: Resend Code for {data.email} is: ===> {code} <===\n")
    
    return {"message": "Verification code resent"}

@router.post("/login", response_model=schemas.Token)
def login(user_in: schemas.UserLogin, db: Session = Depends(get_db)):
    print(f"DEBUG: Login attempt for {user_in.email}")
    user = db.query(models.User).filter(models.User.email == user_in.email).first()
    
    if not user:
        print("DEBUG: Login failed - User not found in DB")
        raise HTTPException(status_code=401, detail="Incorrect email or password")
        
    keyword_match = security.verify_password(user_in.password, user.hashed_password)
    print(f"DEBUG: Password match result: {keyword_match}")
    
    if not keyword_match:
        print("DEBUG: Login failed - Password mismatch")
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    
    print(f"DEBUG: User Verified Status: {user.is_verified}")
    if not user.is_verified:
        print("DEBUG: Login failed - User not verified")
        raise HTTPException(status_code=400, detail="Email not verified")
    
    access_token = security.create_access_token(
        subject=user.email,
        user_id=user.id,
        role=user.role
    )
    print("DEBUG: Login successful, generating token")
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=schemas.UserResponse)
def read_users_me(current_user: models.User = Depends(deps.get_current_active_user)):
    return current_user
