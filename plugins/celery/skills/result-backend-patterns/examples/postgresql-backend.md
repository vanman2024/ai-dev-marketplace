# PostgreSQL Result Backend Complete Setup Guide

Complete guide for configuring Celery with PostgreSQL result backend including database setup, migrations, performance tuning, and maintenance.

## Prerequisites

```bash
# Install PostgreSQL
sudo apt-get install postgresql postgresql-contrib  # Ubuntu/Debian
brew install postgresql                             # macOS

# Install Python dependencies
pip install celery sqlalchemy psycopg2-binary
```

## Database Setup

### 1. Create Database and User

**As PostgreSQL superuser:**
```sql
-- Create database
CREATE DATABASE celery_results
    WITH ENCODING='UTF8'
    LC_COLLATE='en_US.UTF-8'
    LC_CTYPE='en_US.UTF-8'
    TEMPLATE=template0;

-- Create dedicated user
CREATE USER celery WITH PASSWORD 'your_secure_password_here';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE celery_results TO celery;

-- Connect to database
\c celery_results

-- Grant schema privileges (PostgreSQL 15+)
GRANT ALL ON SCHEMA public TO celery;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO celery;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO celery;

-- Make it default for new tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL PRIVILEGES ON TABLES TO celery;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL PRIVILEGES ON SEQUENCES TO celery;
```

**Command line:**
```bash
# Create database and user
sudo -u postgres psql -c "CREATE DATABASE celery_results;"
sudo -u postgres psql -c "CREATE USER celery WITH PASSWORD 'your_secure_password_here';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE celery_results TO celery;"

# Verify
sudo -u postgres psql -d celery_results -c "\du"
```

## Basic PostgreSQL Backend Configuration

### 2. Environment Variables (.env)

```bash
# SECURITY: Never commit actual credentials to git
DB_USER=celery
DB_PASSWORD=your_secure_password_here
DB_HOST=localhost
DB_PORT=5432
DB_NAME=celery_results

# Connection pool settings
DB_POOL_SIZE=10
DB_MAX_OVERFLOW=10
```

### 3. Celery Configuration (celeryconfig.py)

```python
import os
from celery import Celery
from celery.schedules import crontab

# Security: Load from environment
DB_USER = os.getenv('DB_USER', 'celery')
DB_PASSWORD = os.getenv('DB_PASSWORD', '')
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = os.getenv('DB_PORT', '5432')
DB_NAME = os.getenv('DB_NAME', 'celery_results')

# Construct connection string
result_backend = f'db+postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'

app = Celery('myapp', backend=result_backend)

# Database backend configuration
app.conf.update(
    # Table management
    database_create_tables_at_setup=True,  # Auto-create (Celery 5.5+)

    # Table names (customize if needed)
    database_table_names={
        'task': 'celery_taskmeta',
        'group': 'celery_groupmeta',
    },

    # Connection pool
    database_engine_options={
        'pool_size': int(os.getenv('DB_POOL_SIZE', 10)),
        'max_overflow': int(os.getenv('DB_MAX_OVERFLOW', 10)),
        'pool_recycle': 3600,  # Recycle connections hourly
        'pool_pre_ping': True,  # Test connections before use
        'pool_timeout': 30,
        'echo': False,  # Set True for SQL debugging
    },

    # Session management
    database_short_lived_sessions=True,  # Prevent stale connections

    # Result settings
    result_expires=7 * 86400,  # 7 days
    result_serializer='json',
    result_compression='gzip',
    result_extended=True,  # Store extra metadata

    # Automatic cleanup
    beat_schedule={
        'cleanup-expired-results': {
            'task': 'celery.backend_cleanup',
            'schedule': crontab(hour=4, minute=0),  # 4 AM daily
        }
    },
)
```

## Database Schema

### 4. Table Structure

**Celery creates these tables automatically:**

**celery_taskmeta (task results):**
```sql
CREATE TABLE celery_taskmeta (
    id SERIAL PRIMARY KEY,
    task_id VARCHAR(155) UNIQUE NOT NULL,
    status VARCHAR(50) NOT NULL,
    result BYTEA,
    date_done TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    traceback TEXT,
    name VARCHAR(155),
    args BYTEA,
    kwargs BYTEA,
    worker VARCHAR(155),
    retries INTEGER,
    queue VARCHAR(155)
);

-- Indexes for performance
CREATE INDEX celery_taskmeta_task_id ON celery_taskmeta(task_id);
CREATE INDEX celery_taskmeta_status ON celery_taskmeta(status);
CREATE INDEX celery_taskmeta_date_done ON celery_taskmeta(date_done);
CREATE INDEX celery_taskmeta_name ON celery_taskmeta(name);
```

**celery_groupmeta (group results):**
```sql
CREATE TABLE celery_groupmeta (
    id SERIAL PRIMARY KEY,
    taskset_id VARCHAR(155) UNIQUE NOT NULL,
    result BYTEA,
    date_done TIMESTAMP WITHOUT TIME ZONE NOT NULL
);

CREATE INDEX celery_groupmeta_taskset_id ON celery_groupmeta(taskset_id);
CREATE INDEX celery_groupmeta_date_done ON celery_groupmeta(date_done);
```

