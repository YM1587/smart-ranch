import asyncio
from database import SessionLocal
import models
from sqlalchemy.future import select

async def debug_db():
    async with SessionLocal() as db:
        try:
            print("Querying pens...")
            result = await db.execute(select(models.AnimalPen).where(models.AnimalPen.farmer_id == 1))
            pens = result.scalars().all()
            print(f"Pens found: {len(pens)}")
            for p in pens:
                print(f"ID: {p.pen_id}, Name: {p.pen_name}, Type: {p.pen_type}")
            
            print("\nQuerying animals...")
            result = await db.execute(select(models.Animal).where(models.Animal.farmer_id == 1))
            animals = result.scalars().all()
            print(f"Animals found: {len(animals)}")
            for a in animals:
                print(f"ID: {a.animal_id}, Tag: {a.tag_number}, Name: {a.name}, Type: {a.animal_type}, Sex: {a.gender}, PenID: {a.pen_id}")
        except Exception as e:
            print(f"Error: {e}")
            import traceback
            traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(debug_db())
