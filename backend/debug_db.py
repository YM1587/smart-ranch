from database import SessionLocal
import models

db = SessionLocal()
try:
    print("Querying pens...")
    pens = db.query(models.AnimalPen).filter(models.AnimalPen.farmer_id == 1).all()
    print(f"Pens found: {len(pens)}")
    for p in pens:
        print(f"ID: {p.pen_id}, Name: {p.pen_name}")
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
finally:
    db.close()
