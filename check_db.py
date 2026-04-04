import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy.future import select
import os
import sys

# Add backend to path to import models
sys.path.append('backend')
import models

DATABASE_URL = "sqlite+aiosqlite:///./smart_ranch.db"

async def check_db():
    engine = create_async_engine(DATABASE_URL)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        # Check Farmers
        result = await session.execute(select(models.Farmer))
        farmers = result.scalars().all()
        print(f"Farmers count: {len(farmers)}")
        for f in farmers:
            print(f" - ID: {f.farmer_id}, Username: {f.username}")
            
        # Check Animals
        result = await session.execute(select(models.Animal))
        animals = result.scalars().all()
        print(f"Animals count: {len(animals)}")
        
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(check_db())
