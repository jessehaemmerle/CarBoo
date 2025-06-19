#!/usr/bin/env python3

"""
License Generator Script for Fleet Management System
Creates sample licenses for testing
"""

import asyncio
import os
import sys
from datetime import datetime, timedelta
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv
from pathlib import Path

# Add the backend directory to Python path
backend_dir = Path(__file__).parent / "backend"
sys.path.append(str(backend_dir))

# Load environment variables
load_dotenv(backend_dir / '.env')

# Import from server after setting up the path
from server import generate_license_key, LicenseType, LicenseStatus

async def create_sample_licenses():
    """Create sample licenses for testing"""
    
    # Connect to MongoDB
    mongo_url = os.environ['MONGO_URL']
    client = AsyncIOMotorClient(mongo_url)
    db = client[os.environ['DB_NAME']]
    
    print("🔑 Creating sample licenses for Fleet Management System...")
    print("=" * 60)
    
    # Sample licenses to create
    licenses_to_create = [
        {
            "license_type": LicenseType.TRIAL,
            "max_users": 5,
            "max_vehicles": 10,
            "expires_date": datetime.utcnow() + timedelta(days=30),
            "notes": "Trial license - 30 days"
        },
        {
            "license_type": LicenseType.BASIC,
            "max_users": 25,
            "max_vehicles": 50,
            "expires_date": datetime.utcnow() + timedelta(days=365),
            "notes": "Basic plan - 1 year"
        },
        {
            "license_type": LicenseType.PROFESSIONAL,
            "max_users": 100,
            "max_vehicles": 200,
            "expires_date": datetime.utcnow() + timedelta(days=365),
            "notes": "Professional plan - 1 year"
        },
        {
            "license_type": LicenseType.ENTERPRISE,
            "max_users": None,  # Unlimited
            "max_vehicles": None,  # Unlimited
            "expires_date": datetime.utcnow() + timedelta(days=365),
            "notes": "Enterprise plan - 1 year, unlimited users and vehicles"
        },
        {
            "license_type": LicenseType.TRIAL,
            "max_users": 3,
            "max_vehicles": 5,
            "expires_date": datetime.utcnow() + timedelta(days=7),
            "notes": "Short trial license - 7 days"
        }
    ]
    
    created_licenses = []
    
    for license_data in licenses_to_create:
        # Generate unique license key
        license_key = generate_license_key()
        
        # Ensure license key is unique
        while await db.licenses.find_one({"license_key": license_key}):
            license_key = generate_license_key()
        
        # Create license document
        license_doc = {
            "id": license_key.replace("-", "").lower()[:24] + str(len(created_licenses)).zfill(8),
            "license_key": license_key,
            "company_id": None,  # Unassigned
            "license_type": license_data["license_type"],
            "status": LicenseStatus.ACTIVE,
            "max_users": license_data["max_users"],
            "max_vehicles": license_data["max_vehicles"],
            "issued_date": datetime.utcnow(),
            "expires_date": license_data["expires_date"],
            "activated_date": None,
            "created_by": "system",
            "notes": license_data["notes"]
        }
        
        # Insert into database
        await db.licenses.insert_one(license_doc)
        created_licenses.append(license_doc)
        
        # Print license info
        max_users_str = str(license_data["max_users"]) if license_data["max_users"] else "Unlimited"
        max_vehicles_str = str(license_data["max_vehicles"]) if license_data["max_vehicles"] else "Unlimited"
        expires_str = license_data["expires_date"].strftime("%Y-%m-%d")
        
        print(f"✅ {license_data['license_type'].upper()} License")
        print(f"   Key: {license_key}")
        print(f"   Users: {max_users_str}")
        print(f"   Vehicles: {max_vehicles_str}")
        print(f"   Expires: {expires_str}")
        print(f"   Notes: {license_data['notes']}")
        print()
    
    print(f"🎉 Successfully created {len(created_licenses)} sample licenses!")
    print()
    print("📋 License Keys Summary:")
    print("-" * 30)
    for license_doc in created_licenses:
        print(f"{license_doc['license_type'].upper():12} | {license_doc['license_key']}")
    
    print()
    print("💡 You can now use these license keys to:")
    print("   1. Register new companies")
    print("   2. Test the licensing system")
    print("   3. Validate license functionality")
    
    # Close the connection
    client.close()

if __name__ == "__main__":
    asyncio.run(create_sample_licenses())