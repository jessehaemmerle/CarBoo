#!/usr/bin/env python3
import requests
import json
import uuid
from datetime import datetime, timedelta
import time
import sys

# Get the backend URL from the frontend .env file
BACKEND_URL = "https://2c450bf5-ffe9-49a2-ba07-d35dc10e37e9.preview.emergentagent.com"
API_URL = f"{BACKEND_URL}/api"

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
    },
    {
        "make": "Ford",
        "model": "F-150",
        "year": 2020,
        "license_plate": "TRK456",
        "vin": "1FTFW1ET5DFA12345",
        "mileage": 35000,
        "category": "truck"
    },
    {
        "make": "Dodge",
        "model": "Grand Caravan",
        "year": 2019,
        "license_plate": "VAN789",
        "vin": "2C4RDGCG1KR12345",
        "mileage": 45000,
        "category": "van"
    },
    {
        "make": "Volkswagen",
        "model": "Golf",
        "year": 2021,
        "license_plate": "HTB123",
        "vin": "3VWPD71K26M12345",
        "mileage": 18000,
        "category": "hatchback"
    },
    {
        "make": "BMW",
        "model": "M4",
        "year": 2022,
        "license_plate": "CPE456",
        "vin": "WBA3R1C5XEK12345",
        "mileage": 12000,
        "category": "coupe"
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

def cleanup_database():
    print_test_header("Cleaning up database")
    
    # Get all cars
    response = requests.get(f"{API_URL}/cars")
    if response.status_code == 200:
        cars = response.json()
        for car in cars:
            # Delete each car
            car_id = car["id"]
            delete_response = requests.delete(f"{API_URL}/cars/{car_id}")
            print(f"Deleted car {car_id}: {delete_response.status_code}")
    
    # Get all downtimes
    response = requests.get(f"{API_URL}/downtimes")
    if response.status_code == 200:
        downtimes = response.json()
        for downtime in downtimes:
            # Delete each downtime
            downtime_id = downtime["id"]
            delete_response = requests.delete(f"{API_URL}/downtimes/{downtime_id}")
            print(f"Deleted downtime {downtime_id}: {delete_response.status_code}")

# Test functions
def test_car_creation():
    print_test_header("Car Creation")
    created_cars = []
    
    for car_data in test_cars:
        print(f"\nCreating car: {car_data['make']} {car_data['model']} ({car_data['category']})")
        response = requests.post(f"{API_URL}/cars", json=car_data)
        print_response(response)
        
        if assert_status_code(response, 200):
            car = response.json()
            created_cars.append(car)
            assert_field_equals(car, "make", car_data["make"])
            assert_field_equals(car, "model", car_data["model"])
            assert_field_equals(car, "category", car_data["category"])
            assert_field_equals(car, "status", "available")
            assert_field_exists(car, "id")
            assert_field_exists(car, "created_at")
    
    print(f"\n✅ Successfully created {len(created_cars)} cars")
    return created_cars

def test_get_all_cars(expected_count):
    print_test_header("Get All Cars")
    
    response = requests.get(f"{API_URL}/cars")
    print_response(response)
    
    if assert_status_code(response, 200):
        cars = response.json()
        if len(cars) == expected_count:
            print(f"✅ Retrieved {len(cars)} cars as expected")
            return True
        else:
            print(f"❌ Expected {expected_count} cars, got {len(cars)}")
            return False

def test_get_car_by_id(car_id):
    print_test_header(f"Get Car by ID: {car_id}")
    
    response = requests.get(f"{API_URL}/cars/{car_id}")
    print_response(response)
    
    if assert_status_code(response, 200):
        car = response.json()
        assert_field_equals(car, "id", car_id)
        return car
    return None

def test_update_car(car_id):
    print_test_header(f"Update Car: {car_id}")
    
    update_data = {
        "mileage": 25000,
        "status": "in_use"
    }
    
    response = requests.put(f"{API_URL}/cars/{car_id}", json=update_data)
    print_response(response)
    
    if assert_status_code(response, 200):
        car = response.json()
        assert_field_equals(car, "mileage", update_data["mileage"])
        assert_field_equals(car, "status", update_data["status"])
        return True
    return False

def test_delete_car(car_id):
    print_test_header(f"Delete Car: {car_id}")
    
    response = requests.delete(f"{API_URL}/cars/{car_id}")
    print_response(response)
    
    if assert_status_code(response, 200):
        # Verify car is deleted
        get_response = requests.get(f"{API_URL}/cars/{car_id}")
        if get_response.status_code == 404:
            print("✅ Car was successfully deleted")
            return True
        else:
            print(f"❌ Car still exists after deletion, status: {get_response.status_code}")
            return False
    return False

def test_create_downtime(car_id, reason="maintenance"):
    print_test_header(f"Create Downtime for Car: {car_id}")
    
    downtime_data = create_downtime_data(car_id, reason)
    response = requests.post(f"{API_URL}/downtimes", json=downtime_data)
    print_response(response)
    
    if assert_status_code(response, 200):
        downtime = response.json()
        assert_field_equals(downtime, "car_id", car_id)
        assert_field_equals(downtime, "reason", reason)
        assert_field_exists(downtime, "id")
        
        # Check if car status was updated to downtime
        car_response = requests.get(f"{API_URL}/cars/{car_id}")
        if car_response.status_code == 200:
            car = car_response.json()
            if car["status"] == "downtime":
                print("✅ Car status was automatically updated to 'downtime'")
            else:
                print(f"❌ Car status was not updated to 'downtime', current status: {car['status']}")
        
        return downtime
    return None

def test_get_all_downtimes(expected_count):
    print_test_header("Get All Downtimes")
    
    response = requests.get(f"{API_URL}/downtimes")
    print_response(response)
    
    if assert_status_code(response, 200):
        downtimes = response.json()
        if len(downtimes) == expected_count:
            print(f"✅ Retrieved {len(downtimes)} downtimes as expected")
            return True
        else:
            print(f"❌ Expected {expected_count} downtimes, got {len(downtimes)}")
            return False

def test_get_car_downtimes(car_id, expected_count):
    print_test_header(f"Get Downtimes for Car: {car_id}")
    
    response = requests.get(f"{API_URL}/downtimes/car/{car_id}")
    print_response(response)
    
    if assert_status_code(response, 200):
        downtimes = response.json()
        if len(downtimes) == expected_count:
            print(f"✅ Retrieved {len(downtimes)} downtimes for car as expected")
            return downtimes
        else:
            print(f"❌ Expected {expected_count} downtimes for car, got {len(downtimes)}")
            return None

def test_update_downtime(downtime_id):
    print_test_header(f"Update Downtime: {downtime_id}")
    
    update_data = {
        "description": "Updated downtime description",
        "cost": 250.50
    }
    
    response = requests.put(f"{API_URL}/downtimes/{downtime_id}", json=update_data)
    print_response(response)
    
    if assert_status_code(response, 200):
        downtime = response.json()
        assert_field_equals(downtime, "description", update_data["description"])
        assert_field_equals(downtime, "cost", update_data["cost"])
        return True
    return False

def test_delete_downtime(downtime_id):
    print_test_header(f"Delete Downtime: {downtime_id}")
    
    response = requests.delete(f"{API_URL}/downtimes/{downtime_id}")
    print_response(response)
    
    if assert_status_code(response, 200):
        # Verify downtime is deleted
        get_response = requests.get(f"{API_URL}/downtimes")
        if get_response.status_code == 200:
            downtimes = get_response.json()
            for downtime in downtimes:
                if downtime["id"] == downtime_id:
                    print(f"❌ Downtime still exists after deletion")
                    return False
            print("✅ Downtime was successfully deleted")
            return True
    return False

def test_fleet_stats():
    print_test_header("Fleet Statistics")
    
    response = requests.get(f"{API_URL}/fleet/stats")
    print_response(response)
    
    if assert_status_code(response, 200):
        stats = response.json()
        assert_field_exists(stats, "total_cars")
        assert_field_exists(stats, "available_cars")
        assert_field_exists(stats, "in_downtime")
        assert_field_exists(stats, "in_use")
        assert_field_exists(stats, "maintenance")
        
        # Get all cars to verify counts
        cars_response = requests.get(f"{API_URL}/cars")
        if cars_response.status_code == 200:
            cars = cars_response.json()
            
            # Count cars by status
            available_count = sum(1 for car in cars if car["status"] == "available")
            in_use_count = sum(1 for car in cars if car["status"] == "in_use")
            downtime_count = sum(1 for car in cars if car["status"] == "downtime")
            maintenance_count = sum(1 for car in cars if car["status"] == "maintenance")
            
            # Verify counts match
            total_matches = (
                assert_field_equals(stats, "total_cars", len(cars)) and
                assert_field_equals(stats, "available_cars", available_count) and
                assert_field_equals(stats, "in_downtime", downtime_count) and
                assert_field_equals(stats, "in_use", in_use_count) and
                assert_field_equals(stats, "maintenance", maintenance_count)
            )
            
            if total_matches:
                print("✅ All fleet statistics match expected values")
                return True
            else:
                print("❌ Some fleet statistics do not match expected values")
                return False
    return False

def test_fleet_categories():
    print_test_header("Fleet Categories")
    
    response = requests.get(f"{API_URL}/fleet/categories")
    print_response(response)
    
    if assert_status_code(response, 200):
        categories = response.json()
        
        # Get all cars to verify category counts
        cars_response = requests.get(f"{API_URL}/cars")
        if cars_response.status_code == 200:
            cars = cars_response.json()
            
            # Count cars by category
            category_counts = {}
            for car in cars:
                category = car["category"]
                if category in category_counts:
                    category_counts[category] += 1
                else:
                    category_counts[category] = 1
            
            # Verify each category in the response
            all_match = True
            for category_data in categories:
                category = category_data["category"]
                count = category_data["count"]
                
                if category in category_counts:
                    if count == category_counts[category]:
                        print(f"✅ Category '{category}' count matches: {count}")
                    else:
                        print(f"❌ Category '{category}' count mismatch: API={count}, Calculated={category_counts[category]}")
                        all_match = False
                else:
                    print(f"❌ Category '{category}' in API response but not found in cars")
                    all_match = False
            
            # Check for missing categories
            for category, count in category_counts.items():
                if not any(cat_data["category"] == category for cat_data in categories):
                    print(f"❌ Category '{category}' exists in cars but missing from API response")
                    all_match = False
            
            if all_match:
                print("✅ All category counts match expected values")
                return True
            else:
                print("❌ Some category counts do not match expected values")
                return False
    return False

def test_error_handling():
    print_test_header("Error Handling")
    
    # Test invalid car ID
    invalid_id = str(uuid.uuid4())
    response = requests.get(f"{API_URL}/cars/{invalid_id}")
    print(f"Testing invalid car ID: {invalid_id}")
    print_response(response)
    if response.status_code == 404:
        print("✅ Correctly returned 404 for invalid car ID")
    else:
        print(f"❌ Expected 404 for invalid car ID, got {response.status_code}")
    
    # Test missing required fields
    print("\nTesting missing required fields in car creation")
    incomplete_car = {"make": "Test"}
    response = requests.post(f"{API_URL}/cars", json=incomplete_car)
    print_response(response)
    if response.status_code in [400, 422]:
        print("✅ Correctly rejected incomplete car data")
    else:
        print(f"❌ Expected 400/422 for incomplete car data, got {response.status_code}")
    
    # Test invalid data types
    print("\nTesting invalid data types")
    invalid_car = {
        "make": "Toyota",
        "model": "Camry",
        "year": "not-a-number",  # Should be an integer
        "license_plate": "ABC123",
        "vin": "1HGCM82633A123456",
        "mileage": 15000,
        "category": "sedan"
    }
    response = requests.post(f"{API_URL}/cars", json=invalid_car)
    print_response(response)
    if response.status_code in [400, 422]:
        print("✅ Correctly rejected invalid data types")
    else:
        print(f"❌ Expected 400/422 for invalid data types, got {response.status_code}")
    
    return True

def run_all_tests():
    print("\n🚀 Starting Fleet Management API Tests\n")
    
    # Clean up database first
    cleanup_database()
    
    # Test Car Management CRUD APIs
    created_cars = test_car_creation()
    test_get_all_cars(len(created_cars))
    
    # Select a car for detailed testing
    test_car = created_cars[0]
    test_car_id = test_car["id"]
    
    test_get_car_by_id(test_car_id)
    test_update_car(test_car_id)
    
    # Test Downtime Management APIs
    # Create downtimes with different reasons
    downtime_reasons = ["maintenance", "repair", "accident", "cleaning", "inspection", "other"]
    created_downtimes = []
    
    for i, reason in enumerate(downtime_reasons):
        # Use different cars for different reasons
        car_index = i % len(created_cars)
        car_id = created_cars[car_index]["id"]
        downtime = test_create_downtime(car_id, reason)
        if downtime:
            created_downtimes.append(downtime)
    
    test_get_all_downtimes(len(created_downtimes))
    
    # Test downtimes for a specific car
    specific_car_id = created_cars[0]["id"]
    car_downtimes = test_get_car_downtimes(specific_car_id, 
                                          sum(1 for d in created_downtimes if d["car_id"] == specific_car_id))
    
    # Test updating a downtime
    if created_downtimes:
        test_update_downtime(created_downtimes[0]["id"])
    
    # Test Fleet Statistics APIs
    test_fleet_stats()
    test_fleet_categories()
    
    # Test Error Handling
    test_error_handling()
    
    # Test deleting a downtime
    if created_downtimes:
        test_delete_downtime(created_downtimes[0]["id"])
    
    # Test deleting a car
    test_delete_car(created_cars[-1]["id"])
    
    print("\n🏁 All tests completed!\n")

if __name__ == "__main__":
    run_all_tests()