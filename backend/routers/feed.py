from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List

from database import get_db
import models
import schemas
from ledger_sync import sync_operation_to_ledger

router = APIRouter(
    prefix="/feed",
    tags=["Feed"]
)

# --- PEN FEED LOGS ---
@router.post("/pen", response_model=schemas.FeedLog, status_code=status.HTTP_201_CREATED)
async def create_feed_log(log: schemas.FeedLogCreate, db: AsyncSession = Depends(get_db)):
    new_log = models.FeedLog(**log.dict())
    db.add(new_log)
    await db.flush()
    
    # Fetch farmer_id from pen
    result = await db.execute(select(models.AnimalPen).where(models.AnimalPen.pen_id == new_log.pen_id))
    pen = result.scalars().first()
    
    if pen:
        await sync_operation_to_ledger(
            db=db,
            farmer_id=pen.farmer_id,
            amount=new_log.quantity_kg * new_log.cost_per_kg,
            category="Feed",
            description=f"Feed ({new_log.feed_type}) for Pen {pen.pen_name}",
            source_table="feed_log",
            source_id=new_log.log_id,
            transaction_date=new_log.date,
            related_pen_id=new_log.pen_id
        )
    
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
    await db.flush()
    
    # Fetch farmer_id from animal
    result = await db.execute(select(models.Animal).where(models.Animal.animal_id == new_log.animal_id))
    animal = result.scalars().first()
    
    if animal:
        await sync_operation_to_ledger(
            db=db,
            farmer_id=animal.farmer_id,
            amount=new_log.quantity_kg * new_log.cost_per_kg,
            category="Feed",
            description=f"Individual feed ({new_log.feed_type}) for {animal.name or animal.tag_number}",
            source_table="individual_feed_log",
            source_id=new_log.individual_feed_id,
            transaction_date=new_log.date,
            related_animal_id=new_log.animal_id
        )

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
