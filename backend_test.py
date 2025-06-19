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
BACKEND_URL = "https://69781433-d1c7-48a6-be9f-61585bc307c7.preview.emergentagent.com"
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

# Test Company Registration without Subscription Plans
def test_company_registration_without_subscription():
    print_test_header("Company Registration without Subscription Plans")
    
    # Create unique company data
    timestamp = int(time.time())
    company_data = {
        "company_name": f"Test Company {timestamp}",
        "company_email": f"test{timestamp}@example.com",
        "company_phone": "123-456-7890",
        "company_address": "123 Test St",
        "company_website": "https://testcompany.com",
        "manager_name": "Test Manager",
        "manager_email": f"manager{timestamp}@example.com",
        "manager_password": "password123",
        "manager_phone": "123-456-7890",
        "manager_department": "Management"
    }
    
    response = requests.post(f"{API_URL}/companies/register", json=company_data)
    print_response(response)
    
    if not assert_status_code(response, 200):
        print("❌ Company registration failed")
        return None
    
    token_data = response.json()
    
    # Check that company data doesn't include subscription fields
    company = token_data["company"]
    subscription_fields = ["subscription_plan", "max_vehicles", "max_users", "trial_end_date"]
    
    for field in subscription_fields:
        if field in company:
            print(f"❌ Response still includes subscription field: {field}")
            return None
    
    print("✅ Company registration successful without subscription plan fields")
    return token_data["access_token"]

# Test Car Creation without Vehicle Limits
def test_car_creation_without_limits(token, num_cars=5):
    print_test_header(f"Car Creation without Vehicle Limits (creating {num_cars} cars)")
    
    headers = {"Authorization": f"Bearer {token}"}
    car_ids = []
    
    for i in range(num_cars):
        # Create unique car data
        timestamp = int(time.time()) + i
        car_data = {
            "make": f"Test Make {i}",
            "model": f"Test Model {i}",
            "year": 2022 + i % 3,
            "license_plate": f"TEST-{timestamp}",
            "vin": f"VIN{timestamp}",
            "mileage": 10000 + i * 1000,
            "category": "sedan"
        }
        
        response = requests.post(f"{API_URL}/cars", json=car_data, headers=headers)
        
        if not assert_status_code(response, 200):
            print(f"❌ Failed to create car {i+1}")
            return None
        
        car_ids.append(response.json()["id"])
        print(f"✅ Car {i+1} created successfully")
    
    print(f"✅ Successfully created {num_cars} cars without hitting any vehicle limits")
    
    # Clean up - delete the cars
    for car_id in car_ids:
        requests.delete(f"{API_URL}/cars/{car_id}", headers=headers)
    
    return True

# Test User Creation without User Limits
def test_user_creation_without_limits(token, num_users=5):
    print_test_header(f"User Creation without User Limits (creating {num_users} users)")
    
    headers = {"Authorization": f"Bearer {token}"}
    user_ids = []
    
    for i in range(num_users):
        # Create unique user data
        timestamp = int(time.time()) + i
        user_data = {
            "name": f"Test User {i}",
            "email": f"user{timestamp}@example.com",
            "password": "password123",
            "role": "regular_user",
            "department": f"Department {i}",
            "phone": f"123-456-{7890 + i}",
            "language": "en"
        }
        
        response = requests.post(f"{API_URL}/users", json=user_data, headers=headers)
        
        if not assert_status_code(response, 200):
            print(f"❌ Failed to create user {i+1}")
            return None
        
        user_ids.append(response.json()["id"])
        print(f"✅ User {i+1} created successfully")
    
    print(f"✅ Successfully created {num_users} users without hitting any user limits")
    
    # Return the last user ID for the update test
    return user_ids[-1] if user_ids else None

