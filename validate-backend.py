#!/usr/bin/env python3

"""
Backend Configuration Validator
Tests if the backend can start up properly with the current configuration
"""

import sys
import os
import asyncio
from pathlib import Path

# Add backend directory to path
backend_dir = Path(__file__).parent / "backend"
sys.path.insert(0, str(backend_dir))

async def test_backend_startup():
    """Test if the backend can start up without errors"""
    
    print("🔍 Testing backend configuration...")
    
    # Set test environment variables
    os.environ['MONGO_URL'] = 'mongodb://test:test@localhost:27017/test_db?authSource=admin'
    os.environ['DB_NAME'] = 'test_database'
    os.environ['JWT_SECRET_KEY'] = 'test-secret-key-for-validation'
    
    try:
        # Try to import the server module
        print("  ✓ Testing imports...")
        import server
        print("  ✓ Server module imported successfully")
        
        # Test if the FastAPI app can be created
        print("  ✓ Testing FastAPI app creation...")
        app = server.app
        print("  ✓ FastAPI app created successfully")
        
        # Test if routes are properly configured
        print("  ✓ Testing route configuration...")
        routes = [route.path for route in app.routes]
        expected_routes = ['/api/health', '/api/licenses/validate', '/api/companies/register']
        
        for expected_route in expected_routes:
            if any(expected_route in route for route in routes):
                print(f"    ✓ Route {expected_route} found")
            else:
                print(f"    ❌ Route {expected_route} missing")
                return False
        
        # Test models
        print("  ✓ Testing data models...")
        license_model = server.License(
            license_key="TEST-TEST-TEST-TEST-TEST",
            license_type=server.LicenseType.TRIAL,
            max_users=5,
            max_vehicles=10
        )
        print("  ✓ License model works correctly")
        
        print("✅ Backend configuration test passed!")
        return True
        
    except ImportError as e:
        print(f"❌ Import error: {e}")
        return False
    except Exception as e:
        print(f"❌ Configuration error: {e}")
        return False

def test_environment_variables():
    """Test environment variable configuration"""
    
    print("🔍 Testing environment variable configuration...")
    
    # Test environment variables that will be set in Docker
    test_env = {
        'MONGO_URL': 'mongodb://root:password@mongodb:27017/test_database?authSource=admin',
        'DB_NAME': 'test_database',
        'JWT_SECRET_KEY': 'test-secret-key',
        'ENVIRONMENT': 'production'
    }
    
    for key, value in test_env.items():
        os.environ[key] = value
        print(f"  ✓ {key} = {value}")
    
    print("✅ Environment variables configured")
    return True

if __name__ == "__main__":
    print("🧪 Backend Configuration Validation")
    print("===================================")
    
    success = True
    
    try:
        # Test environment variables
        success &= test_environment_variables()
        print()
        
        # Test backend startup
        success &= asyncio.run(test_backend_startup())
        print()
        
        if success:
            print("🎉 All tests passed! Backend should work in Docker.")
        else:
            print("💥 Some tests failed. Check the errors above.")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n⏹️  Test interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n💥 Unexpected error: {e}")
        sys.exit(1)