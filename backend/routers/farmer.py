from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List

from database import get_db
import models
import schemas

router = APIRouter(
    prefix="/farmers",
    tags=["Farmers"]
)

@router.post("/", response_model=schemas.Farmer, status_code=status.HTTP_201_CREATED)
async def create_farmer(farmer: schemas.FarmerCreate, db: AsyncSession = Depends(get_db)):
    # Check if username exists
    result = await db.execute(select(models.Farmer).where(models.Farmer.username == farmer.username))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="Username already registered")
    
    # In a real app, hash the password here
    new_farmer = models.Farmer(
        username=farmer.username,
        password_hash=farmer.password, # TODO: Hash this
        full_name=farmer.full_name,
        phone_number=farmer.phone_number,
        farm_name=farmer.farm_name,
        location=farmer.location,
        farm_type=farmer.farm_type
    )
    db.add(new_farmer)
    await db.commit()
    await db.refresh(new_farmer)
    return new_farmer

@router.get("/{farmer_id}", response_model=schemas.Farmer)
async def read_farmer(farmer_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.Farmer).where(models.Farmer.farmer_id == farmer_id))
    farmer = result.scalars().first()
    if farmer is None:
        raise HTTPException(status_code=404, detail="Farmer not found")
    return farmer
