from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List

from database import get_db
import models
import schemas
from ledger_sync import sync_operation_to_ledger

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

@router.post("/breeding", response_model=schemas.BreedingRecord, status_code=status.HTTP_201_CREATED)
async def create_breeding_record(record: schemas.BreedingRecordCreate, db: AsyncSession = Depends(get_db)):
    new_record = models.BreedingRecord(**record.dict())
    db.add(new_record)
    await db.flush()
    
    # Fetch farmer_id from female animal
    result = await db.execute(select(models.Animal).where(models.Animal.animal_id == new_record.female_id))
    animal = result.scalars().first()
    
    if animal:
        await sync_operation_to_ledger(
            db=db,
            farmer_id=animal.farmer_id,
            amount=new_record.cost,
            category="Breeding Costs",
            description=f"Breeding event for {animal.name or animal.tag_number}",
            source_table="breeding_record",
            source_id=new_record.breeding_id,
            transaction_date=new_record.breeding_date,
            related_animal_id=new_record.female_id
        )

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

@router.get("/milk/farmer/{farmer_id}", response_model=List[schemas.MilkProduction])
async def read_farmer_milk_production(farmer_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.MilkProduction)
        .join(models.Animal, models.MilkProduction.animal_id == models.Animal.animal_id)
        .where(models.Animal.farmer_id == farmer_id)
    )
    return result.scalars().all()

@router.get("/weight/farmer/{farmer_id}", response_model=List[schemas.WeightRecord])
async def read_farmer_weight_records(farmer_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.WeightRecord)
        .join(models.Animal, models.WeightRecord.animal_id == models.Animal.animal_id)
        .where(models.Animal.farmer_id == farmer_id)
    )
    return result.scalars().all()

@router.get("/breeding/farmer/{farmer_id}", response_model=List[schemas.BreedingRecord])
async def read_farmer_breeding_records(farmer_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.BreedingRecord)
        .join(models.Animal, models.BreedingRecord.female_id == models.Animal.animal_id)
        .where(models.Animal.farmer_id == farmer_id)
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
    
    await db.flush()
    
    # Fetch farmer_id from female animal
    res = await db.execute(select(models.Animal).where(models.Animal.animal_id == db_record.female_id))
    animal = res.scalars().first()
    if animal:
        await sync_operation_to_ledger(
            db=db,
            farmer_id=animal.farmer_id,
            amount=db_record.cost,
            category="Breeding Costs",
            description=f"Breeding event update for {animal.name or animal.tag_number}",
            source_table="breeding_record",
            source_id=db_record.breeding_id,
            transaction_date=db_record.breeding_date,
            related_animal_id=db_record.female_id
        )

    await db.commit()
    await db.refresh(db_record)
    return db_record
