from datetime import datetime, timedelta
from jose import jwt

SECRET_KEY = "your-secret-key-for-smart-ranch-development"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 43200

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# Test
token = create_access_token({"sub": "testuser"})
payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
exp = datetime.utcfromtimestamp(payload['exp'])
now = datetime.utcnow()
diff = exp - now
print(f"Token expires in: {diff}")
print(f"Total minutes: {diff.total_seconds() / 60}")
