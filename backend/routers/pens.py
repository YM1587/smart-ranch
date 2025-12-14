from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List
from database import get_db
import models
import schemas

router = APIRouter(
    prefix="/pens",
    tags=["Pens"]
)

@router.get("/", response_model=List[schemas.AnimalPen])
async def get_pens(farmer_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.AnimalPen).filter(models.AnimalPen.farmer_id == farmer_id))
    return result.scalars().all()

@router.post("/", response_model=schemas.AnimalPen, status_code=status.HTTP_201_CREATED)
async def create_pen(pen: schemas.AnimalPenCreate, db: AsyncSession = Depends(get_db)):
    new_pen = models.AnimalPen(**pen.dict())
    db.add(new_pen)
    await db.commit()
    await db.refresh(new_pen)
    return new_pen
