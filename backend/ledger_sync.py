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
    # Safeguard against None amounts
    if amount is None:
        amount = Decimal(0)
    else:
        # Ensure it's a Decimal
        amount = Decimal(str(amount))
    
    # Don't sync if amount is <= 0 (per DB check constraint)
    if amount <= 0:
        return

    if not transaction_date:
        transaction_date = date.today()
    elif isinstance(transaction_date, (str, bytes)):
        # Convert string to date if necessary
        from datetime import datetime
        transaction_date = datetime.strptime(transaction_date, "%Y-%m-%d").date()

    try:
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
        
        # Flush to catch constraints early
        await db.flush()
        
    except Exception as e:
        print(f"Error in sync_operation_to_ledger: {e}")
        # Re-raise to let the router handle the error (causes 500)
        raise e
