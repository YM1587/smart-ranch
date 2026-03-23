from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import and_, or_, func, desc
from typing import List
from datetime import date, timedelta

from database import get_db
import models
import schemas
from models import Alert, Animal, HealthRecord, BreedingRecord, MilkProduction, WeightRecord

router = APIRouter(
    prefix="/alerts",
    tags=["Alerts"]
)

@router.get("/")
async def get_alerts(farmer_id: int, db: AsyncSession = Depends(get_db)):
    # 1. First, dynamically generate alerts if needed
    await generate_dynamic_alerts(farmer_id, db)
    
    # 2. Fetch active, non-dismissed alerts
    result = await db.execute(
        select(Alert)
        .where(and_(Alert.farmer_id == farmer_id, Alert.is_dismissed == 0))
        .order_by(desc(Alert.created_at))
    )
    return result.scalars().all()

@router.post("/{alert_id}/dismiss")
async def dismiss_alert(alert_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Alert).where(Alert.id == alert_id))
    alert = result.scalars().first()
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    
    alert.is_dismissed = 1
    await db.commit()
    return {"message": "Alert dismissed"}

async def generate_dynamic_alerts(farmer_id: int, db: AsyncSession = Depends(get_db)):
    # Simple alert generation logic for Phase I
    
    # Check for Sick animals > 3 days without update (simplified check)
    sick_animals_query = select(Animal, HealthRecord).join(HealthRecord).where(
        and_(
            Animal.farmer_id == farmer_id,
            HealthRecord.next_checkup_date == None,
            HealthRecord.date <= date.today() - timedelta(days=3)
        )
    )
    sick_animals = await db.execute(sick_animals_query)
    for animal, record in sick_animals.all():
        # Check if alert already exists
        eb_query = select(Alert).where(and_(Alert.related_animal_id == animal.animal_id, Alert.type == "CRITICAL", Alert.is_dismissed == 0))
        exists = await db.execute(eb_query)
        if not exists.scalars().first():
            new_alert = Alert(
                farmer_id=farmer_id,
                type="CRITICAL",
                title="Untreated Illness",
                message=f"{animal.tag_number} has been sick for over 3 days without a follow-up.",
                severity="High",
                related_animal_id=animal.animal_id
            )
            db.add(new_alert)

    # Check for Breeding Due Soon
    due_soon_date = date.today() + timedelta(days=7)
    due_soon_query = select(Animal, BreedingRecord).join(BreedingRecord, Animal.animal_id == BreedingRecord.female_id).where(
        and_(
            Animal.farmer_id == farmer_id,
            BreedingRecord.pregnancy_status == "Confirmed",
            BreedingRecord.actual_calving_date == None,
            BreedingRecord.expected_calving_date <= due_soon_date
        )
    )
    due_soon_animals = await db.execute(due_soon_query)
    for animal, br in due_soon_animals.all():
        eb_query = select(Alert).where(and_(Alert.related_animal_id == animal.animal_id, Alert.title == "Calving Due Soon", Alert.is_dismissed == 0))
        exists = await db.execute(eb_query)
        if not exists.scalars().first():
            new_alert = Alert(
                farmer_id=farmer_id,
                type="WARNING",
                title="Calving Due Soon",
                message=f"{animal.tag_number} is expected to calve by {br.expected_calving_date}.",
                severity="Medium",
                related_animal_id=animal.animal_id
            )
            db.add(new_alert)

    await db.commit()
