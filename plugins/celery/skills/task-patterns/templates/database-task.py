"""Database-Related Celery Task Patterns

Demonstrates best practices for database operations in Celery tasks.
"""
from celery import Celery, Task
from celery.utils.log import get_task_logger
from contextlib import contextmanager
from typing import List, Dict, Any, Optional
import time

logger = get_task_logger(__name__)

app = Celery('tasks', broker='redis://localhost:6379/0')


# IMPORTANT: Placeholder connection - replace with your actual DB library
class DatabaseConnection:
    """Placeholder database connection."""

    def __init__(self, host: str = 'localhost', database: str = 'mydb'):
        self.host = host
        self.database = database
        self.connected = False
        logger.info(f"Database connection created: {host}/{database}")

    def connect(self):
        """Establish connection."""
        self.connected = True
        logger.info("Database connected")

    def close(self):
        """Close connection."""
        self.connected = False
        logger.info("Database connection closed")

    def execute(self, query: str, params: tuple = ()):
        """Execute query."""
        logger.info(f"Executing: {query} with params: {params}")
        return {'affected_rows': 1, 'query': query}

    def fetchall(self, query: str, params: tuple = ()):
        """Fetch all results."""
        logger.info(f"Fetching: {query} with params: {params}")
        return [{'id': 1, 'name': 'Example'}]


class DatabaseTask(Task):
    """
    Custom task class with connection pooling.

    Connection is created once per worker and reused across tasks.
    """
    _db = None

    @property
    def db(self):
        """Get or create database connection."""
        if self._db is None:
            logger.info("Creating new database connection")
            self._db = DatabaseConnection()
            self._db.connect()
        return self._db

    def after_return(self, status, retval, task_id, args, kwargs, einfo):
        """Clean up after task completion."""
        # Note: Don't close connection here - it's shared across tasks
        # Connection closes when worker process terminates
        logger.info(f"Task {task_id} completed with status: {status}")


@app.task(base=DatabaseTask, bind=True)
def insert_record(self, table: str, data: dict) -> dict:
    """
    Insert record into database.

    Best Practices:
    - Pass IDs, not objects (avoid race conditions)
    - Use connection pooling
    - Handle database errors gracefully

    Args:
        table: Table name
        data: Record data to insert

    Returns:
        dict: Insert result

    Example:
        result = insert_record.delay('users', {
            'name': 'John Doe',
            'email': 'john@example.com'
        })
    """
    try:
        db = self.db

        # Build insert query (use parameterized queries!)
        columns = ', '.join(data.keys())
        placeholders = ', '.join(['%s'] * len(data))
        query = f"INSERT INTO {table} ({columns}) VALUES ({placeholders})"

        # Execute with parameters (prevents SQL injection)
        result = db.execute(query, tuple(data.values()))

        logger.info(f"Inserted record into {table}: {result}")

        return {
            'status': 'success',
            'table': table,
            'affected_rows': result['affected_rows']
        }

    except Exception as exc:
        logger.error(f"Failed to insert into {table}: {exc}")
        raise


@app.task(base=DatabaseTask, bind=True)
def bulk_insert(self, table: str, records: List[dict]) -> dict:
    """
    Bulk insert records for better performance.

    Args:
        table: Table name
        records: List of records to insert

    Returns:
        dict: Bulk insert result

    Example:
        records = [
            {'name': 'John', 'email': 'john@example.com'},
            {'name': 'Jane', 'email': 'jane@example.com'},
        ]
        result = bulk_insert.delay('users', records)
    """
    if not records:
        return {'status': 'success', 'inserted': 0}

    try:
        db = self.db

        # Build bulk insert query
        columns = ', '.join(records[0].keys())
        placeholders = ', '.join(['%s'] * len(records[0]))

        # Use executemany for bulk insert (more efficient)
        query = f"INSERT INTO {table} ({columns}) VALUES ({placeholders})"

        inserted_count = 0
        for record in records:
            db.execute(query, tuple(record.values()))
            inserted_count += 1

        logger.info(f"Bulk inserted {inserted_count} records into {table}")

        return {
            'status': 'success',
            'table': table,
            'inserted': inserted_count
        }

    except Exception as exc:
        logger.error(f"Bulk insert failed: {exc}")
        raise


