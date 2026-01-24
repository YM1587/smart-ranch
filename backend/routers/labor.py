from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List

from database import get_db
import models
import schemas
from ledger_sync import sync_operation_to_ledger

router = APIRouter(
    prefix="/labor",
    tags=["Labor"]
)

@router.post("/", response_model=schemas.LaborActivity, status_code=status.HTTP_201_CREATED)
async def create_labor_activity(activity: schemas.LaborActivityCreate, db: AsyncSession = Depends(get_db)):
    new_activity = models.LaborActivity(**activity.dict())
    db.add(new_activity)
    await db.commit()
    await db.refresh(new_activity)
    
    await sync_operation_to_ledger(
        db=db,
        farmer_id=new_activity.farmer_id,
        amount=new_activity.labor_cost,
        category="Labor",
        description=f"Labor activity: {new_activity.activity_type}",
        source_table="labor_activity",
        source_id=new_activity.activity_id,
        transaction_date=new_activity.date,
        related_animal_id=new_activity.related_animal_id,
        related_pen_id=new_activity.related_pen_id
    )
    await db.commit()

    return new_activity

@router.get("/farmer/{farmer_id}", response_model=List[schemas.LaborActivity])
async def read_labor_activities(farmer_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.LaborActivity).where(models.LaborActivity.farmer_id == farmer_id))
    return result.scalars().all()
