from sqlalchemy import Column, Integer, String, Date, Numeric, ForeignKey, Text, TIMESTAMP
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

class Pen(Base):
    __tablename__ = "pens"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    livestock_type = Column(String, nullable=False)
    capacity = Column(Integer)
    created_at = Column(TIMESTAMP, server_default=func.now())

    animals = relationship("Animal", back_populates="pen")
    feed_logs = relationship("FeedLog", back_populates="pen")

class Animal(Base):
    __tablename__ = "animals"

    id = Column(Integer, primary_key=True, index=True)
    tag_number = Column(String, unique=True, nullable=False)
    pen_id = Column(Integer, ForeignKey("pens.id"))
    breed = Column(String)
    sex = Column(String)
    dob = Column(Date)
    acquisition_date = Column(Date)
    acquisition_cost = Column(Numeric(10, 2))
    status = Column(String, default="Active")
    created_at = Column(TIMESTAMP, server_default=func.now())

    pen = relationship("Pen", back_populates="animals")
    health_events = relationship("HealthEvent", back_populates="animal")

class HealthEvent(Base):
    __tablename__ = "health_events"

    id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(Integer, ForeignKey("animals.id"))
    event_date = Column(Date, nullable=False)
    event_type = Column(String, nullable=False)
    symptoms = Column(Text)
    diagnosis = Column(Text)
    treatment = Column(Text)
    cost = Column(Numeric(10, 2), default=0.00)
    performed_by = Column(String)
    notes = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.now())

    animal = relationship("Animal", back_populates="health_events")

class FeedLog(Base):
    __tablename__ = "feed_logs"

    id = Column(Integer, primary_key=True, index=True)
    pen_id = Column(Integer, ForeignKey("pens.id"))
    log_date = Column(Date, nullable=False)
    feed_type = Column(String, nullable=False)
    quantity_kg = Column(Numeric(10, 2), nullable=False)
    cost = Column(Numeric(10, 2), nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.now())

    pen = relationship("Pen", back_populates="feed_logs")

class Expense(Base):
    __tablename__ = "expenses"

    id = Column(Integer, primary_key=True, index=True)
    category = Column(String, nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    expense_date = Column(Date, nullable=False)
    description = Column(Text)
    pen_id = Column(Integer, ForeignKey("pens.id"), nullable=True)
    animal_id = Column(Integer, ForeignKey("animals.id"), nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.now())
