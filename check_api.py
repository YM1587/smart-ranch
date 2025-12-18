import requests
import json

BASE_URL = "http://127.0.0.1:8000"

def check_animals():
    try:
        response = requests.get(f"{BASE_URL}/animals/")
        if response.status_code == 200:
            animals = response.json()
            print(f"Total animals: {len(animals)}")
            if animals:
                print(f"Raw first animal: {json.dumps(animals[0], indent=2)}")
            for a in animals:
                print(f"ID: {a.get('animal_id')}, Tag: {a.get('tag_number')}, Name: {a.get('name')}")
        else:
            print(f"Error: {response.status_code}, {response.text}")
    except Exception as e:
        print(f"Exception: {e}")

def test_update():
    try:
        data = {"name": "Test Update"}
        response = requests.put(f"{BASE_URL}/animals/4", json=data)
        print(f"PUT /animals/4: {response.status_code}, {response.text}")
    except Exception as e:
        print(f"Exception in PUT: {e}")

if __name__ == "__main__":
    check_animals()
    test_update()
