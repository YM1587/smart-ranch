from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, func, desc
from typing import List
from datetime import date, timedelta

from database import get_db
import models
import schemas
from models import HealthRecord, Animal
from schemas import HealthRecordCreate
from ledger_sync import sync_operation_to_ledger

router = APIRouter(
    prefix="/health",
    tags=["Health"]
)

@router.post("/", response_model=schemas.HealthRecord, status_code=status.HTTP_201_CREATED)
async def create_health_record(record: schemas.HealthRecordCreate, db: AsyncSession = Depends(get_db)):
    new_record = models.HealthRecord(**record.dict())
    db.add(new_record)
    await db.flush()
    
    # Fetch farmer_id from animal
    result = await db.execute(select(models.Animal).where(models.Animal.animal_id == new_record.animal_id))
    animal = result.scalars().first()
    
    if animal:
        await sync_operation_to_ledger(
            db=db,
            farmer_id=animal.farmer_id,
            amount=new_record.cost,
            category="Veterinary",
            description=f"Health treatment for {animal.name or animal.tag_number}: {new_record.condition}",
            source_table="health_record",
            source_id=new_record.record_id,
            transaction_date=new_record.date,
            related_animal_id=new_record.animal_id
        )
    
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

# --- HEALTH INTELLIGENCE ENDPOINTS ---

@router.get("/status-summary")
async def get_health_summary(farmer_id: int, db: AsyncSession = Depends(get_db)):
    sick_query = select(func.count(HealthRecord.record_id)).join(Animal).where(
        and_(
            Animal.farmer_id == farmer_id,
            HealthRecord.next_checkup_date == None,
            HealthRecord.date >= date.today() - timedelta(days=7)
        )
    )
    sick_result = await db.execute(sick_query)
    sick_count = sick_result.scalar_one()

    under_treatment_query = select(func.count(HealthRecord.record_id)).join(Animal).where(
        and_(
            Animal.farmer_id == farmer_id,
            HealthRecord.next_checkup_date >= date.today()
        )
    )
    under_treatment_result = await db.execute(under_treatment_query)
    under_treatment_count = under_treatment_result.scalar_one()

    return {
        "sick": sick_count,
        "under_treatment": under_treatment_count
    }

@router.get("/sick")
async def get_sick_animals(farmer_id: int, db: AsyncSession = Depends(get_db)):
    query = select(Animal, HealthRecord).join(
        HealthRecord, Animal.animal_id == HealthRecord.animal_id
    ).where(
        and_(
            Animal.farmer_id == farmer_id,
            HealthRecord.next_checkup_date == None,
            HealthRecord.date >= date.today() - timedelta(days=7)
        )
    )
    result = await db.execute(query)
    
    return [
        {
            "animal_id": a.animal_id,
            "tag_number": a.tag_number,
            "name": a.name,
            "condition": hr.condition,
            "date": hr.date,
            "status": "Sick",
            "record_id": hr.record_id
        } for a, hr in result.all()
    ]

@router.post("/{record_id}/resolve")
async def resolve_health_record(record_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.HealthRecord).where(models.HealthRecord.record_id == record_id))
    record = result.scalars().first()
    if not record:
        raise HTTPException(status_code=404, detail="Health record not found")
    
    # Resolves the condition by scheduling a checkup today
    record.next_checkup_date = date.today()
    await db.commit()
    await db.refresh(record)
    return {"status": "resolved"}

@router.get("/under-treatment")
async def get_under_treatment_animals(farmer_id: int, db: AsyncSession = Depends(get_db)):
    query = select(Animal, HealthRecord).join(
        HealthRecord, Animal.animal_id == HealthRecord.animal_id
    ).where(
        and_(
            Animal.farmer_id == farmer_id,
            HealthRecord.next_checkup_date >= date.today()
        )
    )
    result = await db.execute(query)
    
    return [
        {
            "animal_id": a.animal_id,
            "tag_number": a.tag_number,
            "name": a.name,
            "condition": hr.condition,
            "next_checkup": hr.next_checkup_date,
            "status": "Under Treatment"
        } for a, hr in result.all()
    ]

@router.get("/recovered")
async def get_recovered_animals(farmer_id: int, db: AsyncSession = Depends(get_db)):
    query = select(Animal, HealthRecord).join(
        HealthRecord, Animal.animal_id == HealthRecord.animal_id
    ).where(
        and_(
            Animal.farmer_id == farmer_id,
            HealthRecord.next_checkup_date < date.today()
        )
    ).order_by(desc(HealthRecord.date))
    result = await db.execute(query)
    
    return [
        {
            "animal_id": a.animal_id,
            "tag_number": a.tag_number,
            "name": a.name,
            "condition": hr.condition,
            "recovery_date": hr.next_checkup_date,
            "status": "Recovered"
        } for a, hr in result.all()
    ]
