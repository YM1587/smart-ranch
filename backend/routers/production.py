from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func, and_
from typing import List
from datetime import date, timedelta

from database import get_db
import models
import schemas
from auth import get_current_user

router = APIRouter(
    prefix="/production",
    tags=["Production (Milk & Breeding)"]
)

# --- MILK PRODUCTION ---

@router.post("/milk", response_model=schemas.MilkProduction, status_code=status.HTTP_201_CREATED)
async def create_milk_production(
    production: schemas.MilkProductionCreate, 
    db: AsyncSession = Depends(get_db),
    current_user: models.Farmer = Depends(get_current_user)
):
    # Verify animal ownership
    anim_res = await db.execute(select(models.Animal).where(models.Animal.animal_id == production.animal_id))
    animal = anim_res.scalars().first()
    if not animal or animal.farmer_id != current_user.farmer_id:
        raise HTTPException(status_code=403, detail="Not authorized to log production for this animal")

    new_production = models.MilkProduction(**production.dict())
    db.add(new_production)
    await db.commit()
    await db.refresh(new_production)
    return new_production

@router.get("/milk/animal/{animal_id}", response_model=List[schemas.MilkProduction])
async def read_animal_milk_production(
    animal_id: int, 
    db: AsyncSession = Depends(get_db),
    current_user: models.Farmer = Depends(get_current_user)
):
    # Verify animal ownership
    anim_res = await db.execute(select(models.Animal).where(models.Animal.animal_id == animal_id))
    animal = anim_res.scalars().first()
    if not animal or animal.farmer_id != current_user.farmer_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    result = await db.execute(select(models.MilkProduction).where(models.MilkProduction.animal_id == animal_id))
    return result.scalars().all()

@router.get("/milk/farmer/{farmer_id}", response_model=List[schemas.MilkProduction])
async def read_farmer_milk_production(
    farmer_id: int, 
    db: AsyncSession = Depends(get_db),
    current_user: models.Farmer = Depends(get_current_user)
):
    if current_user.farmer_id != farmer_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    result = await db.execute(
        select(models.MilkProduction)
        .join(models.Animal)
        .where(models.Animal.farmer_id == current_user.farmer_id)
        .order_by(models.MilkProduction.date.desc())
    )
    return result.scalars().all()

# --- WEIGHT RECORDS ---

@router.post("/weight", response_model=schemas.WeightRecord, status_code=status.HTTP_201_CREATED)
async def create_weight_record(
    weight: schemas.WeightRecordCreate, 
    db: AsyncSession = Depends(get_db),
    current_user: models.Farmer = Depends(get_current_user)
):
    # Verify animal ownership
    anim_res = await db.execute(select(models.Animal).where(models.Animal.animal_id == weight.animal_id))
    animal = anim_res.scalars().first()
    if not animal or animal.farmer_id != current_user.farmer_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    new_weight = models.WeightRecord(**weight.dict())
    db.add(new_weight)
    await db.commit()
    await db.refresh(new_weight)
    return new_weight

@router.get("/weight/farmer/{farmer_id}", response_model=List[schemas.WeightRecord])
async def read_farmer_weight_records(
    farmer_id: int, 
    db: AsyncSession = Depends(get_db),
    current_user: models.Farmer = Depends(get_current_user)
):
    if current_user.farmer_id != farmer_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    result = await db.execute(
        select(models.WeightRecord)
        .join(models.Animal)
        .where(models.Animal.farmer_id == current_user.farmer_id)
        .order_by(models.WeightRecord.date.desc())
    )
    return result.scalars().all()

# --- BREEDING RECORDS ---

@router.post("/breeding", response_model=schemas.BreedingRecord, status_code=status.HTTP_201_CREATED)
async def create_breeding_record(
    breeding: schemas.BreedingRecordCreate, 
    db: AsyncSession = Depends(get_db),
    current_user: models.Farmer = Depends(get_current_user)
):
    # Verify female animal ownership
    anim_res = await db.execute(select(models.Animal).where(models.Animal.animal_id == breeding.female_id))
    animal = anim_res.scalars().first()
    if not animal or animal.farmer_id != current_user.farmer_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    new_breeding = models.BreedingRecord(**breeding.dict())
    db.add(new_breeding)
    await db.commit()
    await db.refresh(new_breeding)
    return new_breeding

