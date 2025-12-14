from fastapi import FastAPI
from database import engine, Base
from routers import animals, health, feed, finance, farmer, production, labor
import asyncio

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Smart Ranch Management System API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(farmer.router)
app.include_router(animals.router)
app.include_router(production.router)
app.include_router(health.router)
app.include_router(feed.router)
app.include_router(labor.router)
app.include_router(finance.router)

@app.on_event("startup")
async def startup():
    # Create tables if they don't exist (for development convenience)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

@app.get("/")
async def root():
    return {"message": "Welcome to Smart Ranch Management System API"}
