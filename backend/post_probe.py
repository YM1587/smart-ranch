import urllib.request
import json

def test_post(url, data):
    print(f"Testing POST {url} ...")
    try:
        req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), method='POST')
        req.add_header('Content-Type', 'application/json')
        with urllib.request.urlopen(req) as response:
            print(f"Status: {response.getcode()}")
            print(f"Body: {response.read().decode()}")
    except urllib.error.HTTPError as e:
        print(f"HTTP Error: {e.code}")
        print(f"Error Body: {e.read().decode()}")
    except Exception as e:
        print(f"Failed: {e}")

if __name__ == "__main__":
    # Test health record (requires animal 1 or 5 etc)
    # Based on previous test, animal 5 exists
    payload = {
        "animal_id": 5,
        "date": "2024-01-24",
        "condition": "Fever",
        "symptoms": "High temp",
        "treatment": "Antibiotics",
        "cost": 500.0,
        "vet_name": "Dr. Test",
        "notes": "Testing sync"
    }
    test_post("http://127.0.0.1:8000/health/", payload)