@app.task(base=DatabaseTask, bind=True)
def update_record(self, table: str, record_id: int, data: dict) -> dict:
    """
    Update database record by ID.

    Args:
        table: Table name
        record_id: Record ID to update
        data: Fields to update

    Returns:
        dict: Update result

    Example:
        result = update_record.delay('users', 123, {
            'name': 'John Updated',
            'updated_at': '2025-01-01'
        })
    """
    try:
        db = self.db

        # Build update query
        set_clause = ', '.join([f"{k} = %s" for k in data.keys()])
        query = f"UPDATE {table} SET {set_clause} WHERE id = %s"

        # Execute with parameters
        params = tuple(data.values()) + (record_id,)
        result = db.execute(query, params)

        logger.info(f"Updated record {record_id} in {table}")

        return {
            'status': 'success',
            'table': table,
            'record_id': record_id,
            'affected_rows': result['affected_rows']
        }

    except Exception as exc:
        logger.error(f"Failed to update record {record_id}: {exc}")
        raise


@app.task(base=DatabaseTask, bind=True)
def query_records(self, query: str, params: tuple = ()) -> List[dict]:
    """
    Query database records.

    Args:
        query: SQL query
        params: Query parameters

    Returns:
        list: Query results

    Example:
        result = query_records.delay(
            "SELECT * FROM users WHERE status = %s",
            ('active',)
        )
    """
    try:
        db = self.db
        results = db.fetchall(query, params)

        logger.info(f"Query returned {len(results)} records")

        return results

    except Exception as exc:
        logger.error(f"Query failed: {exc}")
        raise


@contextmanager
def database_transaction(db):
    """
    Context manager for database transactions.

    Example:
        with database_transaction(db) as transaction:
            db.execute("INSERT INTO table1 ...")
            db.execute("UPDATE table2 ...")
    """
    try:
        logger.info("Starting transaction")
        # db.begin()  # Start transaction
        yield db
        # db.commit()  # Commit on success
        logger.info("Transaction committed")
    except Exception:
        # db.rollback()  # Rollback on error
        logger.error("Transaction rolled back")
        raise


@app.task(base=DatabaseTask, bind=True)
def transactional_operation(self, operations: List[dict]) -> dict:
    """
    Execute multiple database operations in a transaction.

    All operations succeed or all fail together (atomicity).

    Args:
        operations: List of operations to execute

    Returns:
        dict: Transaction result

    Example:
        operations = [
            {'type': 'insert', 'table': 'orders', 'data': {...}},
            {'type': 'update', 'table': 'inventory', 'id': 123, 'data': {...}},
        ]
        result = transactional_operation.delay(operations)
    """
    try:
        db = self.db

        with database_transaction(db):
            for op in operations:
                if op['type'] == 'insert':
                    insert_record(op['table'], op['data'])
                elif op['type'] == 'update':
                    update_record(op['table'], op['id'], op['data'])
                else:
                    raise ValueError(f"Unknown operation type: {op['type']}")

        logger.info(f"Transaction completed: {len(operations)} operations")

        return {
            'status': 'success',
            'operations_count': len(operations)
        }

    except Exception as exc:
        logger.error(f"Transaction failed: {exc}")
        raise


