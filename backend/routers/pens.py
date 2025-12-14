from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import models
import schemas

router = APIRouter(
    prefix="/pens",
    tags=["Pens"]
)

@router.get("/", response_model=List[schemas.AnimalPen])
def get_pens(farmer_id: int, db: Session = Depends(get_db)):
    pens = db.query(models.AnimalPen).filter(models.AnimalPen.farmer_id == farmer_id).all()
    return pens

@router.post("/", response_model=schemas.AnimalPen, status_code=status.HTTP_201_CREATED)
def create_pen(pen: schemas.AnimalPenCreate, db: Session = Depends(get_db)):
    new_pen = models.AnimalPen(**pen.dict())
    db.add(new_pen)
    db.commit()
    db.refresh(new_pen)
    return new_pen
