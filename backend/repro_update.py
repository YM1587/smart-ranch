import requests
import json

BASE_URL = "http://127.0.0.1:8000"

def test_update_animal(animal_id):
    data = {
        "farmer_id": 1,
        "pen_id": 1,
        "tag_number": "CP001",
        "name": "Winnie Updated",
        "animal_type": "Dairy",
        "breed": "Sahiwal",
        "gender": "Female",
        "acquisition_type": "Born-on-farm",
        "acquisition_cost": 0.0
    }
    url = f"{BASE_URL}/animals/{animal_id}"
    print(f"PUT {url}")
    print(f"Data: {json.dumps(data)}")
    
    try:
        response = requests.put(url, json=data)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
    except Exception as e:
        print(f"Failed: {e}")

if __name__ == "__main__":
    test_update_animal(2)
