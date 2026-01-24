import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://postgres:%24Youngmoney12327@localhost/smartranch")

async def run_migration():
    engine = create_async_engine(DATABASE_URL, echo=True)
    
    async with engine.begin() as conn:
        print("Adding source_table and source_id to financial_transaction...")
        try:
            await conn.execute(text("ALTER TABLE financial_transaction ADD COLUMN source_table VARCHAR(50);"))
            await conn.execute(text("ALTER TABLE financial_transaction ADD COLUMN source_id INT;"))
        except Exception as e:
            print(f"Error updating financial_transaction (maybe already exists?): {e}")

        print("Adding cost to breeding_record...")
        try:
            await conn.execute(text("ALTER TABLE breeding_record ADD COLUMN cost NUMERIC(10, 2) DEFAULT 0;"))
        except Exception as e:
            print(f"Error updating breeding_record (maybe already exists?): {e}")

    await engine.dispose()
    print("Migration complete!")

if __name__ == "__main__":
    asyncio.run(run_migration())
