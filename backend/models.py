from sqlalchemy import Column, Integer, String, Date, Numeric, ForeignKey, Text, TIMESTAMP, CheckConstraint, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

class Farmer(Base):
    __tablename__ = "farmer"

    farmer_id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(100), nullable=False)
    phone_number = Column(String(15))
    farm_name = Column(String(100))
    location = Column(String(255))
    farm_type = Column(String(20), nullable=False)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    last_login = Column(TIMESTAMP(timezone=True))

    pens = relationship("AnimalPen", back_populates="farmer", cascade="all, delete-orphan")
    animals = relationship("Animal", back_populates="farmer", cascade="all, delete-orphan")
    labor_activities = relationship("LaborActivity", back_populates="farmer", cascade="all, delete-orphan")
    financial_transactions = relationship("FinancialTransaction", back_populates="farmer", cascade="all, delete-orphan")
    performance_caches = relationship("PerformanceCache", back_populates="farmer", cascade="all, delete-orphan")

class AnimalPen(Base):
    __tablename__ = "animal_pen"

    pen_id = Column(Integer, primary_key=True, index=True)
    pen_name = Column(String(50), nullable=False)
    pen_type = Column(String(20), nullable=False)
    capacity = Column(Integer)
    description = Column(Text)
    farmer_id = Column(Integer, ForeignKey("farmer.farmer_id", ondelete="CASCADE"), nullable=False)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    farmer = relationship("Farmer", back_populates="pens")
    animals = relationship("Animal", back_populates="pen", cascade="all, delete-orphan")
    feed_logs = relationship("FeedLog", back_populates="pen", cascade="all, delete-orphan")

class Animal(Base):
    __tablename__ = "animal"

    animal_id = Column(Integer, primary_key=True, index=True)
    farmer_id = Column(Integer, ForeignKey("farmer.farmer_id", ondelete="CASCADE"), nullable=False)
    pen_id = Column(Integer, ForeignKey("animal_pen.pen_id", ondelete="CASCADE"), nullable=False)
    tag_number = Column(String(50), nullable=False)
    animal_type = Column(String(10), nullable=False)
    breed = Column(String(50), nullable=False)
    gender = Column(String(10), nullable=False)
    birth_date = Column(Date)
    acquisition_type = Column(String(20), nullable=False)
    acquisition_cost = Column(Numeric(10, 2), default=0)
    status = Column(String(20), default="Active")
    disposal_reason = Column(String(100))
    disposal_date = Column(Date)
    disposal_value = Column(Numeric(10, 2))
    notes = Column(Text)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())

    __table_args__ = (UniqueConstraint('farmer_id', 'tag_number', name='unique_farmer_tag'),)

    farmer = relationship("Farmer", back_populates="animals")
    pen = relationship("AnimalPen", back_populates="animals")
    milk_productions = relationship("MilkProduction", back_populates="animal", cascade="all, delete-orphan")
    weight_records = relationship("WeightRecord", back_populates="animal", cascade="all, delete-orphan")
    breeding_records_female = relationship("BreedingRecord", foreign_keys="[BreedingRecord.female_id]", back_populates="female", cascade="all, delete-orphan")
    breeding_records_male = relationship("BreedingRecord", foreign_keys="[BreedingRecord.male_id]", back_populates="male")
    breeding_records_offspring = relationship("BreedingRecord", foreign_keys="[BreedingRecord.offspring_id]", back_populates="offspring")
    individual_feed_logs = relationship("IndividualFeedLog", back_populates="animal", cascade="all, delete-orphan")
    health_records = relationship("HealthRecord", back_populates="animal", cascade="all, delete-orphan")

class MilkProduction(Base):
    __tablename__ = "milk_production"

    production_id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(Integer, ForeignKey("animal.animal_id", ondelete="CASCADE"), nullable=False)
    date = Column(Date, nullable=False, server_default=func.current_date())
    morning_yield = Column(Numeric(5, 2))
    evening_yield = Column(Numeric(5, 2))
    # total_yield is generated always, so we don't map it for writing, but can read it if needed.
    # SQLAlchemy doesn't support GENERATED ALWAYS AS well for writes, usually we just read it.
    # For simplicity in python we might calculate it or just let DB handle it.
    # We will map it as read-only or just ignore it in inserts.
    total_yield = Column(Numeric(5, 2), server_default=func.text("GENERATED ALWAYS AS (COALESCE(morning_yield,0) + COALESCE(evening_yield,0)) STORED"))
    fat_content = Column(Numeric(4, 2))
    protein_content = Column(Numeric(4, 2))
    somatic_cell_count = Column(Integer)
    quality_notes = Column(Text)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    animal = relationship("Animal", back_populates="milk_productions")

class WeightRecord(Base):
    __tablename__ = "weight_record"

    weight_id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(Integer, ForeignKey("animal.animal_id", ondelete="CASCADE"), nullable=False)
    date = Column(Date, nullable=False, server_default=func.current_date())
    weight_kg = Column(Numeric(6, 2), nullable=False)
    body_condition_score = Column(Integer)
    notes = Column(Text)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    animal = relationship("Animal", back_populates="weight_records")