### 5. Manual Table Creation

If not using auto-creation:

```python
from celery.backends.database import SessionManager, models

def init_database(app):
    """Initialize database tables"""
    session = SessionManager()
    engine = session.get_engine(app.backend.url)

    # Create all tables
    models.ResultModelBase.metadata.create_all(engine)
    print("✓ Database tables created")

    return engine

# Run initialization
engine = init_database(app)
```

## SSL/TLS Configuration

### 6. Secure Database Connections

**PostgreSQL Configuration (pg_hba.conf):**
```conf
# Require SSL for remote connections
hostssl all all 0.0.0.0/0 md5
```

**Enable SSL in postgresql.conf:**
```conf
ssl = on
ssl_cert_file = '/etc/ssl/certs/server.crt'
ssl_key_file = '/etc/ssl/private/server.key'
ssl_ca_file = '/etc/ssl/certs/ca.crt'
```

**Celery Configuration with SSL:**
```python
import os
from celery import Celery

DB_USER = os.getenv('DB_USER', 'celery')
DB_PASSWORD = os.getenv('DB_PASSWORD', '')
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = os.getenv('DB_PORT', '5432')
DB_NAME = os.getenv('DB_NAME', 'celery_results')

result_backend = f'db+postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'

app = Celery('myapp', backend=result_backend)

app.conf.update(
    database_engine_options={
        'pool_size': 10,
        'max_overflow': 10,
        'pool_recycle': 3600,
        'pool_pre_ping': True,

        # SSL configuration
        'connect_args': {
            'sslmode': 'require',  # or 'verify-full' for cert validation
            'sslcert': '/path/to/client-cert.pem',
            'sslkey': '/path/to/client-key.pem',
            'sslrootcert': '/path/to/ca-cert.pem',
        }
    },
)
```

## Performance Optimization

### 7. Indexes

**Add custom indexes for your query patterns:**

```sql
-- Index on worker name (for per-worker queries)
CREATE INDEX idx_celery_worker ON celery_taskmeta(worker);

-- Index on queue name (for per-queue queries)
CREATE INDEX idx_celery_queue ON celery_taskmeta(queue);

-- Composite index for status + date queries
CREATE INDEX idx_celery_status_date ON celery_taskmeta(status, date_done DESC);

-- Partial index for failed tasks only
CREATE INDEX idx_celery_failures ON celery_taskmeta(date_done DESC)
    WHERE status IN ('FAILURE', 'REVOKED');
```

### 8. Connection Pooling

**PgBouncer for Connection Pooling:**

```ini
# pgbouncer.ini
[databases]
celery_results = host=localhost port=5432 dbname=celery_results

[pgbouncer]
listen_port = 6432
listen_addr = 127.0.0.1
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 20
```

**Connect through PgBouncer:**
```python
# Point to PgBouncer instead of PostgreSQL directly
DB_PORT = '6432'  # PgBouncer port
result_backend = f'db+postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:6432/{DB_NAME}'
```

### 9. Partitioning (Large Datasets)

**Partition by date for better performance:**

```sql
-- Create partitioned table
CREATE TABLE celery_taskmeta_partitioned (
    LIKE celery_taskmeta INCLUDING ALL
) PARTITION BY RANGE (date_done);

-- Create partitions (monthly)
CREATE TABLE celery_taskmeta_2025_01 PARTITION OF celery_taskmeta_partitioned
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE celery_taskmeta_2025_02 PARTITION OF celery_taskmeta_partitioned
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

-- Migrate data
INSERT INTO celery_taskmeta_partitioned SELECT * FROM celery_taskmeta;

-- Rename tables
ALTER TABLE celery_taskmeta RENAME TO celery_taskmeta_old;
ALTER TABLE celery_taskmeta_partitioned RENAME TO celery_taskmeta;
```

## Maintenance and Monitoring

### 10. Query Results

```python
from celery.backends.database import SessionManager, models

def query_recent_results(limit=10):
    """Query recent results from database"""
    session = SessionManager()
    engine = session.get_engine(app.backend.url)

    with session(engine=engine) as sess:
        results = sess.query(models.Task).order_by(
            models.Task.date_done.desc()
        ).limit(limit).all()

        for task in results:
            print(f"Task {task.task_id}:")
            print(f"  Status: {task.status}")
            print(f"  Date: {task.date_done}")
            print(f"  Result: {task.result}")
            print()

def query_failed_tasks(hours=24):
    """Query failed tasks from last N hours"""
    from datetime import datetime, timedelta

    session = SessionManager()
    engine = session.get_engine(app.backend.url)
    cutoff = datetime.utcnow() - timedelta(hours=hours)

    with session(engine=engine) as sess:
        failures = sess.query(models.Task).filter(
            models.Task.status == 'FAILURE',
            models.Task.date_done > cutoff
        ).all()

        print(f"Failed tasks (last {hours} hours): {len(failures)}")
        for task in failures:
            print(f"  {task.task_id}: {task.name}")
            print(f"    {task.traceback[:200]}...")
```

