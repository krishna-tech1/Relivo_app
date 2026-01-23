import sys
import os
from datetime import datetime

# Improve path handling to find 'app' and 'db'
sys.path.append(os.getcwd())

from sqlalchemy.orm import Session
from db.session import SessionLocal
from db import models

def seed_grants():
    db = SessionLocal()
    try:
        # Check if grants already exist to avoid duplicates
        if db.query(models.Grant).count() > 0:
            print("Grants table already has data. Skipping seed.")
            return

        print("Seeding grants...")

        grants_data = [
            {
                "title": "Emergency Housing Assistance",
                "provider": "UN Refugee Agency",
                "location": "Germany",
                "deadline": datetime(2026, 2, 15),
                "amount": "€5,000",
                "description": "Financial assistance for refugees seeking emergency housing solutions. This grant covers rent deposits, first month's rent, and essential furniture."
            },
            {
                "title": "Education & Training Grant",
                "provider": "European Education Foundation",
                "location": "France",
                "deadline": datetime(2026, 3, 30),
                "amount": "€3,500",
                "description": "Support for refugees pursuing education, vocational training, or professional certification programs."
            },
            {
                "title": "Healthcare Support Fund",
                "provider": "International Medical Corps",
                "location": "Sweden",
                "deadline": datetime(2026, 2, 28),
                "amount": "€2,000",
                "description": "Medical assistance for refugees requiring healthcare services not covered by standard insurance."
            },
            {
                "title": "Small Business Startup Grant",
                "provider": "Refugee Entrepreneurship Network",
                "location": "Netherlands",
                "deadline": datetime(2026, 4, 15),
                "amount": "€8,000",
                "description": "Funding for refugees looking to start their own small business or social enterprise."
            },
            {
                "title": "Family Reunification Support",
                "provider": "Red Cross International",
                "location": "Belgium",
                "deadline": datetime(2026, 3, 10),
                "amount": "€4,500",
                "description": "Legal and financial assistance for family reunification processes."
            }
        ]

        for data in grants_data:
            grant = models.Grant(**data)
            db.add(grant)
        
        db.commit()
        print("Successfully seeded 5 grants.")

    except Exception as e:
        print(f"Error seeding grants: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_grants()
