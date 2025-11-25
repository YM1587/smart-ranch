from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List
import database
import models
import schemas

router = APIRouter()

# --- PENS ---
@router.post("/pens/", response_model=schemas.Pen)
async def create_pen(pen: schemas.PenCreate, db: AsyncSession = Depends(database.get_db)):
    db_pen = models.Pen(**pen.dict())
    db.add(db_pen)
    await db.commit()
    await db.refresh(db_pen)
    return db_pen

@router.get("/pens/", response_model=List[schemas.Pen])
async def read_pens(skip: int = 0, limit: int = 100, db: AsyncSession = Depends(database.get_db)):
    result = await db.execute(select(models.Pen).offset(skip).limit(limit))
    return result.scalars().all()

@router.get("/pens/{pen_id}", response_model=schemas.Pen)
async def read_pen(pen_id: int, db: AsyncSession = Depends(database.get_db)):
    result = await db.execute(select(models.Pen).where(models.Pen.id == pen_id))
    pen = result.scalars().first()
    if pen is None:
        raise HTTPException(status_code=404, detail="Pen not found")
    return pen

# --- ANIMALS ---
@router.post("/animals/", response_model=schemas.Animal)
async def create_animal(animal: schemas.AnimalCreate, db: AsyncSession = Depends(database.get_db)):
    db_animal = models.Animal(**animal.dict())
    db.add(db_animal)
    await db.commit()
    await db.refresh(db_animal)
    return db_animal

@router.get("/animals/", response_model=List[schemas.Animal])
async def read_animals(skip: int = 0, limit: int = 100, db: AsyncSession = Depends(database.get_db)):
    result = await db.execute(select(models.Animal).offset(skip).limit(limit))
    return result.scalars().all()

@router.get("/animals/{animal_id}", response_model=schemas.Animal)
async def read_animal(animal_id: int, db: AsyncSession = Depends(database.get_db)):
    result = await db.execute(select(models.Animal).where(models.Animal.id == animal_id))
    animal = result.scalars().first()
    if animal is None:
        raise HTTPException(status_code=404, detail="Animal not found")
    return animal
