from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging

from app.api import auth
from db.session import engine, Base
import db.models # Import models to ensure they are registered with Base

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Refugee App Backend", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Startup event to create tables
@app.on_event("startup")
async def startup_event():
    """Create database tables on startup"""
    try:
        logger.info("Creating database tables...")
        Base.metadata.create_all(bind=engine)
        logger.info("✅ Database tables created successfully")
    except Exception as e:
        logger.error(f"❌ Error creating tables: {e}")
        # Don't crash the app, tables might already exist
        logger.warning("Continuing without creating tables - they may already exist")

# Include routers
app.include_router(auth.router)
from app.api import grants
app.include_router(grants.router)

@app.get("/")
async def root():
    return {
        "message": "Refugee App Backend is running",
        "version": "1.0.0",
        "status": "healthy"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        # Test database connection
        from db.session import SessionLocal
        from sqlalchemy import text
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "database": "disconnected", "error": str(e)}

@app.get("/migrate-schema")
async def migrate_schema():
    """Manually apply schema updates (e.g. adding columns)"""
    from db.session import engine
    from sqlalchemy import text
    try:
        with engine.connect() as conn:
            # Check if category column exists
            # This is a simple way for PostgreSQL/SQLite
            try:
                conn.execute(text("ALTER TABLE grants ADD COLUMN category VARCHAR(100) DEFAULT 'General'"))
                conn.commit()
                message = "✅ Migration successful: Added 'category' column."
            except Exception as e:
                # If column already exists, it will error
                if "already exists" in str(e).lower() or "duplicate column" in str(e).lower():
                    message = "ℹ️ 'category' column already exists."
                else:
                    return {"error": str(e)}

            # Perform one-time bulk categorization for 'General' grants
            try:
                # Update Housing
                conn.execute(text("""
                    UPDATE grants SET category = 'Housing' 
                    WHERE category = 'General' AND (
                        LOWER(title) LIKE '%housing%' OR LOWER(title) LIKE '%shelter%' OR 
                        LOWER(description) LIKE '%housing%' OR LOWER(description) LIKE '%shelter%'
                    )
                """))
                # Update Education
                conn.execute(text("""
                    UPDATE grants SET category = 'Education' 
                    WHERE category = 'General' AND (
                        LOWER(title) LIKE '%education%' OR LOWER(title) LIKE '%training%' OR 
                        LOWER(description) LIKE '%education%' OR LOWER(description) LIKE '%training%'
                    )
                """))
                # Update Healthcare
                conn.execute(text("""
                    UPDATE grants SET category = 'Healthcare' 
                    WHERE category = 'General' AND (
                        LOWER(title) LIKE '%health%' OR LOWER(title) LIKE '%medical%' OR 
                        LOWER(description) LIKE '%health%' OR LOWER(description) LIKE '%medical%'
                    )
                """))
                # Update Employment
                conn.execute(text("""
                    UPDATE grants SET category = 'Employment' 
                    WHERE category = 'General' AND (
                        LOWER(title) LIKE '%employment%' OR LOWER(title) LIKE '%job%' OR LOWER(title) LIKE '%business%' OR
                        LOWER(description) LIKE '%employment%' OR LOWER(description) LIKE '%job%' OR LOWER(description) LIKE '%business%'
                    )
                """))
                # Update Legal
                conn.execute(text("""
                    UPDATE grants SET category = 'Legal' 
                    WHERE category = 'General' AND (
                        LOWER(title) LIKE '%legal%' OR LOWER(title) LIKE '%asylum%' OR 
                        LOWER(description) LIKE '%legal%' OR LOWER(description) LIKE '%asylum%'
                    )
                """))
                # Update Emergency
                conn.execute(text("""
                    UPDATE grants SET category = 'Emergency' 
                    WHERE category = 'General' AND (
                        LOWER(title) LIKE '%emergency%' OR LOWER(title) LIKE '%urgent%' OR 
                        LOWER(description) LIKE '%emergency%' OR LOWER(description) LIKE '%urgent%'
                    )
                """))
                conn.commit()
                return {"message": f"{message} Categorization sync complete."}
            except Exception as e:
                return {"message": f"{message} Error during categorization: {str(e)}"}
    except Exception as e:
        return {"error": str(e)}

    finally:
        db.close()



