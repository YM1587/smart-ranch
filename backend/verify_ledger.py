import urllib.request
import json

def test_get(url):
    print(f"Testing GET {url} ...")
    try:
        with urllib.request.urlopen(url) as response:
            print(f"Status: {response.getcode()}")
            data = json.loads(response.read().decode())
            # Find the most recent transaction
            if data:
                # Assuming id is transaction_id
                latest = max(data, key=lambda x: x['transaction_id'])
                print(f"Latest Transaction: {json.dumps(latest, indent=2)}")
            else:
                print("No transactions found.")
    except Exception as e:
        print(f"Failed: {e}")

if __name__ == "__main__":
    test_get("http://127.0.0.1:8000/finance/farmer/1")
