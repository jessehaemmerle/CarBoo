#!/usr/bin/env python3
import requests
import json
from datetime import datetime, timedelta
import time
import random
import string

# Get the backend URL
BACKEND_URL = "https://69781433-d1c7-48a6-be9f-61585bc307c7.preview.emergentagent.com"
API_URL = f"{BACKEND_URL}/api"

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

def generate_random_email():
    random_str = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
    return f"test_{random_str}@example.com"

# Register a new company and get token
def register_company():
    print_test_header("Register New Company")
    
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
        return None
    
    return response.json()["access_token"]

# Create a car
def create_car(token):
    print_test_header("Create Car")
    
    headers = {"Authorization": f"Bearer {token}"}
    timestamp = int(time.time())
    car_data = {
        "make": "Test Make",
        "model": "Test Model",
        "year": 2022,
        "license_plate": f"TEST-{timestamp}",
        "vin": f"VIN{timestamp}",
        "mileage": 10000,
        "category": "sedan"
    }
    
    response = requests.post(f"{API_URL}/cars", json=car_data, headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    return response.json()["id"]

# Create a regular user
def create_regular_user(token):
    print_test_header("Create Regular User")
    
    headers = {"Authorization": f"Bearer {token}"}
    timestamp = int(time.time())
    user_data = {
        "name": "Regular User",
        "email": f"user{timestamp}@example.com",
        "password": "password123",
        "role": "regular_user",
        "department": "Sales",
        "phone": "123-456-7890",
        "language": "en"
    }
    
    response = requests.post(f"{API_URL}/users", json=user_data, headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    return response.json()["id"], user_data["email"], user_data["password"]

# Login as user
def login_user(email, password):
    print_test_header(f"Login as {email}")
    
    login_data = {
        "email": email,
        "password": password
    }
    
    response = requests.post(f"{API_URL}/auth/login", json=login_data)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    return response.json()["access_token"]

# Create a booking
def create_booking(token, car_id):
    print_test_header("Create Booking")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # First, get the current user info to verify we're logged in correctly
    response = requests.get(f"{API_URL}/auth/me", headers=headers)
    print("Current user info:")
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    # Now create the booking
    start_date = datetime.utcnow() + timedelta(days=1)
    end_date = start_date + timedelta(days=2)
    
    booking_data = {
        "car_id": car_id,
        "start_date": start_date.isoformat(),
        "end_date": end_date.isoformat(),
        "purpose": "Test booking"
    }
    
    response = requests.post(f"{API_URL}/bookings", json=booking_data, headers=headers)
    print("Booking creation response:")
    print_response(response)
    
    if not assert_status_code(response, 200):
        return None
    
    return response.json()["id"]

# Approve a booking
def approve_booking(token, booking_id):
    print_test_header("Approve Booking")
    
    headers = {"Authorization": f"Bearer {token}"}
    approval_data = {
        "status": "approved"
    }
    
    response = requests.put(f"{API_URL}/bookings/{booking_id}/approve", json=approval_data, headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return False
    
    return True

# Get all bookings
def get_bookings(token):
    print_test_header("Get All Bookings")
    
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{API_URL}/bookings", headers=headers)
    print_response(response)
    
    if not assert_status_code(response, 200):
        return False
    
    return True

# Run booking tests
def run_booking_tests():
    print("\n🚀 Starting Booking System Tests\n")
    
    # Register a new company
    manager_token = register_company()
    if not manager_token:
        print("❌ Failed to register company")
        return False
    
    # Create a car
    car_id = create_car(manager_token)
    if not car_id:
        print("❌ Failed to create car")
        return False
    
    # Create a regular user
    user_result = create_regular_user(manager_token)
    if not user_result:
        print("❌ Failed to create regular user")
        return False
    
    user_id, user_email, user_password = user_result
    
    # Login as regular user
    user_token = login_user(user_email, user_password)
    if not user_token:
        print("❌ Failed to login as regular user")
        return False
    
    # Create a booking as regular user
    booking_id = create_booking(user_token, car_id)
    if not booking_id:
        print("❌ Failed to create booking")
        return False
    
    # Approve the booking as manager
    if not approve_booking(manager_token, booking_id):
        print("❌ Failed to approve booking")
        return False
    
    # Get all bookings as manager
    if not get_bookings(manager_token):
        print("❌ Failed to get bookings as manager")
        return False
    
    # Get all bookings as regular user
    if not get_bookings(user_token):
        print("❌ Failed to get bookings as regular user")
        return False
    
    print("\n🏁 All booking tests completed successfully!\n")
    return True

if __name__ == "__main__":
    run_booking_tests()