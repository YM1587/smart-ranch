import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://postgres:%24Youngmoney12327@localhost/smartranch")

async def inspect_db():
    engine = create_async_engine(DATABASE_URL, echo=True)
    async with engine.begin() as conn:
        print("--- Breeding Record Columns ---")
        res = await conn.execute(text("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'breeding_record'"))
        for row in res:
            print(f"{row[0]}: {row[1]}")
        
        print("\n--- Financial Transaction Columns ---")
        res = await conn.execute(text("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'financial_transaction'"))
        for row in res:
            print(f"{row[0]}: {row[1]}")

    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(inspect_db())