class BreedingRecord(Base):
    __tablename__ = "breeding_record"

    breeding_id = Column(Integer, primary_key=True, index=True)
    female_id = Column(Integer, ForeignKey("animal.animal_id", ondelete="CASCADE"), nullable=False)
    male_id = Column(Integer, ForeignKey("animal.animal_id", ondelete="SET NULL"))
    breeding_date = Column(Date, nullable=False)
    breeding_method = Column(String(20))
    pregnancy_status = Column(String(20), default="Unknown")
    expected_calving_date = Column(Date)
    actual_calving_date = Column(Date)
    outcome = Column(String(20))
    offspring_id = Column(Integer, ForeignKey("animal.animal_id", ondelete="SET NULL"))
    notes = Column(Text)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    female = relationship("Animal", foreign_keys=[female_id], back_populates="breeding_records_female")
    male = relationship("Animal", foreign_keys=[male_id], back_populates="breeding_records_male")
    offspring = relationship("Animal", foreign_keys=[offspring_id], back_populates="breeding_records_offspring")

class FeedLog(Base):
    __tablename__ = "feed_log"

    log_id = Column(Integer, primary_key=True, index=True)
    pen_id = Column(Integer, ForeignKey("animal_pen.pen_id", ondelete="CASCADE"), nullable=False)
    feed_type = Column(String(50), nullable=False)
    quantity_kg = Column(Numeric(8, 2), nullable=False)
    cost_per_kg = Column(Numeric(8, 2), nullable=False)
    total_cost = Column(Numeric(10, 2), server_default=func.text("GENERATED ALWAYS AS (quantity_kg * cost_per_kg) STORED"))
    date = Column(Date, nullable=False, server_default=func.current_date())
    notes = Column(Text)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    pen = relationship("AnimalPen", back_populates="feed_logs")

class IndividualFeedLog(Base):
    __tablename__ = "individual_feed_log"

    individual_feed_id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(Integer, ForeignKey("animal.animal_id", ondelete="CASCADE"), nullable=False)
    feed_type = Column(String(50), nullable=False)
    quantity_kg = Column(Numeric(6, 2), nullable=False)
    cost_per_kg = Column(Numeric(6, 2), nullable=False)
    total_cost = Column(Numeric(8, 2), server_default=func.text("GENERATED ALWAYS AS (quantity_kg * cost_per_kg) STORED"))
    date = Column(Date, nullable=False, server_default=func.current_date())
    notes = Column(Text)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    animal = relationship("Animal", back_populates="individual_feed_logs")

class HealthRecord(Base):
    __tablename__ = "health_record"

    record_id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(Integer, ForeignKey("animal.animal_id", ondelete="CASCADE"), nullable=False)
    date = Column(Date, nullable=False, server_default=func.current_date())
    condition = Column(String(100), nullable=False)
    symptoms = Column(Text, nullable=False)
    treatment = Column(Text, nullable=False)
    cost = Column(Numeric(10, 2), default=0)
    vet_name = Column(String(100))
    next_checkup_date = Column(Date)
    notes = Column(Text)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    animal = relationship("Animal", back_populates="health_records")

class LaborActivity(Base):
    __tablename__ = "labor_activity"

    activity_id = Column(Integer, primary_key=True, index=True)
    farmer_id = Column(Integer, ForeignKey("farmer.farmer_id", ondelete="CASCADE"), nullable=False)
    activity_type = Column(String(50), nullable=False)
    description = Column(Text)
    hours_spent = Column(Numeric(4, 2), nullable=False)
    labor_cost = Column(Numeric(8, 2), nullable=False)
    date = Column(Date, nullable=False, server_default=func.current_date())
    related_animal_id = Column(Integer, ForeignKey("animal.animal_id", ondelete="SET NULL"))
    related_pen_id = Column(Integer, ForeignKey("animal_pen.pen_id", ondelete="SET NULL"))
    notes = Column(Text)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    farmer = relationship("Farmer", back_populates="labor_activities")
    related_animal = relationship("Animal", foreign_keys=[related_animal_id])
    related_pen = relationship("AnimalPen", foreign_keys=[related_pen_id])

class FinancialTransaction(Base):
    __tablename__ = "financial_transaction"

    transaction_id = Column(Integer, primary_key=True, index=True)
    farmer_id = Column(Integer, ForeignKey("farmer.farmer_id", ondelete="CASCADE"), nullable=False)
    type = Column(String(10), nullable=False)
    category = Column(String(30), nullable=False)
    description = Column(Text, nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    date = Column(Date, nullable=False, server_default=func.current_date())
    related_animal_id = Column(Integer, ForeignKey("animal.animal_id", ondelete="SET NULL"))
    related_pen_id = Column(Integer, ForeignKey("animal_pen.pen_id", ondelete="SET NULL"))
    buyer_supplier = Column(String(100))
    notes = Column(Text)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    farmer = relationship("Farmer", back_populates="financial_transactions")
    related_animal = relationship("Animal", foreign_keys=[related_animal_id])
    related_pen = relationship("AnimalPen", foreign_keys=[related_pen_id])

class PerformanceCache(Base):
    __tablename__ = "performance_cache"

    cache_id = Column(Integer, primary_key=True, index=True)
    farmer_id = Column(Integer, ForeignKey("farmer.farmer_id", ondelete="CASCADE"), nullable=False)
    metric_name = Column(String(100), nullable=False)
    metric_value = Column(Numeric(12, 4), nullable=False)
    period_type = Column(String(20), nullable=False)
    period_start = Column(Date, nullable=False)
    period_end = Column(Date, nullable=False)
    related_animal_id = Column(Integer, ForeignKey("animal.animal_id", ondelete="SET NULL"))
    related_pen_id = Column(Integer, ForeignKey("animal_pen.pen_id", ondelete="SET NULL"))
    calculated_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    __table_args__ = (UniqueConstraint('farmer_id', 'metric_name', 'period_type', 'period_start', 'related_animal_id', 'related_pen_id', name='unique_performance_metric'),)

    farmer = relationship("Farmer", back_populates="performance_caches")
