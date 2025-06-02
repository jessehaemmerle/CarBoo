#!/usr/bin/env python3
import requests
import json
import uuid
from datetime import datetime, timedelta
import time
import sys
import random
import string

# Get the backend URL from the frontend .env file
BACKEND_URL = "https://2c450bf5-ffe9-49a2-ba07-d35dc10e37e9.preview.emergentagent.com"
API_URL = f"{BACKEND_URL}/api"

# Set to True to enable verbose output
VERBOSE = True

# Test data
test_cars = [
    {
        "make": "Toyota",
        "model": "Camry",
        "year": 2022,
        "license_plate": "ABC123",
        "vin": "1HGCM82633A123456",
        "mileage": 15000,
        "category": "sedan"
    },
    {
        "make": "Honda",
        "model": "CR-V",
        "year": 2021,
        "license_plate": "XYZ789",
        "vin": "5FNRL6H70MB123456",
        "mileage": 22000,
        "category": "suv"
    }
]

# Test data for downtimes
def create_downtime_data(car_id, reason="maintenance"):
    start_date = datetime.utcnow() - timedelta(days=1)
    end_date = datetime.utcnow() + timedelta(days=1)
    return {
        "car_id": car_id,
        "reason": reason,
        "description": f"Test {reason} downtime",
        "start_date": start_date.isoformat(),
        "end_date": end_date.isoformat(),
        "cost": 150.75
    }

# Test data for bookings
def create_booking_data(car_id, days_from_now=1, duration_days=2):
    start_date = datetime.utcnow() + timedelta(days=days_from_now)
    end_date = start_date + timedelta(days=duration_days)
    return {
        "car_id": car_id,
        "start_date": start_date.isoformat(),
        "end_date": end_date.isoformat(),
        "purpose": f"Test booking created at {datetime.utcnow().isoformat()}"
    }

# Test data for users
def generate_random_email():
    random_str = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
    return f"test_{random_str}@example.com"

test_fleet_manager = {
    "name": "Fleet Manager",
    "email": generate_random_email(),
    "password": "Password123!",
    "role": "fleet_manager",
    "department": "Fleet Management",
    "phone": "555-123-4567"
}

test_regular_user = {
    "name": "Regular User",
    "email": generate_random_email(),
    "password": "Password123!",
    "role": "regular_user",
    "department": "Sales",
    "phone": "555-987-6543"
}

# Helper functions
def print_test_header(test_name):
    print(f"\n{'=' * 80}")
    print(f"TEST: {test_name}")
    print(f"{'=' * 80}")

def print_response(response):
    print(f"Status Code: {response.status_code}")
    try:
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    except:
        print(f"Response: {response.text}")

def assert_status_code(response, expected_code):
    if response.status_code != expected_code:
        print(f"❌ Expected status code {expected_code}, got {response.status_code}")
        return False
    print(f"✅ Status code is {expected_code} as expected")
    return True

def assert_field_equals(data, field, expected_value):
    if field not in data:
        print(f"❌ Field '{field}' not found in response")
        return False
    if data[field] != expected_value:
        print(f"❌ Expected {field}={expected_value}, got {data[field]}")
        return False
    print(f"✅ Field {field}={expected_value} as expected")
    return True

def assert_field_exists(data, field):
    if field not in data:
        print(f"❌ Field '{field}' not found in response")
        return False
    print(f"✅ Field '{field}' exists in response")
    return True

# Authentication Tests
def test_user_registration(user_data):
    print_test_header(f"User Registration - {user_data['role']}")
    
    response = requests.post(f"{API_URL}/auth/register", json=user_data)
    print_response(response)
    
    if assert_status_code(response, 200):
        token_data = response.json()
        assert_field_exists(token_data, "access_token")
        assert_field_exists(token_data, "token_type")
        assert_field_exists(token_data, "user")
        
        user = token_data["user"]
        assert_field_equals(user, "name", user_data["name"])
        assert_field_equals(user, "email", user_data["email"])
        assert_field_equals(user, "role", user_data["role"])
        
        print(f"✅ Successfully registered {user_data['role']} user")
        return token_data
    return None

