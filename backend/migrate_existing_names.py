import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

DATABASE_URL = "postgresql+asyncpg://postgres:%24Youngmoney12327@localhost/smartranch"

async def migrate():
    engine = create_async_engine(DATABASE_URL)
    async with engine.begin() as conn:
        # Fill name with tag_number where name is null
        await conn.execute(text("UPDATE animal SET name = tag_number WHERE name IS NULL;"))
    print("Migration successful: Filled 'name' column for existing animals.")
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(migrate())
