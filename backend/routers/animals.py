from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List

from database import get_db
import models
import schemas

router = APIRouter(
    prefix="/animals",
    tags=["Animals & Pens"]
)

# --- PENS ---
@router.post("/pens", response_model=schemas.AnimalPen, status_code=status.HTTP_201_CREATED)
async def create_pen(pen: schemas.AnimalPenCreate, db: AsyncSession = Depends(get_db)):
    new_pen = models.AnimalPen(**pen.dict())
    db.add(new_pen)
    await db.commit()
    await db.refresh(new_pen)
    return new_pen

@router.get("/pens/farmer/{farmer_id}", response_model=List[schemas.AnimalPen])
async def read_pens(farmer_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.AnimalPen).where(models.AnimalPen.farmer_id == farmer_id))
    return result.scalars().all()

# --- ANIMALS ---
@router.post("/", response_model=schemas.Animal, status_code=status.HTTP_201_CREATED)
async def create_animal(animal: schemas.AnimalCreate, db: AsyncSession = Depends(get_db)):
    # Check if tag exists for this farmer
    result = await db.execute(
        select(models.Animal).where(
            (models.Animal.tag_number == animal.tag_number) & 
            (models.Animal.farmer_id == animal.farmer_id)
        )
    )
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="Tag number already exists for this farmer")

    new_animal = models.Animal(**animal.dict())
    db.add(new_animal)
    await db.commit()
    await db.refresh(new_animal)
    return new_animal

@router.get("/farmer/{farmer_id}", response_model=List[schemas.Animal])
async def read_animals(farmer_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.Animal).where(models.Animal.farmer_id == farmer_id))
    return result.scalars().all()

@router.get("/{animal_id}", response_model=schemas.Animal)
async def read_animal(animal_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.Animal).where(models.Animal.animal_id == animal_id))
    animal = result.scalars().first()
    if animal is None:
        raise HTTPException(status_code=404, detail="Animal not found")
    return animal
