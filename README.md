# Smart Ranch Management System (SRMS)

A scalable, mobile-based management system for smallholder livestock farmers, built with Flutter and FastAPI.

## 🚀 Migration & Setup Guide

This project is set up for cross-machine development. Follow these steps to migrate or install the system on a new machine.

### Phase 1: Preparation (Current Machine)
Before pushing to GitHub, ensure your `.gitignore` is in place.
1. **GitHub Push**:
```powershell
git init
git add .
git commit -m "Complete project setup"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/smart-ranch-system.git
git push -u origin main
```

---

### Phase 2: Installation (New Machine)

#### 1. Prerequisites
- **Python 3.10+**
- **PostgreSQL 14+**
- **Flutter SDK**
- **Git**

#### 2. Clone and Initialize
```powershell
git clone https://github.com/YOUR_USERNAME/smart-ranch-system.git
cd "smart ranch system"
```

#### 3. Database Setup
1. Create a database named `smartranch` in PostgreSQL.
2. Run the initialization script:
```powershell
psql -U postgres -d smartranch -f init.sql
```

#### 4. Backend (FastAPI) Setup
```powershell
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```
*Note: Point `backend/database.py` to your local DB instance.*

#### 5. Frontend (Flutter) Setup
```powershell
cd ../mobile_app
flutter pub get
# Start an Android Emulator or connect a device
flutter run
```

---

## 📱 Mobile Connectivity
- **Web (Chrome)**: Uses `http://127.0.0.1:8000`
- **Android Emulator**: Uses `http://10.0.2.2:8000`
- **Physical Device**: Use your computer's local IP (e.g., `http://192.168.1.5:8000`) in `lib/services/api_service.dart`.

## 🛠️ Architecture
- **Frontend**: Flutter (Cross-platform)
- **Backend**: FastAPI (Asynchronous Python)
- **Database**: PostgreSQL (HTAP Optimized)
