from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List

from database import get_db
import models
import schemas

router = APIRouter(
    prefix="/production",
    tags=["Production"]
)

# --- MILK PRODUCTION ---
@router.post("/milk", response_model=schemas.MilkProduction, status_code=status.HTTP_201_CREATED)
async def create_milk_production(production: schemas.MilkProductionCreate, db: AsyncSession = Depends(get_db)):
    new_production = models.MilkProduction(**production.dict())
    db.add(new_production)
    await db.commit()
    await db.refresh(new_production)
    return new_production

@router.get("/milk/animal/{animal_id}", response_model=List[schemas.MilkProduction])
async def read_milk_production_by_animal(animal_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.MilkProduction).where(models.MilkProduction.animal_id == animal_id))
    return result.scalars().all()

# --- WEIGHT RECORDS ---
@router.post("/weight", response_model=schemas.WeightRecord, status_code=status.HTTP_201_CREATED)
async def create_weight_record(record: schemas.WeightRecordCreate, db: AsyncSession = Depends(get_db)):
    new_record = models.WeightRecord(**record.dict())
    db.add(new_record)
    await db.commit()
    await db.refresh(new_record)
    return new_record

@router.get("/weight/animal/{animal_id}", response_model=List[schemas.WeightRecord])
async def read_weight_records_by_animal(animal_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.WeightRecord).where(models.WeightRecord.animal_id == animal_id))
    return result.scalars().all()

# --- BREEDING RECORDS ---
@router.post("/breeding", response_model=schemas.BreedingRecord, status_code=status.HTTP_201_CREATED)
async def create_breeding_record(record: schemas.BreedingRecordCreate, db: AsyncSession = Depends(get_db)):
    new_record = models.BreedingRecord(**record.dict())
    db.add(new_record)
    await db.commit()
    await db.refresh(new_record)
    return new_record

@router.get("/breeding/animal/{animal_id}", response_model=List[schemas.BreedingRecord])
async def read_breeding_records_by_animal(animal_id: int, db: AsyncSession = Depends(get_db)):
    # Get records where animal is female or male
    result = await db.execute(
        select(models.BreedingRecord).where(
            (models.BreedingRecord.female_id == animal_id) | 
            (models.BreedingRecord.male_id == animal_id)
        )
    )
    return result.scalars().all()
@router.put("/breeding/{breeding_id}", response_model=schemas.BreedingRecord)
async def update_breeding_record(breeding_id: int, record: schemas.BreedingRecordUpdate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.BreedingRecord).where(models.BreedingRecord.breeding_id == breeding_id))
    db_record = result.scalars().first()
    if not db_record:
        raise HTTPException(status_code=404, detail="Breeding record not found")
    
    update_data = record.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_record, key, value)
    
    await db.commit()
    await db.refresh(db_record)
    return db_record
