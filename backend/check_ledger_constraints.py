import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://postgres:%24Youngmoney12327@localhost/smartranch")

async def check_ledger_constraints():
    engine = create_async_engine(DATABASE_URL, echo=True)
    async with engine.begin() as conn:
        print("--- Financial Transaction Check Constraints ---")
        sql = """
        SELECT conname, pg_get_constraintdef(c.oid) 
        FROM pg_constraint c 
        WHERE contype = 'c' AND conname LIKE 'financial_transaction%';
        """
        res = await conn.execute(text(sql))
        for row in res:
            print(f"{row[0]}: {row[1]}")

    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(check_ledger_constraints())
