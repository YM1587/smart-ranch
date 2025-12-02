from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List

from database import get_db
import models
import schemas

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
    return new_activity

@router.get("/farmer/{farmer_id}", response_model=List[schemas.LaborActivity])
async def read_labor_activities(farmer_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.LaborActivity).where(models.LaborActivity.farmer_id == farmer_id))
    return result.scalars().all()
