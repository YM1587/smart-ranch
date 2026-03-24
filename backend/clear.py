import asyncio
from sqlalchemy import text
from database import engine

async def run():
    async with engine.begin() as conn:
        await conn.execute(text("DELETE FROM alerts"))

asyncio.run(run())