@router.get("/breeding/farmer/{farmer_id}", response_model=List[schemas.BreedingRecord])
async def read_farmer_breeding_records(
    farmer_id: int, 
    db: AsyncSession = Depends(get_db),
    current_user: models.Farmer = Depends(get_current_user)
):
    if current_user.farmer_id != farmer_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    result = await db.execute(
        select(models.BreedingRecord)
        .join(models.Animal, models.BreedingRecord.female_id == models.Animal.animal_id)
        .where(models.Animal.farmer_id == current_user.farmer_id)
        .order_by(models.BreedingRecord.breeding_date.desc())
    )
    return result.scalars().all()

# --- BREEDING TOOLS ---

@router.get("/breeding-summary")
async def get_breeding_summary(
    farmer_id: int, 
    db: AsyncSession = Depends(get_db),
    current_user: models.Farmer = Depends(get_current_user)
):
    if current_user.farmer_id != farmer_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    preg_res = await db.execute(
        select(func.count(models.BreedingRecord.breeding_id))
        .join(models.Animal, models.BreedingRecord.female_id == models.Animal.animal_id)
        .where(
            and_(
                models.Animal.farmer_id == current_user.farmer_id,
                models.BreedingRecord.pregnancy_status == "Pregnant"
            )
        )
    )
    pregnant_count = preg_res.scalar_one()

    due_res = await db.execute(
        select(func.count(models.BreedingRecord.breeding_id))
        .join(models.Animal, models.BreedingRecord.female_id == models.Animal.animal_id)
        .where(
            and_(
                models.Animal.farmer_id == current_user.farmer_id,
                models.BreedingRecord.pregnancy_status == "Pregnant",
                models.BreedingRecord.expected_calving_date >= date.today()
            )
        )
    )
    due_count = due_res.scalar_one()

    failed_res = await db.execute(
        select(func.count(models.BreedingRecord.breeding_id))
        .join(models.Animal, models.BreedingRecord.female_id == models.Animal.animal_id)
        .where(
            and_(
                models.Animal.farmer_id == current_user.farmer_id,
                models.BreedingRecord.pregnancy_status == "Failed"
            )
        )
    )
    failed_count = failed_res.scalar_one()

    return {
        "pregnant": pregnant_count,
        "due_soon": due_count,
        "failed": failed_count
    }

@router.get("/breeding/pregnant")
async def get_pregnant_animals(
    farmer_id: int, 
    db: AsyncSession = Depends(get_db),
    current_user: models.Farmer = Depends(get_current_user)
):
    if current_user.farmer_id != farmer_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    query = select(models.Animal, models.BreedingRecord).join(
        models.BreedingRecord, models.Animal.animal_id == models.BreedingRecord.female_id
    ).where(
        and_(
            models.Animal.farmer_id == current_user.farmer_id,
            models.BreedingRecord.pregnancy_status == "Pregnant"
        )
    )
    result = await db.execute(query)
    
    return [
        {
            "animal_id": a.animal_id,
            "tag_number": a.tag_number,
            "name": a.name,
            "breeding_id": br.breeding_id,
            "expected_calving_date": br.expected_calving_date,
            "breeding_date": br.breeding_date
        } for a, br in result.all()
    ]

@router.get("/breeding/pending")
async def get_pending_breeding(
    farmer_id: int, 
    db: AsyncSession = Depends(get_db),
    current_user: models.Farmer = Depends(get_current_user)
):
    if current_user.farmer_id != farmer_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    query = select(models.Animal, models.BreedingRecord).join(
        models.BreedingRecord, models.Animal.animal_id == models.BreedingRecord.female_id
    ).where(
        and_(
            models.Animal.farmer_id == current_user.farmer_id,
            models.BreedingRecord.pregnancy_status == "Unknown",
            models.BreedingRecord.actual_calving_date == None
        )
    )
    result = await db.execute(query)
    
    return [
        {
            "animal_id": a.animal_id,
            "tag_number": a.tag_number,
            "name": a.name,
            "breeding_id": br.breeding_id,
            "breeding_date": br.breeding_date,
            "breeding_method": br.breeding_method
        } for a, br in result.all()
    ]

