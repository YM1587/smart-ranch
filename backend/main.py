from fastapi import FastAPI
from database import engine, Base
from routers import animals, health, feed, finance
import asyncio

app = FastAPI(title="Smart Ranch Management System API")

# Include Routers
app.include_router(animals.router, tags=["Animals & Pens"])
app.include_router(health.router, tags=["Health"])
app.include_router(feed.router, tags=["Feed"])
app.include_router(finance.router, tags=["Finance"])

@app.on_event("startup")
async def startup():
    # Create tables if they don't exist (for development convenience)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

@app.get("/")
async def root():
    return {"message": "Welcome to Smart Ranch Management System API"}