### 11. Archival Strategy

```python
def archive_old_results(days=30, archive_table='celery_taskmeta_archive'):
    """Archive old results to separate table"""
    from datetime import datetime, timedelta
    from celery.backends.database import SessionManager, models

    session = SessionManager()
    engine = session.get_engine(app.backend.url)
    cutoff = datetime.utcnow() - timedelta(days=days)

    # Create archive table if not exists
    with engine.connect() as conn:
        conn.execute(f"""
            CREATE TABLE IF NOT EXISTS {archive_table} (
                LIKE celery_taskmeta INCLUDING ALL
            )
        """)

        # Copy old records to archive
        conn.execute(f"""
            INSERT INTO {archive_table}
            SELECT * FROM celery_taskmeta
            WHERE date_done < %s
        """, (cutoff,))

        # Delete from main table
        result = conn.execute(f"""
            DELETE FROM celery_taskmeta
            WHERE date_done < %s
        """, (cutoff,))

        conn.commit()
        print(f"Archived {result.rowcount} old results")
```

### 12. Vacuum and Analyze

```sql
-- Regular maintenance (should be automated with cron)
VACUUM ANALYZE celery_taskmeta;
VACUUM ANALYZE celery_groupmeta;

-- Full vacuum (locks table, run during maintenance window)
VACUUM FULL celery_taskmeta;

-- Update statistics
ANALYZE celery_taskmeta;
```

**Automate with cron:**
```bash
# /etc/cron.daily/postgres-maintenance.sh
#!/bin/bash
psql -U celery -d celery_results -c "VACUUM ANALYZE celery_taskmeta;"
```

## Troubleshooting

### Connection Issues

**Problem: FATAL: password authentication failed**
```bash
# Verify credentials
psql -U celery -d celery_results -h localhost -W

# Check pg_hba.conf
sudo cat /etc/postgresql/*/main/pg_hba.conf | grep celery
```

**Problem: Connection pool exhausted**
```python
# Increase pool size
database_engine_options={
    'pool_size': 20,  # Increase
    'max_overflow': 20,  # Increase
    'pool_timeout': 60,  # Increase wait time
}
```

### Performance Issues

**Problem: Slow result retrieval**

```sql
-- Check query performance
EXPLAIN ANALYZE
SELECT * FROM celery_taskmeta
WHERE task_id = 'some-task-id';

-- Check missing indexes
SELECT schemaname, tablename, attname, n_distinct, correlation
FROM pg_stats
WHERE tablename = 'celery_taskmeta'
ORDER BY abs(correlation) DESC;

-- Check table bloat
SELECT schemaname, tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    n_tup_upd + n_tup_del AS total_updates,
    n_live_tup AS live_tuples,
    n_dead_tup AS dead_tuples
FROM pg_stat_user_tables
WHERE tablename = 'celery_taskmeta';
```

**Problem: Stale connections**

```python
# Enable pre-ping
database_engine_options={
    'pool_pre_ping': True,  # Verify connections
}

# Or use short-lived sessions
database_short_lived_sessions=True
```

## Security Best Practices

1. **Use strong passwords:**
   ```sql
   ALTER USER celery WITH PASSWORD 'complex_random_password_here';
   ```

2. **Limit database permissions:**
   ```sql
   -- Revoke unnecessary privileges
   REVOKE CREATE ON SCHEMA public FROM PUBLIC;
   GRANT CONNECT ON DATABASE celery_results TO celery;
   ```

3. **Use SSL for connections:**
   ```python
   connect_args={'sslmode': 'require'}
   ```

4. **Restrict network access (pg_hba.conf):**
   ```conf
   # Only allow from specific IPs
   host celery_results celery 10.0.0.0/24 md5
   ```

5. **Store credentials in environment:**
   ```bash
   # Never commit to git
   DB_PASSWORD=actual_password_here
   ```

## Complete Example

**Directory Structure:**
```
myproject/
├── .env                 # Credentials (not in git)
├── .env.example         # Template (in git)
├── .gitignore
├── celeryconfig.py
├── tasks.py
├── migrations/          # Database migrations
│   └── init_db.py
└── maintenance/         # Maintenance scripts
    ├── archive_old.py
    └── vacuum.sh
```

**migrations/init_db.py:**
```python
from celeryconfig import app
from celery.backends.database import SessionManager, models

def init_database():
    session = SessionManager()
    engine = session.get_engine(app.backend.url)
    models.ResultModelBase.metadata.create_all(engine)
    print("✓ Database initialized")

if __name__ == '__main__':
    init_database()
```

**Usage:**
```bash
# Initialize database
python migrations/init_db.py

# Start worker
celery -A tasks worker --loglevel=info

# Monitor database
watch -n 5 'psql -U celery -d celery_results -c "SELECT COUNT(*) FROM celery_taskmeta;"'
```

## Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [Celery Database Backend](https://docs.celeryq.dev/en/stable/userguide/configuration.html#database-backend-settings)
- [PgBouncer](https://www.pgbouncer.org/)

---

**Last Updated:** 2025-11-16
**Celery Version:** 5.0+
**PostgreSQL Version:** 12+
