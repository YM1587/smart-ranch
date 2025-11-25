from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List
import database
import models
import schemas

router = APIRouter()

@router.post("/expenses/", response_model=schemas.Expense)
async def create_expense(expense: schemas.ExpenseCreate, db: AsyncSession = Depends(database.get_db)):
    db_expense = models.Expense(**expense.dict())
    db.add(db_expense)
    await db.commit()
    await db.refresh(db_expense)
    return db_expense

@router.get("/expenses/", response_model=List[schemas.Expense])
async def read_expenses(skip: int = 0, limit: int = 100, db: AsyncSession = Depends(database.get_db)):
    result = await db.execute(select(models.Expense).offset(skip).limit(limit))
    return result.scalars().all()
