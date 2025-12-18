import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

DATABASE_URL = "postgresql+asyncpg://postgres:%24Youngmoney12327@localhost/smartranch"

async def debug_db():
    engine = create_async_engine(DATABASE_URL)
    async with engine.connect() as conn:
        result = await conn.execute(text("SELECT animal_id, tag_number, name FROM animal;"))
        rows = result.fetchall()
        print(f"Total rows: {len(rows)}")
        for row in rows:
            print(f"ID: {row[0]}, Tag: {row[1]}, Name: {row[2]}")
            
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(debug_db())
