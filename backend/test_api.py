import requests
import json

BASE_URL = "http://127.0.0.1:8000"

def test_root():
    try:
        response = requests.get(f"{BASE_URL}/")
        print(f"Root: {response.status_code} - {response.json()}")
    except Exception as e:
        print(f"Root failed: {e}")

def test_create_pen():
    pen_data = {
        "name": "Test Pen 1",
        "livestock_type": "Cattle",
        "capacity": 10
    }
    try:
        response = requests.post(f"{BASE_URL}/pens/", json=pen_data)
        print(f"Create Pen: {response.status_code} - {response.json()}")
        return response.json().get("id")
    except Exception as e:
        print(f"Create Pen failed: {e}")
        return None

def test_create_animal(pen_id):
    if not pen_id:
        print("Skipping Animal test due to missing Pen ID")
        return

    animal_data = {
        "tag_number": "COW-001",
        "pen_id": pen_id,
        "breed": "Friesian",
        "sex": "Female",
        "status": "Active"
    }
    try:
        response = requests.post(f"{BASE_URL}/animals/", json=animal_data)
        print(f"Create Animal: {response.status_code} - {response.json()}")
    except Exception as e:
        print(f"Create Animal failed: {e}")

if __name__ == "__main__":
    print("Testing API...")
    test_root()
    pen_id = test_create_pen()
    test_create_animal(pen_id)