# Test User Update with Language Preference
def test_user_update_with_language(token, user_id):
    print_test_header("User Update with Language Preference")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Test updating to German
    update_data = {
        "name": "Updated User Name",
        "department": "Updated Department",
        "phone": "987-654-3210",
        "language": "de"
    }
    
    response = requests.put(f"{API_URL}/users/{user_id}", json=update_data, headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        print("❌ User update failed")
        return False
    
    user_data = response.json()
    
    # Verify language was updated correctly
    if not assert_field_equals(user_data, "language", "de"):
        return False
    
    # Test updating to Spanish
    update_data = {
        "language": "es"
    }
    
    response = requests.put(f"{API_URL}/users/{user_id}", json=update_data, headers=headers)
    
    if not assert_status_code(response, 200):
        print("❌ User update failed")
        return False
    
    user_data = response.json()
    
    # Verify language was updated correctly
    if not assert_field_equals(user_data, "language", "es"):
        return False
    
    print("✅ User language preference update successful")
    return True

# Test Company Info without Subscription Fields
def test_company_info_without_subscription(token):
    print_test_header("Company Info without Subscription Fields")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    response = requests.get(f"{API_URL}/companies/me", headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        print("❌ Company info retrieval failed")
        return False
    
    company_data = response.json()
    
    # Check that company data doesn't include subscription fields
    subscription_fields = ["subscription_plan", "max_vehicles", "max_users", "trial_end_date"]
    
    for field in subscription_fields:
        if field in company_data:
            print(f"❌ Response still includes subscription field: {field}")
            return False
    
    print("✅ Company info response correctly excludes subscription fields")
    return True

def run_subscription_removal_tests():
    print("\n🚀 Starting Tests for Subscription/Pricing Logic Removal\n")
    
    # Test company registration without subscription plans
    token = test_company_registration_without_subscription()
    if not token:
        print("❌ Company registration test failed")
        return False
    
    # Test car creation without vehicle limits
    car_test = test_car_creation_without_limits(token)
    if not car_test:
        print("❌ Car creation test failed")
        return False
    
    # Test user creation without user limits
    user_id = test_user_creation_without_limits(token)
    if not user_id:
        print("❌ User creation test failed")
        return False
    
    # Test user update with language preference
    user_update = test_user_update_with_language(token, user_id)
    if not user_update:
        print("❌ User update test failed")
        return False
    
    # Test company info without subscription fields
    company_info = test_company_info_without_subscription(token)
    if not company_info:
        print("❌ Company info test failed")
        return False
    
    print("\n🏁 All subscription removal tests completed successfully!\n")
    return True

# Licensing System Tests
def test_license_validation(license_key, expected_valid=True, expected_assigned=False):
    print_test_header(f"License Validation - {license_key}")
    
    validation_data = {
        "license_key": license_key
    }
    
    response = requests.post(f"{API_URL}/licenses/validate", json=validation_data)
    print_response(response)
    
    if expected_valid:
        if not assert_status_code(response, 200):
            return False
        
        data = response.json()
        if not assert_field_equals(data, "valid", True):
            return False
        
        if not assert_field_equals(data, "already_assigned", expected_assigned):
            return False
        
        print(f"✅ License validation successful for {license_key}")
        return data
    else:
        if not assert_status_code(response, 400):
            return False
        
        print(f"✅ Invalid license correctly rejected: {license_key}")
        return True

def test_company_registration_with_license(license_key, expected_success=True):
    print_test_header(f"Company Registration with License - {license_key}")
    
    # Create unique company data
    timestamp = int(time.time())
    company_data = {
        "company_name": f"License Test Company {timestamp}",
        "company_email": f"license_test{timestamp}@example.com",
        "company_phone": "123-456-7890",
        "company_address": "123 License Test St",
        "company_website": "https://licensetest.com",
        "license_key": license_key,
        "manager_name": "License Test Manager",
        "manager_email": f"license_manager{timestamp}@example.com",
        "manager_password": "Password123!",
        "manager_phone": "123-456-7890",
        "manager_department": "License Management"
    }
    
    response = requests.post(f"{API_URL}/companies/register", json=company_data)
    print_response(response)
    
    if expected_success:
        if not assert_status_code(response, 200):
            return None
        
        token_data = response.json()
        assert_field_exists(token_data, "access_token")
        assert_field_exists(token_data, "user")
        assert_field_exists(token_data, "company")
        
        print(f"✅ Company registration successful with license key: {license_key}")
        return token_data
    else:
        if not assert_status_code(response, 400):
            return False
        
        print(f"✅ Company registration correctly rejected with invalid license key: {license_key}")
        return True

def test_license_assignment(manager_token, license_key, expected_success=True):
    print_test_header(f"License Assignment - {license_key}")
    
    headers = {"Authorization": f"Bearer {manager_token}"}
    
    validation_data = {
        "license_key": license_key
    }
    
    response = requests.post(f"{API_URL}/licenses/assign", json=validation_data, headers=headers)
    print_response(response)
    
    if expected_success:
        if not assert_status_code(response, 200):
            return False
        
        print(f"✅ License assignment successful for {license_key}")
        return True
    else:
        if not assert_status_code(response, 400):
            return False
        
        print(f"✅ License assignment correctly rejected for {license_key}")
        return True

def test_company_license_info(token):
    print_test_header("Company License Info")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    response = requests.get(f"{API_URL}/licenses/company-info", headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    data = response.json()
    assert_field_exists(data, "has_license")
    
    if data["has_license"]:
        assert_field_exists(data, "license_type")
        assert_field_exists(data, "status")
        assert_field_exists(data, "limits")
        
        # Check limits structure
        limits = data["limits"]
        assert_field_exists(limits, "users_within_limit")
        assert_field_exists(limits, "vehicles_within_limit")
        assert_field_exists(limits, "users_count")
        assert_field_exists(limits, "vehicles_count")
    
    print("✅ Company license info retrieved successfully")
    return data

def test_admin_license_management(manager_token):
    print_test_header("Admin License Management")
    
    headers = {"Authorization": f"Bearer {manager_token}"}
    
    # 1. Create a new license
    license_data = {
        "license_type": "trial",
        "max_users": 3,
        "max_vehicles": 5,
        "expires_date": (datetime.utcnow() + timedelta(days=14)).isoformat(),
        "notes": "Test license created via API"
    }
    
    print("\nCreating a new license:")
    response = requests.post(f"{API_URL}/admin/licenses", json=license_data, headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    created_license = response.json()
    license_id = created_license["id"]
    license_key = created_license["license_key"]
    
    # 2. List all licenses
    print("\nListing all licenses:")
    response = requests.get(f"{API_URL}/admin/licenses", headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    licenses = response.json()
    if not any(license["id"] == license_id for license in licenses):
        print("❌ Created license not found in licenses list")
        return None
    
    print("✅ Created license found in licenses list")
    
    # 3. Revoke the license
    print(f"\nRevoking license {license_id}:")
    response = requests.delete(f"{API_URL}/admin/licenses/{license_id}", headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    # 4. Verify license is revoked
    response = requests.get(f"{API_URL}/admin/licenses", headers=headers)
    if response.status_code == 200:
        licenses = response.json()
        revoked_license = next((license for license in licenses if license["id"] == license_id), None)
        if revoked_license and revoked_license["status"] == "revoked":
            print("✅ License was successfully revoked")
        else:
            print("❌ License was not properly revoked")
            return None
    
    print("✅ Admin license management operations successful")
    return license_key

def test_license_limits(token, license_info):
    print_test_header("License Limits Enforcement")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Extract limits from license info
    limits = license_info["limits"]
    max_users = limits.get("max_users")
    max_vehicles = limits.get("max_vehicles")
    current_users = limits["users_count"]
    current_vehicles = limits["vehicles_count"]
    
    print(f"License limits: {max_users} users, {max_vehicles} vehicles")
    print(f"Current usage: {current_users} users, {current_vehicles} vehicles")
    
    # Test user creation up to limit
    if max_users is not None:
        users_to_create = max(0, max_users - current_users)
        print(f"\nCreating {users_to_create} users to reach limit:")
        
        user_ids = []
        for i in range(users_to_create):
            timestamp = int(time.time()) + i
            user_data = {
                "name": f"Limit Test User {i}",
                "email": f"limit_user{timestamp}@example.com",
                "password": "Password123!",
                "role": "regular_user",
                "department": "Testing"
            }
            
            response = requests.post(f"{API_URL}/users", json=user_data, headers=headers)
            if response.status_code == 200:
                user_id = response.json()["id"]
                user_ids.append(user_id)
                print(f"✅ Created user {i+1}/{users_to_create}")
            else:
                print(f"❌ Failed to create user {i+1}/{users_to_create}")
                print_response(response)
        
        # Try to create one more user (should fail)
        if users_to_create > 0:
            print("\nAttempting to create user beyond limit:")
            timestamp = int(time.time()) + 1000
            user_data = {
                "name": "Beyond Limit User",
                "email": f"beyond_limit{timestamp}@example.com",
                "password": "Password123!",
                "role": "regular_user",
                "department": "Testing"
            }
            
            response = requests.post(f"{API_URL}/users", json=user_data, headers=headers)
            print_response(response)
            
            if assert_status_code(response, 403):
                print("✅ User creation correctly blocked at license limit")
            else:
                print("❌ User creation was not blocked at license limit")
    
    # Test vehicle creation up to limit
    if max_vehicles is not None:
        vehicles_to_create = max(0, max_vehicles - current_vehicles)
        print(f"\nCreating {vehicles_to_create} vehicles to reach limit:")
        
        vehicle_ids = []
        for i in range(vehicles_to_create):
            timestamp = int(time.time()) + i
            vehicle_data = {
                "make": f"Limit Test Make {i}",
                "model": f"Limit Test Model {i}",
                "year": 2023,
                "license_plate": f"LIMIT-{timestamp}",
                "vin": f"LIMIT{timestamp}",
                "mileage": 5000 + i * 100,
                "category": "sedan"
            }
            
            response = requests.post(f"{API_URL}/cars", json=vehicle_data, headers=headers)
            if response.status_code == 200:
                vehicle_id = response.json()["id"]
                vehicle_ids.append(vehicle_id)
                print(f"✅ Created vehicle {i+1}/{vehicles_to_create}")
            else:
                print(f"❌ Failed to create vehicle {i+1}/{vehicles_to_create}")
                print_response(response)
        
        # Try to create one more vehicle (should fail)
        if vehicles_to_create > 0:
            print("\nAttempting to create vehicle beyond limit:")
            timestamp = int(time.time()) + 1000
            vehicle_data = {
                "make": "Beyond Limit Make",
                "model": "Beyond Limit Model",
                "year": 2023,
                "license_plate": f"BEYOND-{timestamp}",
                "vin": f"BEYOND{timestamp}",
                "mileage": 5000,
                "category": "sedan"
            }
            
            response = requests.post(f"{API_URL}/cars", json=vehicle_data, headers=headers)
            print_response(response)
            
            if assert_status_code(response, 403):
                print("✅ Vehicle creation correctly blocked at license limit")
            else:
                print("❌ Vehicle creation was not blocked at license limit")
    
    print("✅ License limits enforcement test completed")
    return True

def run_licensing_system_tests():
    print("\n🚀 Starting Licensing System Tests\n")
    
    # Sample license keys from the review request
    sample_licenses = {
        "TRIAL": "2CV1-09O9-1DE0-9YCC-1U4V",
        "BASIC": "ZH06-RKDV-WJRB-RINZ-VZ8Q",
        "PROFESSIONAL": "4RY4-WXV4-N6BE-UQY8-PWK6",
        "ENTERPRISE": "7N2F-FWDZ-H2TS-V3G2-K5X6",
        "TRIAL_SHORT": "6D6K-DAFG-RCP5-XKFK-FZGF",
        "INVALID": "INVALID-KEY-TEST"
    }
    
    # 1. Test license validation
    print("\n=== Testing License Validation API ===")
    
    # Test with valid license keys
    for license_type, license_key in sample_licenses.items():
        if license_type != "INVALID":
            result = test_license_validation(license_key, expected_valid=True)
            if not result:
                print(f"❌ License validation failed for {license_type} license")
    
    # Test with invalid license key
    result = test_license_validation(sample_licenses["INVALID"], expected_valid=False)
    if not result:
        print("❌ Invalid license validation test failed")
    
    # Test with empty license key
    result = test_license_validation("", expected_valid=False)
    if not result:
        print("❌ Empty license validation test failed")
    
    # 2. Test company registration with license
    print("\n=== Testing Company Registration with License ===")
    
    # Register with TRIAL license
    trial_registration = test_company_registration_with_license(sample_licenses["TRIAL"])
    if not trial_registration:
        print("❌ Company registration with TRIAL license failed")
        return False
    
    trial_token = trial_registration["access_token"]
    
    # Try to register with the same license (should fail)
    result = test_company_registration_with_license(sample_licenses["TRIAL"], expected_success=False)
    if not result:
        print("❌ Company registration with already assigned license test failed")
    
    # Try to register with invalid license (should fail)
    result = test_company_registration_with_license(sample_licenses["INVALID"], expected_success=False)
    if not result:
        print("❌ Company registration with invalid license test failed")
    
    # 3. Test company license info
    print("\n=== Testing Company License Info ===")
    
    license_info = test_company_license_info(trial_token)
    if not license_info:
        print("❌ Company license info test failed")
        return False
    
    # 4. Test license assignment
    print("\n=== Testing License Assignment ===")
    
    # Register another company with BASIC license
    basic_registration = test_company_registration_with_license(sample_licenses["BASIC"])
    if not basic_registration:
        print("❌ Company registration with BASIC license failed")
        return False
    
    basic_token = basic_registration["access_token"]
    
    # Try to assign already assigned license (should fail)
    result = test_license_assignment(basic_token, sample_licenses["TRIAL"], expected_success=False)
    if not result:
        print("❌ License assignment with already assigned license test failed")
    
    # Try to assign invalid license (should fail)
    result = test_license_assignment(basic_token, sample_licenses["INVALID"], expected_success=False)
    if not result:
        print("❌ License assignment with invalid license test failed")
    
    # 5. Test admin license management
    print("\n=== Testing Admin License Management ===")
    
    new_license_key = test_admin_license_management(basic_token)
    if not new_license_key:
        print("❌ Admin license management test failed")
        return False
    
    # 6. Test license limits enforcement
    print("\n=== Testing License Limits Enforcement ===")
    
    # Register a company with TRIAL_SHORT license (has low limits)
    short_registration = test_company_registration_with_license(sample_licenses["TRIAL_SHORT"])
    if not short_registration:
        print("❌ Company registration with TRIAL_SHORT license failed")
        return False
    
    short_token = short_registration["access_token"]
    
    # Get license info
    short_license_info = test_company_license_info(short_token)
    if not short_license_info:
        print("❌ Company license info test failed")
        return False
    
    # Test limits
    result = test_license_limits(short_token, short_license_info)
    if not result:
        print("❌ License limits enforcement test failed")
        return False
    
    print("\n🏁 All licensing system tests completed successfully!\n")
    return True

if __name__ == "__main__":
    # Uncomment to run authentication tests
    # run_auth_tests()
    
    # Uncomment to run subscription removal tests
    # run_subscription_removal_tests()
    
    # Run licensing system tests
    run_licensing_system_tests()
