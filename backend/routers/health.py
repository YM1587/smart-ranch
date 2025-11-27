from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List
import database
import models
import schemas

router = APIRouter()

@router.post("/health/", response_model=schemas.HealthEvent)
async def create_health_event(event: schemas.HealthEventCreate, db: AsyncSession = Depends(database.get_db)):
    db_event = models.HealthEvent(**event.dict())
    db.add(db_event)
    await db.commit()
    await db.refresh(db_event)
    return db_event

@router.get("/health/", response_model=List[schemas.HealthEvent])
async def read_all_health_events(skip: int = 0, limit: int = 100, db: AsyncSession = Depends(database.get_db)):
    result = await db.execute(select(models.HealthEvent).order_by(models.HealthEvent.date.desc()).offset(skip).limit(limit))
    return result.scalars().all()

@router.get("/health/animal/{animal_id}", response_model=List[schemas.HealthEvent])
async def read_health_events_by_animal(animal_id: int, db: AsyncSession = Depends(database.get_db)):
    result = await db.execute(select(models.HealthEvent).where(models.HealthEvent.animal_id == animal_id))
    return result.scalars().all()
