from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List
import database
import models
import schemas

router = APIRouter()

@router.post("/feed/", response_model=schemas.FeedLog)
async def create_feed_log(log: schemas.FeedLogCreate, db: AsyncSession = Depends(database.get_db)):
    db_log = models.FeedLog(**log.dict())
    db.add(db_log)
    await db.commit()
    await db.refresh(db_log)
    return db_log

@router.get("/feed/pen/{pen_id}", response_model=List[schemas.FeedLog])
async def read_feed_logs_by_pen(pen_id: int, db: AsyncSession = Depends(database.get_db)):
    result = await db.execute(select(models.FeedLog).where(models.FeedLog.pen_id == pen_id))
    return result.scalars().all()
