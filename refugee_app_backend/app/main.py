from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import auth
from db.session import engine, Base
import db.models # Import models to ensure they are registered with Base

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create database tables
Base.metadata.create_all(bind=engine)

app.include_router(auth.router)

@app.get("/")
async def root():
    return {"message": "Refugee App Backend is running"}
