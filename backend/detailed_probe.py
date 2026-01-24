import urllib.request
import json

def test_get(url):
    print(f"Testing GET {url} ...")
    try:
        with urllib.request.urlopen(url) as response:
            print(f"Status: {response.getcode()}")
            print(f"Body: {response.read().decode()}")
    except urllib.error.HTTPError as e:
        print(f"HTTP Error: {e.code}")
        print(f"Error Body: {e.read().decode()}")
    except Exception as e:
        print(f"Failed: {e}")

if __name__ == "__main__":
    test_get("http://127.0.0.1:8000/production/breeding/farmer/1")
    # Also test animals to see if any endpoint works
    test_get("http://127.0.0.1:8000/animals/farmer/1")
