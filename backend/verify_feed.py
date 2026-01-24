import urllib.request
import json

def test_post(url, data):
    print(f"Testing POST {url} ...")
    try:
        req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), method='POST')
        req.add_header('Content-Type', 'application/json')
        with urllib.request.urlopen(req) as response:
            print(f"Status: {response.getcode()}")
            print(f"Body: {json.dumps(json.loads(response.read().decode()), indent=2)}")
    except urllib.error.HTTPError as e:
        print(f"HTTP Error: {e.code}")
        print(f"Error Body: {e.read().decode()}")
    except Exception as e:
        print(f"Failed: {e}")

if __name__ == "__main__":
    # Test individual feed log (animal 5 exists)
    payload = {
        "animal_id": 5,
        "feed_type": "Dairy Meal",
        "quantity_kg": 5.0,
        "cost_per_kg": 40.0,
        "date": "2024-01-24",
        "notes": "Testing feed sync"
    }
    test_post("http://127.0.0.1:8000/feed/individual", payload)
