import asyncio
import httpx

async def test_endpoints():
    async with httpx.AsyncClient() as client:
        # Test GET breeding records
        print("Testing GET /production/breeding/farmer/1 ...")
        try:
            resp = await client.get("http://127.0.0.1:8000/production/breeding/farmer/1")
            print(f"Status: {resp.status_code}")
            if resp.status_code != 200:
                print(f"Error Body: {resp.text}")
        except Exception as e:
            print(f"Connection failed: {e}")

        # Test health record creation mock (this checks if ledger_sync is working)
        # Note: This might fail if farmer/animal 1 doesn't exist, but we want to see the error type
        print("\nTesting POST /health/ ...")
        try:
            payload = {
                "animal_id": 1,
                "date": "2024-01-24",
                "condition": "Test Condition",
                "symptoms": "Test Symptoms",
                "treatment": "Test Treatment",
                "cost": 100.0
            }
            resp = await client.post("http://127.0.0.1:8000/health/", json=payload)
            print(f"Status: {resp.status_code}")
            if resp.status_code != 201:
                print(f"Error Body: {resp.text}")
        except Exception as e:
            print(f"Connection failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_endpoints())
