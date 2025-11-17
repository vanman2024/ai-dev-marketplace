"""
Celery Database Result Backend Configuration
=============================================

Database backend is ideal for long-term result storage and when you need
SQL query capabilities for result analysis.

Supports: PostgreSQL, MySQL, SQLite, Oracle

SECURITY: Never hardcode credentials. Use environment variables.
"""

import os
from celery import Celery
from celery.schedules import crontab

# Security: Load database credentials from environment
DB_USER = os.getenv('DB_USER', 'celery')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'your_db_password_here')
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = os.getenv('DB_PORT', '5432')  # PostgreSQL default
DB_NAME = os.getenv('DB_NAME', 'celery_results')

# Construct Database URL
# PostgreSQL
result_backend = f'db+postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'

# MySQL
# result_backend = f'db+mysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'

# SQLite (for development only)
# result_backend = 'db+sqlite:///celery_results.db'

app = Celery('myapp', backend=result_backend)

# Database Backend Configuration
app.conf.update(
    # Table Creation
    database_create_tables_at_setup=True,  # Auto-create tables (Celery 5.5+)

    # Table Names (customize if needed)
    database_table_names={
        'task': 'celery_taskmeta',
        'group': 'celery_groupmeta',
    },

    # Connection Pool Settings
    database_engine_options={
        'pool_size': 10,           # Number of connections to maintain
        'max_overflow': 10,        # Max connections beyond pool_size
        'pool_recycle': 3600,      # Recycle connections after 1 hour
        'pool_pre_ping': True,     # Test connections before use
        'pool_timeout': 30,        # Timeout waiting for connection
        'echo': False,             # Set to True for SQL query logging

        # MySQL CRITICAL: Change transaction isolation level
        # 'isolation_level': 'READ COMMITTED',

        # PostgreSQL SSL
        # 'connect_args': {
        #     'sslmode': 'require',
        #     'sslcert': '/path/to/cert.pem',
        #     'sslkey': '/path/to/key.pem',
        #     'sslrootcert': '/path/to/ca.pem',
        # }
    },

    # Session Management
    database_short_lived_sessions=True,  # Fix stale connection issues

    # Result Expiration
    result_expires=7 * 86400,  # 7 days (longer than Redis typically)
    # result_expires=None,  # Never expire (requires manual cleanup)

    # Serialization
    result_serializer='json',
    result_accept_content=['json'],
    result_compression='gzip',

    # Extended Metadata
    result_extended=True,

    # Automatic Cleanup (requires celery beat)
    beat_schedule={
        'cleanup-expired-results': {
            'task': 'celery.backend_cleanup',
            'schedule': crontab(hour=4, minute=0),  # Run at 4 AM daily
        }
    },
)

# Example Tasks
@app.task(bind=True)
def long_running_task(self, data):
    """Task with results stored long-term for audit"""
    # Process data
    result = {'processed': len(data), 'task_id': self.request.id}
    return result

@app.task(ignore_result=True)
def fire_and_forget_task(data):
    """Task that doesn't need result storage"""
    # Do work without storing result
    print(f"Processing {data}")

# Database Initialization Script
def init_database():
    """Initialize database tables if not using auto-creation"""
    from celery.backends.database import SessionManager

    session = SessionManager()
    engine = session.get_engine(app.backend.url)

    # Import models
    from celery.backends.database import models

    # Create all tables
    models.ResultModelBase.metadata.create_all(engine)
    print("Database tables created successfully")

# Query Results from Database
def query_recent_results(limit=10):
    """Example: Query recent results from database"""
    from celery.backends.database import SessionManager
    from celery.backends.database.models import Task

    session = SessionManager()
    engine = session.get_engine(app.backend.url)

    with session(engine=engine) as sess:
        results = sess.query(Task).order_by(
            Task.date_done.desc()
        ).limit(limit).all()

        for task in results:
            print(f"Task {task.task_id}: {task.status}")
            print(f"  Result: {task.result}")
            print(f"  Date: {task.date_done}")

# Archive Old Results
def archive_old_results(days=30):
    """Move results older than N days to archive table"""
    from datetime import datetime, timedelta
    from celery.backends.database import SessionManager
    from celery.backends.database.models import Task

    session = SessionManager()
    engine = session.get_engine(app.backend.url)
    cutoff_date = datetime.utcnow() - timedelta(days=days)

    with session(engine=engine) as sess:
        old_tasks = sess.query(Task).filter(
            Task.date_done < cutoff_date
        ).all()

        # Archive logic here (copy to archive table, then delete)
        count = len(old_tasks)
        print(f"Archived {count} old results")

if __name__ == '__main__':
    # Initialize database if needed
    # init_database()

    # Send task
    result = long_running_task.delay(['item1', 'item2', 'item3'])

    # Get result
    print(f"Result: {result.get(timeout=30)}")

    # Query recent results
    # query_recent_results()

"""
Environment Variables (.env):
------------------------------
DB_USER=celery
DB_PASSWORD=your_secure_password_here
DB_HOST=localhost
DB_PORT=5432
DB_NAME=celery_results

PostgreSQL Setup:
-----------------
CREATE DATABASE celery_results;
CREATE USER celery WITH PASSWORD 'your_secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE celery_results TO celery;

MySQL Setup:
------------
CREATE DATABASE celery_results CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'celery'@'localhost' IDENTIFIED BY 'your_secure_password_here';
GRANT ALL PRIVILEGES ON celery_results.* TO 'celery'@'localhost';
FLUSH PRIVILEGES;

# CRITICAL for MySQL - Add to my.cnf:
[mysqld]
transaction-isolation = READ-COMMITTED

Dependencies:
-------------
pip install sqlalchemy
pip install psycopg2-binary  # PostgreSQL
# OR
pip install mysqlclient  # MySQL

Indexes (for performance):
---------------------------
CREATE INDEX idx_task_id ON celery_taskmeta(task_id);
CREATE INDEX idx_status ON celery_taskmeta(status);
CREATE INDEX idx_date_done ON celery_taskmeta(date_done);
"""