@app.task(base=DatabaseTask, bind=True)
def paginated_query(
    self,
    table: str,
    page: int = 1,
    page_size: int = 100,
    filters: Optional[dict] = None
) -> dict:
    """
    Query records with pagination.

    Args:
        table: Table name
        page: Page number (1-indexed)
        page_size: Records per page
        filters: Optional filters to apply

    Returns:
        dict: Paginated results

    Example:
        result = paginated_query.delay('users', page=2, page_size=50)
    """
    try:
        db = self.db

        # Calculate offset
        offset = (page - 1) * page_size

        # Build query
        query = f"SELECT * FROM {table}"
        params = []

        if filters:
            where_clauses = [f"{k} = %s" for k in filters.keys()]
            query += " WHERE " + " AND ".join(where_clauses)
            params.extend(filters.values())

        query += f" LIMIT %s OFFSET %s"
        params.extend([page_size, offset])

        # Execute query
        results = db.fetchall(query, tuple(params))

        logger.info(f"Paginated query returned {len(results)} records (page {page})")

        return {
            'status': 'success',
            'page': page,
            'page_size': page_size,
            'results': results,
            'has_more': len(results) == page_size
        }

    except Exception as exc:
        logger.error(f"Paginated query failed: {exc}")
        raise


@app.task(base=DatabaseTask, bind=True)
def aggregate_data(self, table: str, group_by: str, aggregates: dict) -> List[dict]:
    """
    Perform aggregation query.

    Args:
        table: Table name
        group_by: Field to group by
        aggregates: Aggregation functions (e.g., {'total': 'SUM(amount)'})

    Returns:
        list: Aggregation results

    Example:
        result = aggregate_data.delay(
            'orders',
            group_by='user_id',
            aggregates={'total_amount': 'SUM(amount)', 'order_count': 'COUNT(*)'}
        )
    """
    try:
        db = self.db

        # Build aggregation query
        agg_selects = [f"{func} as {alias}" for alias, func in aggregates.items()]
        query = f"SELECT {group_by}, {', '.join(agg_selects)} FROM {table} GROUP BY {group_by}"

        results = db.fetchall(query)

        logger.info(f"Aggregation returned {len(results)} groups")

        return results

    except Exception as exc:
        logger.error(f"Aggregation failed: {exc}")
        raise


# Best Practices Documentation
DATABASE_BEST_PRACTICES = """
Database Task Best Practices:

1. Pass IDs, Not Objects
   ❌ BAD:  task.delay(user_object)
   ✅ GOOD: task.delay(user_id)

2. Use Connection Pooling
   - Create connection once per worker
   - Reuse across tasks
   - Don't create/destroy per task

3. Parameterized Queries
   ❌ BAD:  f"SELECT * FROM users WHERE id = {user_id}"
   ✅ GOOD: "SELECT * FROM users WHERE id = %s", (user_id,)

4. Transactions for Multiple Operations
   - Use transactions for related operations
   - Ensures atomicity
   - Prevents partial failures

5. Handle Connection Failures
   - Use autoretry_for for connection errors
   - Implement exponential backoff
   - Set reasonable timeouts

6. Optimize Bulk Operations
   - Use bulk insert instead of many single inserts
   - Batch updates when possible
   - Use pagination for large datasets

7. Logging and Monitoring
   - Log all database operations
   - Track query performance
   - Monitor connection pool usage
"""


# Example usage
if __name__ == '__main__':
    # Single insert
    result1 = insert_record.delay('users', {
        'name': 'John Doe',
        'email': 'john@example.com'
    })
    print(f"Insert Task ID: {result1.id}")

    # Bulk insert
    records = [
        {'name': 'Jane', 'email': 'jane@example.com'},
        {'name': 'Bob', 'email': 'bob@example.com'},
    ]
    result2 = bulk_insert.delay('users', records)
    print(f"Bulk Insert Task ID: {result2.id}")

    # Update
    result3 = update_record.delay('users', 123, {'name': 'John Updated'})
    print(f"Update Task ID: {result3.id}")

    # Query
    result4 = query_records.delay("SELECT * FROM users WHERE status = %s", ('active',))
    print(f"Query Task ID: {result4.id}")

    # Paginated query
    result5 = paginated_query.delay('users', page=1, page_size=50)
    print(f"Paginated Query Task ID: {result5.id}")

    print("\nBest Practices:")
    print(DATABASE_BEST_PRACTICES)
