from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List

from database import get_db
import models
import schemas

router = APIRouter(
    prefix="/feed",
    tags=["Feed"]
)

# --- PEN FEED LOGS ---
@router.post("/pen", response_model=schemas.FeedLog, status_code=status.HTTP_201_CREATED)
async def create_feed_log(log: schemas.FeedLogCreate, db: AsyncSession = Depends(get_db)):
    new_log = models.FeedLog(**log.dict())
    db.add(new_log)
    await db.commit()
    await db.refresh(new_log)
    return new_log

@router.get("/pen/{pen_id}", response_model=List[schemas.FeedLog])
async def read_feed_logs(pen_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.FeedLog).where(models.FeedLog.pen_id == pen_id))
    return result.scalars().all()

# --- INDIVIDUAL FEED LOGS ---
@router.post("/individual", response_model=schemas.IndividualFeedLog, status_code=status.HTTP_201_CREATED)
async def create_individual_feed_log(log: schemas.IndividualFeedLogCreate, db: AsyncSession = Depends(get_db)):
    new_log = models.IndividualFeedLog(**log.dict())
    db.add(new_log)
    await db.commit()
    await db.refresh(new_log)
    return new_log

@router.get("/individual/{animal_id}", response_model=List[schemas.IndividualFeedLog])
async def read_individual_feed_logs(animal_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.IndividualFeedLog).where(models.IndividualFeedLog.animal_id == animal_id))
    return result.scalars().all()

@router.get("/farmer/{farmer_id}/pen", response_model=List[schemas.FeedLog])
async def read_farmer_pen_feed_logs(farmer_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.FeedLog)
        .join(models.AnimalPen, models.FeedLog.pen_id == models.AnimalPen.pen_id)
        .where(models.AnimalPen.farmer_id == farmer_id)
    )
    return result.scalars().all()

@router.get("/farmer/{farmer_id}/individual", response_model=List[schemas.IndividualFeedLog])
async def read_farmer_individual_feed_logs(farmer_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.IndividualFeedLog)
        .join(models.Animal, models.IndividualFeedLog.animal_id == models.Animal.animal_id)
        .where(models.Animal.farmer_id == farmer_id)
    )
    return result.scalars().all()
