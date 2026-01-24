from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from decimal import Decimal
import models
import schemas
from datetime import date

async def sync_operation_to_ledger(
    db: AsyncSession,
    farmer_id: int,
    amount: Decimal,
    category: str,
    description: str,
    source_table: str,
    source_id: int,
    transaction_date: date = None,
    related_animal_id: int = None,
    related_pen_id: int = None
):
    """
    Synchronizes an operational activity to the financial ledger.
    Creates a new transaction or updates an existing one based on source_table and source_id.
    """
    if not transaction_date:
        transaction_date = date.today()

    # Check if a transaction already exists for this source
    result = await db.execute(
        select(models.FinancialTransaction).where(
            models.FinancialTransaction.source_table == source_table,
            models.FinancialTransaction.source_id == source_id
        )
    )
    db_transaction = result.scalars().first()

    if db_transaction:
        # Update existing transaction
        db_transaction.amount = amount
        db_transaction.category = category
        db_transaction.description = description
        db_transaction.date = transaction_date
        db_transaction.related_animal_id = related_animal_id
        db_transaction.related_pen_id = related_pen_id
    else:
        # Create new transaction
        new_transaction = models.FinancialTransaction(
            farmer_id=farmer_id,
            type="Expense",
            category=category,
            description=description,
            amount=amount,
            date=transaction_date,
            source_table=source_table,
            source_id=source_id,
            related_animal_id=related_animal_id,
            related_pen_id=related_pen_id
        )
        db.add(new_transaction)
    
    # We don't commit here; we let the caller handle the commit to ensure atomicity
    # with the operational record update.
