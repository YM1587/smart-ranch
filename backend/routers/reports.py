from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func, and_, desc, cast, Float
from typing import List, Dict
from datetime import date, timedelta
from decimal import Decimal

from database import get_db
import models
import schemas
from auth import get_current_user

router = APIRouter(
    prefix="/reports",
    tags=["Reports"]
)

@router.get("/fcr/{pen_id}")
async def get_pen_fcr(
    pen_id: int, 
    db: AsyncSession = Depends(get_db), 
    current_user: models.Farmer = Depends(get_current_user)
):
    """
    Calculates Feed Conversion Ratio (FCR) for a specific pen.
    """
    # Verify pen ownership
    pen_res = await db.execute(select(models.AnimalPen).where(models.AnimalPen.pen_id == pen_id))
    pen = pen_res.scalars().first()
    if not pen or pen.farmer_id != current_user.farmer_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    # 1. Total Feed Consumed in this Pen
    feed_query = select(func.sum(models.FeedLog.quantity_kg)).where(models.FeedLog.pen_id == pen_id)
    feed_result = await db.execute(feed_query)
    total_feed = feed_result.scalar() or 0
    
    if total_feed == 0:
        return {"fcr": 0, "message": "No feed records found for this pen."}

    # 2. Total Weight Gain
    animals_query = select(models.Animal.animal_id).where(models.Animal.pen_id == pen_id)
    animals_result = await db.execute(animals_query)
    animal_ids = animals_result.scalars().all()
    
    total_gain = 0
    for a_id in animal_ids:
        first_w = await db.execute(select(models.WeightRecord.weight_kg).where(models.WeightRecord.animal_id == a_id).order_by(models.WeightRecord.date.asc()).limit(1))
        last_w = await db.execute(select(models.WeightRecord.weight_kg).where(models.WeightRecord.animal_id == a_id).order_by(models.WeightRecord.date.desc()).limit(1))
        
        start = first_w.scalar()
        end = last_w.scalar()
        
        if start and end and end > start:
            total_gain += (end - start)

    if total_gain == 0:
        return {"fcr": 0, "message": "Insufficient weight gain data for calculation."}
    
    fcr = float(total_feed) / float(total_gain)
    return {
        "pen_id": pen_id,
        "total_feed_kg": float(total_feed),
        "total_gain_kg": float(total_gain),
        "fcr": round(fcr, 2)
    }

@router.get("/mortality")
async def get_mortality_rate(
    farmer_id: int, 
    db: AsyncSession = Depends(get_db), 
    current_user: models.Farmer = Depends(get_current_user)
):
    if current_user.farmer_id != farmer_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    total_query = select(func.count(models.Animal.animal_id)).where(models.Animal.farmer_id == current_user.farmer_id)
    total_result = await db.execute(total_query)
    total_count = total_result.scalar() or 0
    
    if total_count == 0:
        return {"mortality_rate": 0}

    deceased_query = select(func.count(models.Animal.animal_id)).where(
        and_(
            models.Animal.farmer_id == current_user.farmer_id,
            models.Animal.status == "Disposed",
            models.Animal.disposal_reason == "Deceased"
        )
    )
    deceased_result = await db.execute(deceased_query)
    deceased_count = deceased_result.scalar() or 0
    
    rate = (deceased_count / total_count) * 100
    return {
        "total_animals": total_count,
        "deceased_count": deceased_count,
        "mortality_rate": round(rate, 2)
    }

@router.get("/financial-summary")
async def get_financial_summary(
    farmer_id: int, 
    db: AsyncSession = Depends(get_db), 
    current_user: models.Farmer = Depends(get_current_user)
):
    if current_user.farmer_id != farmer_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    summary = {}

    # 1. Existing Expense Transactions from FinancialTransaction table
    finance_query = select(
        models.FinancialTransaction.category,
        func.sum(models.FinancialTransaction.amount).label("total_amount")
    ).where(
        and_(
            models.FinancialTransaction.farmer_id == current_user.farmer_id,
            models.FinancialTransaction.type == "Expense"
        )
    ).group_by(models.FinancialTransaction.category)
    
    finance_res = await db.execute(finance_query)
    for row in finance_res.all():
        summary[row.category] = float(row.total_amount)

    # 2. Feed Costs (Pen FeedLogs)
    # Join with AnimalPen to filter by farmer_id
    feed_query = select(func.sum(models.FeedLog.total_cost)).join(models.AnimalPen).where(models.AnimalPen.farmer_id == farmer_id)
    feed_res = await db.execute(feed_query)
    feed_total = feed_res.scalar() or 0
    summary["Feeding"] = summary.get("Feeding", 0) + float(feed_total)

    # 3. Labor Costs
    labor_query = select(func.sum(models.LaborActivity.labor_cost)).where(models.LaborActivity.farmer_id == farmer_id)
    labor_res = await db.execute(labor_query)
    labor_total = labor_res.scalar() or 0
    summary["Labor"] = summary.get("Labor", 0) + float(labor_total)

    # 4. Health/Medical Costs
    # Join with Animal to filter by farmer_id
    health_query = select(func.sum(models.HealthRecord.cost)).join(models.Animal).where(models.Animal.farmer_id == farmer_id)
    health_res = await db.execute(health_query)
    health_total = health_res.scalar() or 0
    summary["Medical"] = summary.get("Medical", 0) + float(health_total)

    # 5. Breeding Costs
    # Join with Animal to filter by farmer_id (using female animal)
    breeding_query = select(func.sum(models.BreedingRecord.cost)).join(models.Animal, models.BreedingRecord.female_id == models.Animal.animal_id).where(models.Animal.farmer_id == farmer_id)
    breeding_res = await db.execute(breeding_query)
    breeding_total = breeding_res.scalar() or 0
    summary["Breeding"] = summary.get("Breeding", 0) + float(breeding_total)

    # 6. Animal Acquisition Costs
    acquisition_query = select(func.sum(models.Animal.acquisition_cost)).where(models.Animal.farmer_id == farmer_id)
    acquisition_res = await db.execute(acquisition_query)
    acquisition_total = acquisition_res.scalar() or 0
    summary["Acquisition"] = summary.get("Acquisition", 0) + float(acquisition_total)

    total_expenses = sum(summary.values())
    
    return {
        "categories": summary,
        "total_expenses": total_expenses
    }
