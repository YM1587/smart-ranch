import requests
import json
import random
import string

BASE_URL = "http://127.0.0.1:8000"

def random_string(length=8):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def test_root():
    try:
        response = requests.get(f"{BASE_URL}/")
        print(f"Root: {response.status_code} - {response.json()}")
    except Exception as e:
        print(f"Root failed: {e}")

def test_create_farmer():
    username = f"farmer_{random_string()}"
    data = {
        "username": username,
        "password": "password123",
        "full_name": "Test Farmer",
        "phone_number": "1234567890",
        "farm_name": "Test Farm",
        "location": "Test Location",
        "farm_type": "Dairy"
    }
    try:
        response = requests.post(f"{BASE_URL}/farmers/", json=data)
        print(f"Create Farmer: {response.status_code}")
        if response.status_code == 201:
            return response.json().get("farmer_id")
        else:
            print(response.text)
            return None
    except Exception as e:
        print(f"Create Farmer failed: {e}")
        return None

def test_create_pen(farmer_id):
    data = {
        "pen_name": "Test Pen",
        "pen_type": "Milking Cows",
        "capacity": 20,
        "description": "Main milking pen",
        "farmer_id": farmer_id
    }
    try:
        response = requests.post(f"{BASE_URL}/animals/pens", json=data)
        print(f"Create Pen: {response.status_code}")
        if response.status_code == 201:
            return response.json().get("pen_id")
        else:
            print(response.text)
            return None
    except Exception as e:
        print(f"Create Pen failed: {e}")
        return None

def test_create_animal(farmer_id, pen_id):
    tag = f"COW-{random_string(4)}"
    data = {
        "farmer_id": farmer_id,
        "pen_id": pen_id,
        "tag_number": tag,
        "animal_type": "Dairy",
        "breed": "Friesian",
        "gender": "Female",
        "acquisition_type": "Born-on-farm",
        "acquisition_cost": 0,
        "status": "Active"
    }
    try:
        response = requests.post(f"{BASE_URL}/animals/", json=data)
        print(f"Create Animal: {response.status_code}")
        if response.status_code == 201:
            return response.json().get("animal_id")
        else:
            print(response.text)
            return None
    except Exception as e:
        print(f"Create Animal failed: {e}")
        return None

def test_create_milk_production(animal_id):
    data = {
        "animal_id": animal_id,
        "date": "2023-10-27",
        "morning_yield": 12.5,
        "evening_yield": 10.0
    }
    try:
        response = requests.post(f"{BASE_URL}/production/milk", json=data)
        print(f"Create Milk Production: {response.status_code}")
    except Exception as e:
        print(f"Create Milk Production failed: {e}")

def test_create_feed_log(pen_id):
    data = {
        "pen_id": pen_id,
        "feed_type": "Dairy Meal",
        "quantity_kg": 50,
        "cost_per_kg": 45,
        "date": "2023-10-27"
    }
    try:
        response = requests.post(f"{BASE_URL}/feed/pen", json=data)
        print(f"Create Feed Log: {response.status_code}")
    except Exception as e:
        print(f"Create Feed Log failed: {e}")

if __name__ == "__main__":
    print("Testing API...")
    test_root()
    farmer_id = test_create_farmer()
    if farmer_id:
        pen_id = test_create_pen(farmer_id)
        if pen_id:
            animal_id = test_create_animal(farmer_id, pen_id)
            if animal_id:
                test_create_milk_production(animal_id)
            test_create_feed_log(pen_id)
