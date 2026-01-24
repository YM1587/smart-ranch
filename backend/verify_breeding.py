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
    # Test breeding record (female animal 5 exists per previous tests)
    payload = {
        "female_id": 5,
        "breeding_date": "2024-01-24",
        "breeding_method": "AI",
        "pregnancy_status": "Pregnant",
        "cost": 1500.0,
        "notes": "Final test"
    }
    test_post("http://127.0.0.1:8000/production/breeding", payload)
