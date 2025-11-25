from pydantic import BaseModel
from typing import Optional, List
from datetime import date, datetime

# --- PEN SCHEMAS ---
class PenBase(BaseModel):
    name: str
    livestock_type: str
    capacity: Optional[int] = None

class PenCreate(PenBase):
    pass

class Pen(PenBase):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True

# --- ANIMAL SCHEMAS ---
class AnimalBase(BaseModel):
    tag_number: str
    pen_id: Optional[int] = None
    breed: Optional[str] = None
    sex: Optional[str] = None
    dob: Optional[date] = None
    acquisition_date: Optional[date] = None
    acquisition_cost: Optional[float] = None
    status: Optional[str] = "Active"

class AnimalCreate(AnimalBase):
    pass

class Animal(AnimalBase):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True

# --- HEALTH EVENT SCHEMAS ---
class HealthEventBase(BaseModel):
    animal_id: int
    event_date: date
    event_type: str
    symptoms: Optional[str] = None
    diagnosis: Optional[str] = None
    treatment: Optional[str] = None
    cost: Optional[float] = 0.0
    performed_by: Optional[str] = None
    notes: Optional[str] = None

class HealthEventCreate(HealthEventBase):
    pass

class HealthEvent(HealthEventBase):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True

# --- FEED LOG SCHEMAS ---
class FeedLogBase(BaseModel):
    pen_id: int
    log_date: date
    feed_type: str
    quantity_kg: float
    cost: float

class FeedLogCreate(FeedLogBase):
    pass

class FeedLog(FeedLogBase):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True

# --- EXPENSE SCHEMAS ---
class ExpenseBase(BaseModel):
    category: str
    amount: float
    expense_date: date
    description: Optional[str] = None
    pen_id: Optional[int] = None
    animal_id: Optional[int] = None

class ExpenseCreate(ExpenseBase):
    pass

class Expense(ExpenseBase):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True
