from pydantic import BaseModel
from typing import Optional, List
from datetime import date, datetime
from decimal import Decimal

# --- FARMER SCHEMAS ---
class FarmerBase(BaseModel):
    username: str
    full_name: str
    phone_number: Optional[str] = None
    farm_name: Optional[str] = None
    location: Optional[str] = None
    farm_type: str

class FarmerCreate(FarmerBase):
    password: str

class Farmer(FarmerBase):
    farmer_id: int
    created_at: datetime
    last_login: Optional[datetime] = None

    class Config:
        orm_mode = True

# --- ANIMAL PEN SCHEMAS ---
class AnimalPenBase(BaseModel):
    pen_name: str
    pen_type: str
    capacity: Optional[int] = None
    description: Optional[str] = None
    farmer_id: int

class AnimalPenCreate(AnimalPenBase):
    pass

class AnimalPen(AnimalPenBase):
    pen_id: int
    created_at: datetime

    class Config:
        orm_mode = True

# --- ANIMAL SCHEMAS ---
class AnimalBase(BaseModel):
    farmer_id: int
    pen_id: int
    tag_number: str
    animal_type: str
    breed: str
    gender: str
    birth_date: Optional[date] = None
    acquisition_type: str
    acquisition_cost: Optional[Decimal] = Decimal(0)
    status: Optional[str] = "Active"
    disposal_reason: Optional[str] = None
    disposal_date: Optional[date] = None
    disposal_value: Optional[Decimal] = None
    notes: Optional[str] = None

class AnimalCreate(AnimalBase):
    pass

class Animal(AnimalBase):
    animal_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        orm_mode = True

# --- MILK PRODUCTION SCHEMAS ---
class MilkProductionBase(BaseModel):
    animal_id: int
    date: date
    morning_yield: Optional[Decimal] = None
    evening_yield: Optional[Decimal] = None
    fat_content: Optional[Decimal] = None
    protein_content: Optional[Decimal] = None
    somatic_cell_count: Optional[int] = None
    quality_notes: Optional[str] = None

class MilkProductionCreate(MilkProductionBase):
    pass

class MilkProduction(MilkProductionBase):
    production_id: int
    total_yield: Optional[Decimal] = None
    created_at: datetime

    class Config:
        orm_mode = True

# --- WEIGHT RECORD SCHEMAS ---
class WeightRecordBase(BaseModel):
    animal_id: int
    date: date
    weight_kg: Decimal
    body_condition_score: Optional[int] = None
    notes: Optional[str] = None

class WeightRecordCreate(WeightRecordBase):
    pass

class WeightRecord(WeightRecordBase):
    weight_id: int
    created_at: datetime

    class Config:
        orm_mode = True

# --- BREEDING RECORD SCHEMAS ---
class BreedingRecordBase(BaseModel):
    female_id: int
    male_id: Optional[int] = None
    breeding_date: date
    breeding_method: Optional[str] = None
    pregnancy_status: Optional[str] = "Unknown"
    expected_calving_date: Optional[date] = None
    actual_calving_date: Optional[date] = None
    outcome: Optional[str] = None
    offspring_id: Optional[int] = None
    notes: Optional[str] = None

class BreedingRecordCreate(BreedingRecordBase):
    pass

class BreedingRecord(BreedingRecordBase):
    breeding_id: int
    created_at: datetime

    class Config:
        orm_mode = True

# --- FEED LOG SCHEMAS ---
class FeedLogBase(BaseModel):
    pen_id: int
    feed_type: str
    quantity_kg: Decimal
    cost_per_kg: Decimal
    date: date
    notes: Optional[str] = None

class FeedLogCreate(FeedLogBase):
    pass

class FeedLog(FeedLogBase):
    log_id: int
    total_cost: Optional[Decimal] = None
    created_at: datetime

    class Config:
        orm_mode = True

# --- INDIVIDUAL FEED LOG SCHEMAS ---
class IndividualFeedLogBase(BaseModel):
    animal_id: int
    feed_type: str
    quantity_kg: Decimal
    cost_per_kg: Decimal
    date: date
    notes: Optional[str] = None

class IndividualFeedLogCreate(IndividualFeedLogBase):
    pass

class IndividualFeedLog(IndividualFeedLogBase):
    individual_feed_id: int
    total_cost: Optional[Decimal] = None
    created_at: datetime

    class Config:
        orm_mode = True

# --- HEALTH RECORD SCHEMAS ---
class HealthRecordBase(BaseModel):
    animal_id: int
    date: date
    condition: str
    symptoms: str
    treatment: str
    cost: Optional[Decimal] = Decimal(0)
    vet_name: Optional[str] = None
    next_checkup_date: Optional[date] = None
    notes: Optional[str] = None

class HealthRecordCreate(HealthRecordBase):
    pass

class HealthRecord(HealthRecordBase):
    record_id: int
    created_at: datetime

    class Config:
        orm_mode = True

# --- LABOR ACTIVITY SCHEMAS ---
class LaborActivityBase(BaseModel):
    farmer_id: int
    activity_type: str
    description: Optional[str] = None
    hours_spent: Decimal
    labor_cost: Decimal
    date: date
    related_animal_id: Optional[int] = None
    related_pen_id: Optional[int] = None
    notes: Optional[str] = None

class LaborActivityCreate(LaborActivityBase):
    pass

class LaborActivity(LaborActivityBase):
    activity_id: int
    created_at: datetime

    class Config:
        orm_mode = True

# --- FINANCIAL TRANSACTION SCHEMAS ---
class FinancialTransactionBase(BaseModel):
    farmer_id: int
    type: str
    category: str
    description: str
    amount: Decimal
    date: date
    related_animal_id: Optional[int] = None
    related_pen_id: Optional[int] = None
    buyer_supplier: Optional[str] = None
    notes: Optional[str] = None

class FinancialTransactionCreate(FinancialTransactionBase):
    pass

class FinancialTransaction(FinancialTransactionBase):
    transaction_id: int
    created_at: datetime

    class Config:
        orm_mode = True

# --- PERFORMANCE CACHE SCHEMAS ---
class PerformanceCacheBase(BaseModel):
    farmer_id: int
    metric_name: str
    metric_value: Decimal
    period_type: str
    period_start: date
    period_end: date
    related_animal_id: Optional[int] = None
    related_pen_id: Optional[int] = None

class PerformanceCacheCreate(PerformanceCacheBase):
    pass

class PerformanceCache(PerformanceCacheBase):
    cache_id: int
    calculated_at: datetime

    class Config:
        orm_mode = True
