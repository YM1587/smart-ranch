from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List

from database import get_db
import models
import schemas

router = APIRouter(
    prefix="/health",
    tags=["Health"]
)

@router.post("/", response_model=schemas.HealthRecord, status_code=status.HTTP_201_CREATED)
async def create_health_record(record: schemas.HealthRecordCreate, db: AsyncSession = Depends(get_db)):
    new_record = models.HealthRecord(**record.dict())
    db.add(new_record)
    await db.commit()
    await db.refresh(new_record)
    return new_record

@router.get("/animal/{animal_id}", response_model=List[schemas.HealthRecord])
async def read_health_records(animal_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.HealthRecord).where(models.HealthRecord.animal_id == animal_id))
    return result.scalars().all()

@router.get("/farmer/{farmer_id}", response_model=List[schemas.HealthRecord])
async def read_farmer_health_records(farmer_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.HealthRecord)
        .join(models.Animal, models.HealthRecord.animal_id == models.Animal.animal_id)
        .where(models.Animal.farmer_id == farmer_id)
    )
    return result.scalars().all()