@router.post("/breeding/{breeding_id}/failed")
async def mark_breeding_failed(
    breeding_id: int, 
    db: AsyncSession = Depends(get_db),
    current_user: models.Farmer = Depends(get_current_user)
):
    result = await db.execute(
        select(models.BreedingRecord)
        .join(models.Animal, models.BreedingRecord.female_id == models.Animal.animal_id)
        .where(
            and_(
                models.BreedingRecord.breeding_id == breeding_id,
                models.Animal.farmer_id == current_user.farmer_id
            )
        )
    )
    record = result.scalars().first()
    if not record:
        raise HTTPException(status_code=404, detail="Breeding record not found")
    
    record.pregnancy_status = "Failed"
    await db.commit()
    await db.refresh(record)
    return {"status": "success"}

@router.get("/breeding/due-soon")
async def get_due_soon_animals(
    farmer_id: int, 
    db: AsyncSession = Depends(get_db),
    current_user: models.Farmer = Depends(get_current_user)
):
    if current_user.farmer_id != farmer_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    due_soon_date = date.today() + timedelta(days=14) # Check next 2 weeks
    query = select(models.Animal, models.BreedingRecord).join(
        models.BreedingRecord, models.Animal.animal_id == models.BreedingRecord.female_id
    ).where(
        and_(
            models.Animal.farmer_id == current_user.farmer_id,
            models.BreedingRecord.pregnancy_status == "Pregnant",
            models.BreedingRecord.actual_calving_date == None,
            models.BreedingRecord.expected_calving_date <= due_soon_date
        )
    )
    result = await db.execute(query)
    
    return [
        {
            "animal_id": a.animal_id,
            "tag_number": a.tag_number,
            "name": a.name,
            "breeding_id": br.breeding_id,
            "expected_calving_date": br.expected_calving_date,
            "breeding_date": br.breeding_date
        } for a, br in result.all()
    ]

@router.post("/breeding/{breeding_id}/pregnant")
async def mark_breeding_pregnant(
    breeding_id: int, 
    db: AsyncSession = Depends(get_db),
    current_user: models.Farmer = Depends(get_current_user)
):
    result = await db.execute(
        select(models.BreedingRecord)
        .join(models.Animal, models.BreedingRecord.female_id == models.Animal.animal_id)
        .where(
            and_(
                models.BreedingRecord.breeding_id == breeding_id,
                models.Animal.farmer_id == current_user.farmer_id
            )
        )
    )
    record = result.scalars().first()
    if not record:
        raise HTTPException(status_code=404, detail="Breeding record not found")
    
    record.pregnancy_status = "Pregnant"
    # Estimate calving date (e.g. 283 days for cows)
    record.expected_calving_date = record.breeding_date + timedelta(days=283)
    
    await db.commit()
    await db.refresh(record)
    return {"status": "success", "expected_calving_date": record.expected_calving_date}

@router.post("/breeding/{breeding_id}/calved")
async def mark_breeding_calved(
    breeding_id: int, 
    db: AsyncSession = Depends(get_db),
    current_user: models.Farmer = Depends(get_current_user)
):
    result = await db.execute(
        select(models.BreedingRecord)
        .join(models.Animal, models.BreedingRecord.female_id == models.Animal.animal_id)
        .where(
            and_(
                models.BreedingRecord.breeding_id == breeding_id,
                models.Animal.farmer_id == current_user.farmer_id
            )
        )
    )
    record = result.scalars().first()
    if not record:
        raise HTTPException(status_code=404, detail="Breeding record not found")
    
    record.actual_calving_date = date.today()
    record.pregnancy_status = "Calved"
    
    await db.commit()
    await db.refresh(record)
    return {"status": "success"}
