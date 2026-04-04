import asyncio
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

DATABASE_URL = "postgresql+asyncpg://postgres:%24Youngmoney12327@localhost/smartranch"

async def main():
    engine = create_async_engine(DATABASE_URL)
    async with engine.connect() as conn:
        print("Connected to database.")
        
        queries = [
            ("ALTER TABLE health_record ADD COLUMN IF NOT EXISTS outcome VARCHAR(50);", "health_record.outcome"),
            ("ALTER TABLE alert ADD COLUMN IF NOT EXISTS is_dismissed INTEGER DEFAULT 0;", "alert.is_dismissed"),
            ("ALTER TABLE alert ADD COLUMN IF NOT EXISTS severity VARCHAR(20) DEFAULT 'Info';", "alert.severity"),
            ("ALTER TABLE alert ADD COLUMN IF NOT EXISTS type VARCHAR(20) DEFAULT 'INFO';", "alert.type"),
            ("ALTER TABLE alert ADD COLUMN IF NOT EXISTS animal_id INTEGER REFERENCES animal(animal_id);", "alert.animal_id"),
        ]
        
        for query, col in queries:
            try:
                await conn.execute(text(query))
                await conn.commit()
                print(f"Task: Ensuring {col} column exists... OK")
            except Exception as e:
                print(f"Error for {col}: {e}")
                
    await engine.dispose()
    print("Done.")

if __name__ == "__main__":
    asyncio.run(main())