def test_user_login(email, password):
    print_test_header(f"User Login - {email}")
    
    login_data = {
        "email": email,
        "password": password
    }
    
    response = requests.post(f"{API_URL}/auth/login", json=login_data)
    print_response(response)
    
    if assert_status_code(response, 200):
        token_data = response.json()
        assert_field_exists(token_data, "access_token")
        assert_field_exists(token_data, "token_type")
        assert_field_exists(token_data, "user")
        
        print(f"✅ Successfully logged in as {email}")
        return token_data
    return None

def test_invalid_login():
    print_test_header("Invalid Login Attempt")
    
    login_data = {
        "email": "nonexistent@example.com",
        "password": "WrongPassword123"
    }
    
    response = requests.post(f"{API_URL}/auth/login", json=login_data)
    print_response(response)
    
    if assert_status_code(response, 401):
        print("✅ Invalid login correctly rejected")
        return True
    return False

def test_get_current_user(token):
    print_test_header("Get Current User Info")
    
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{API_URL}/auth/me", headers=headers)
    print_response(response)
    
    if assert_status_code(response, 200):
        user_data = response.json()
        assert_field_exists(user_data, "id")
        assert_field_exists(user_data, "name")
        assert_field_exists(user_data, "email")
        assert_field_exists(user_data, "role")
        
        print("✅ Successfully retrieved current user info")
        return user_data
    return None

def test_unauthorized_access():
    print_test_header("Unauthorized Access (No Token)")
    
    # Try to access protected endpoints without a token
    endpoints = [
        "/cars",
        "/downtimes",
        "/fleet/stats",
        "/users"
    ]
    
    all_rejected = True
    for endpoint in endpoints:
        response = requests.get(f"{API_URL}{endpoint}")
        print(f"Endpoint: {endpoint}, Status: {response.status_code}")
        
        if response.status_code != 401:
            print(f"❌ Expected 401 for unauthorized access to {endpoint}, got {response.status_code}")
            all_rejected = False
    
    if all_rejected:
        print("✅ All unauthorized access attempts correctly rejected")
        return True
    return False

