import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

DATABASE_URL = "postgresql+asyncpg://postgres:%24Youngmoney12327@localhost/smartranch"

async def migrate():
    engine = create_async_engine(DATABASE_URL)
    async with engine.begin() as conn:
        await conn.execute(text("ALTER TABLE animal ADD COLUMN IF NOT EXISTS name VARCHAR(100);"))
    print("Migration successful: added 'name' column to 'animal' table.")
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(migrate())