# User Management Tests
def test_user_management_as_manager(manager_token):
    print_test_header("User Management (as Fleet Manager)")
    
    headers = {"Authorization": f"Bearer {manager_token}"}
    
    # Create a new user
    new_user = {
        "name": "Created User",
        "email": generate_random_email(),
        "password": "Password123!",
        "role": "regular_user",
        "department": "IT",
        "phone": "555-111-2222"
    }
    
    print("\nCreating a new user:")
    response = requests.post(f"{API_URL}/users", json=new_user, headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    created_user = response.json()
    user_id = created_user["id"]
    
    # List all users
    print("\nListing all users:")
    response = requests.get(f"{API_URL}/users", headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    users = response.json()
    if not any(user["id"] == user_id for user in users):
        print("❌ Created user not found in users list")
        return None
    
    print("✅ Created user found in users list")
    
    # Delete the user
    print(f"\nDeleting user {user_id}:")
    response = requests.delete(f"{API_URL}/users/{user_id}", headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    # Verify user is deleted
    response = requests.get(f"{API_URL}/users", headers=headers)
    if response.status_code == 200:
        users = response.json()
        if any(user["id"] == user_id for user in users):
            print("❌ User still exists after deletion")
            return None
    
    print("✅ User was successfully deleted")
    return True

def test_user_management_as_regular(regular_token):
    print_test_header("User Management (as Regular User)")
    
    headers = {"Authorization": f"Bearer {regular_token}"}
    
    # Try to list users
    print("\nAttempting to list users:")
    response = requests.get(f"{API_URL}/users", headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 403):
        print("❌ Regular user was able to list users")
        return False
    
    # Try to create a user
    new_user = {
        "name": "Unauthorized User",
        "email": generate_random_email(),
        "password": "Password123!",
        "role": "regular_user"
    }
    
    print("\nAttempting to create a user:")
    response = requests.post(f"{API_URL}/users", json=new_user, headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 403):
        print("❌ Regular user was able to create a user")
        return False
    
    print("✅ Regular user correctly denied access to user management")
    return True

# Car Management Tests
def test_car_management_as_manager(manager_token):
    print_test_header("Car Management (as Fleet Manager)")
    
    headers = {"Authorization": f"Bearer {manager_token}"}
    
    # Create a car
    car_data = test_cars[0]
    print("\nCreating a car:")
    response = requests.post(f"{API_URL}/cars", json=car_data, headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    car = response.json()
    car_id = car["id"]
    
    # Update the car
    update_data = {
        "mileage": 30000,
        "status": "in_use"
    }
    
    print(f"\nUpdating car {car_id}:")
    response = requests.put(f"{API_URL}/cars/{car_id}", json=update_data, headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    updated_car = response.json()
    assert_field_equals(updated_car, "mileage", update_data["mileage"])
    assert_field_equals(updated_car, "status", update_data["status"])
    
    # Get the car
    print(f"\nGetting car {car_id}:")
    response = requests.get(f"{API_URL}/cars/{car_id}", headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    # Delete the car
    print(f"\nDeleting car {car_id}:")
    response = requests.delete(f"{API_URL}/cars/{car_id}", headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    print("✅ Fleet manager successfully performed all car operations")
    return car_id

def test_car_management_as_regular(regular_token, manager_token):
    print_test_header("Car Management (as Regular User)")
    
    regular_headers = {"Authorization": f"Bearer {regular_token}"}
    manager_headers = {"Authorization": f"Bearer {manager_token}"}
    
    # First, have the manager create a car
    car_data = test_cars[1]
    response = requests.post(f"{API_URL}/cars", json=car_data, headers=manager_headers)
    if response.status_code != 200:
        print("❌ Failed to create test car as manager")
        return False
    
    car = response.json()
    car_id = car["id"]
    print(f"Created test car with ID: {car_id}")
    
    # Regular user tries to view cars (should succeed)
    print("\nRegular user viewing all cars:")
    response = requests.get(f"{API_URL}/cars", headers=regular_headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return False
    
    # Regular user tries to view specific car (should succeed)
    print(f"\nRegular user viewing specific car {car_id}:")
    response = requests.get(f"{API_URL}/cars/{car_id}", headers=regular_headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return False
    
    # Regular user tries to create a car (should fail)
    print("\nRegular user attempting to create a car:")
    new_car = {
        "make": "Unauthorized",
        "model": "Car",
        "year": 2023,
        "license_plate": "UNAUTH1",
        "vin": "UNAUTHORIZED12345",
        "mileage": 5000,
        "category": "sedan"
    }
    
    response = requests.post(f"{API_URL}/cars", json=new_car, headers=regular_headers)
    print_response(response)
    
    if not assert_status_code(response, 403):
        print("❌ Regular user was able to create a car")
        return False
    
    # Regular user tries to update a car (should fail)
    print(f"\nRegular user attempting to update car {car_id}:")
    update_data = {
        "mileage": 40000
    }
    
    response = requests.put(f"{API_URL}/cars/{car_id}", json=update_data, headers=regular_headers)
    print_response(response)
    
    if not assert_status_code(response, 403):
        print("❌ Regular user was able to update a car")
        return False
    
    # Regular user tries to delete a car (should fail)
    print(f"\nRegular user attempting to delete car {car_id}:")
    response = requests.delete(f"{API_URL}/cars/{car_id}", headers=regular_headers)
    print_response(response)
    
    if not assert_status_code(response, 403):
        print("❌ Regular user was able to delete a car")
        return False
    
    # Clean up - manager deletes the car
    requests.delete(f"{API_URL}/cars/{car_id}", headers=manager_headers)
    
    print("✅ Regular user correctly restricted to read-only car operations")
    return True

# Downtime Management Tests
def test_downtime_management_as_manager(manager_token):
    print_test_header("Downtime Management (as Fleet Manager)")
    
    headers = {"Authorization": f"Bearer {manager_token}"}
    
    # First, create a car
    car_data = test_cars[0]
    response = requests.post(f"{API_URL}/cars", json=car_data, headers=headers)
    if response.status_code != 200:
        print("❌ Failed to create test car")
        return None
    
    car = response.json()
    car_id = car["id"]
    print(f"Created test car with ID: {car_id}")
    
    # Create a downtime
    downtime_data = create_downtime_data(car_id, "maintenance")
    print("\nCreating a downtime:")
    response = requests.post(f"{API_URL}/downtimes", json=downtime_data, headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    downtime = response.json()
    downtime_id = downtime["id"]
    
    # Update the downtime
    update_data = {
        "description": "Updated maintenance description",
        "cost": 300.50
    }
    
    print(f"\nUpdating downtime {downtime_id}:")
    response = requests.put(f"{API_URL}/downtimes/{downtime_id}", json=update_data, headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    updated_downtime = response.json()
    assert_field_equals(updated_downtime, "description", update_data["description"])
    assert_field_equals(updated_downtime, "cost", update_data["cost"])
    
    # Get all downtimes
    print("\nGetting all downtimes:")
    response = requests.get(f"{API_URL}/downtimes", headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    # Get car downtimes
    print(f"\nGetting downtimes for car {car_id}:")
    response = requests.get(f"{API_URL}/downtimes/car/{car_id}", headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    # Delete the downtime
    print(f"\nDeleting downtime {downtime_id}:")
    response = requests.delete(f"{API_URL}/downtimes/{downtime_id}", headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    # Clean up - delete the car
    requests.delete(f"{API_URL}/cars/{car_id}", headers=headers)
    
    print("✅ Fleet manager successfully performed all downtime operations")
    return car_id, downtime_id

def test_downtime_management_as_regular(regular_token, manager_token):
    print_test_header("Downtime Management (as Regular User)")
    
    regular_headers = {"Authorization": f"Bearer {regular_token}"}
    manager_headers = {"Authorization": f"Bearer {manager_token}"}
    
    # First, have the manager create a car and downtime
    car_data = test_cars[1]
    response = requests.post(f"{API_URL}/cars", json=car_data, headers=manager_headers)
    if response.status_code != 200:
        print("❌ Failed to create test car as manager")
        return False
    
    car = response.json()
    car_id = car["id"]
    print(f"Created test car with ID: {car_id}")
    
    downtime_data = create_downtime_data(car_id, "repair")
    response = requests.post(f"{API_URL}/downtimes", json=downtime_data, headers=manager_headers)
    if response.status_code != 200:
        print("❌ Failed to create test downtime as manager")
        return False
    
    downtime = response.json()
    downtime_id = downtime["id"]
    print(f"Created test downtime with ID: {downtime_id}")
    
    # Regular user tries to view downtimes (should succeed)
    print("\nRegular user viewing all downtimes:")
    response = requests.get(f"{API_URL}/downtimes", headers=regular_headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return False
    
    # Regular user tries to view car downtimes (should succeed)
    print(f"\nRegular user viewing downtimes for car {car_id}:")
    response = requests.get(f"{API_URL}/downtimes/car/{car_id}", headers=regular_headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return False
    
    # Regular user tries to create a downtime (should fail)
    print("\nRegular user attempting to create a downtime:")
    new_downtime = create_downtime_data(car_id, "cleaning")
    
    response = requests.post(f"{API_URL}/downtimes", json=new_downtime, headers=regular_headers)
    print_response(response)
    
    if not assert_status_code(response, 403):
        print("❌ Regular user was able to create a downtime")
        return False
    
    # Regular user tries to update a downtime (should fail)
    print(f"\nRegular user attempting to update downtime {downtime_id}:")
    update_data = {
        "description": "Unauthorized update"
    }
    
    response = requests.put(f"{API_URL}/downtimes/{downtime_id}", json=update_data, headers=regular_headers)
    print_response(response)
    
    if not assert_status_code(response, 403):
        print("❌ Regular user was able to update a downtime")
        return False
    
    # Regular user tries to delete a downtime (should fail)
    print(f"\nRegular user attempting to delete downtime {downtime_id}:")
    response = requests.delete(f"{API_URL}/downtimes/{downtime_id}", headers=regular_headers)
    print_response(response)
    
    if not assert_status_code(response, 403):
        print("❌ Regular user was able to delete a downtime")
        return False
    
    # Clean up - manager deletes the downtime and car
    requests.delete(f"{API_URL}/downtimes/{downtime_id}", headers=manager_headers)
    requests.delete(f"{API_URL}/cars/{car_id}", headers=manager_headers)
    
    print("✅ Regular user correctly restricted to read-only downtime operations")
    return True

# Fleet Statistics Tests
def test_fleet_statistics_access(manager_token, regular_token):
    print_test_header("Fleet Statistics Access")
    
    manager_headers = {"Authorization": f"Bearer {manager_token}"}
    regular_headers = {"Authorization": f"Bearer {regular_token}"}
    
    # Test manager access to stats
    print("\nFleet manager accessing statistics:")
    response = requests.get(f"{API_URL}/fleet/stats", headers=manager_headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return False
    
    # Test manager access to categories
    print("\nFleet manager accessing categories:")
    response = requests.get(f"{API_URL}/fleet/categories", headers=manager_headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return False
    
    # Test regular user access to stats
    print("\nRegular user accessing statistics:")
    response = requests.get(f"{API_URL}/fleet/stats", headers=regular_headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return False
    
    # Test regular user access to categories
    print("\nRegular user accessing categories:")
    response = requests.get(f"{API_URL}/fleet/categories", headers=regular_headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return False
    
    print("✅ Both user roles can access fleet statistics")
    return True

def run_auth_tests():
    print("\n🚀 Starting Fleet Management API Authentication Tests\n")
    
    # Test unauthorized access
    test_unauthorized_access()
    
    # Test user registration
    manager_data = test_user_registration(test_fleet_manager)
    if not manager_data:
        print("❌ Failed to register fleet manager")
        return False
    
    manager_token = manager_data["access_token"]
    
    # Test user login
    manager_login = test_user_login(test_fleet_manager["email"], test_fleet_manager["password"])
    if not manager_login:
        print("❌ Failed to login as fleet manager")
        return False
    
    # Test invalid login
    test_invalid_login()
    
    # Test get current user
    manager_info = test_get_current_user(manager_token)
    if not manager_info:
        print("❌ Failed to get current user info")
        return False
    
    # Test user management as manager
    user_mgmt_result = test_user_management_as_manager(manager_token)
    if user_mgmt_result is None:
        print("❌ User management as manager failed")
        return False
    
    # Create a regular user through the manager API
    regular_user_data = {
        "name": test_regular_user["name"],
        "email": test_regular_user["email"],
        "password": test_regular_user["password"],
        "role": test_regular_user["role"],
        "department": test_regular_user["department"],
        "phone": test_regular_user["phone"]
    }
    
    headers = {"Authorization": f"Bearer {manager_token}"}
    response = requests.post(f"{API_URL}/users", json=regular_user_data, headers=headers)
    if response.status_code != 200:
        print("❌ Failed to create regular user")
        return False
    
    # Login as regular user
    regular_login = test_user_login(test_regular_user["email"], test_regular_user["password"])
    if not regular_login:
        print("❌ Failed to login as regular user")
        return False
    
    regular_token = regular_login["access_token"]
    
    # Test user management as regular user (should fail)
    user_mgmt_regular = test_user_management_as_regular(regular_token)
    if not user_mgmt_regular:
        print("❌ User management as regular user test failed")
        return False
    
    # Test car management as manager
    car_mgmt_manager = test_car_management_as_manager(manager_token)
    if car_mgmt_manager is None:
        print("❌ Car management as manager failed")
        return False
    
    # Test car management as regular user
    car_mgmt_regular = test_car_management_as_regular(regular_token, manager_token)
    if not car_mgmt_regular:
        print("❌ Car management as regular user test failed")
        return False
    
    # Test downtime management as manager
    downtime_mgmt_manager = test_downtime_management_as_manager(manager_token)
    if downtime_mgmt_manager is None:
        print("❌ Downtime management as manager failed")
        return False
    
    # Test downtime management as regular user
    downtime_mgmt_regular = test_downtime_management_as_regular(regular_token, manager_token)
    if not downtime_mgmt_regular:
        print("❌ Downtime management as regular user test failed")
        return False
    
    # Test fleet statistics access for both roles
    stats_access = test_fleet_statistics_access(manager_token, regular_token)
    if not stats_access:
        print("❌ Fleet statistics access test failed")
        return False
    
    print("\n🏁 All authentication and authorization tests completed successfully!\n")
    return True

if __name__ == "__main__":
    run_auth_tests()
