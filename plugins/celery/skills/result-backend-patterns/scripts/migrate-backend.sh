#!/bin/bash
#
# Migrate Celery Result Backend
# ==============================
#
# Safe migration between result backends with zero downtime.
# Supports: redis → postgresql, postgresql → redis, etc.
#
# Usage: ./migrate-backend.sh <source-backend> <target-backend>
#
# Examples:
#   ./migrate-backend.sh redis postgresql
#   ./migrate-backend.sh postgresql redis
#
# Migration Strategy:
# 1. Configure new backend
# 2. Enable dual-write mode
# 3. Verify new backend
# 4. Switch reads to new backend
# 5. Deprecate old backend
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# Check arguments
if [ "$#" -ne 2 ]; then
    print_error "Usage: $0 <source-backend> <target-backend>"
    echo ""
    echo "Supported backends: redis, postgresql, mysql, sqlite"
    echo ""
    echo "Examples:"
    echo "  $0 redis postgresql    # Migrate from Redis to PostgreSQL"
    echo "  $0 postgresql redis    # Migrate from PostgreSQL to Redis"
    exit 1
fi

SOURCE_BACKEND="$1"
TARGET_BACKEND="$2"

print_info "Planning migration from $SOURCE_BACKEND to $TARGET_BACKEND"
echo ""

# Validate backends
validate_backend() {
    case "$1" in
        redis|postgresql|mysql|sqlite)
            return 0
            ;;
        *)
            print_error "Unsupported backend: $1"
            exit 1
            ;;
    esac
}

validate_backend "$SOURCE_BACKEND"
validate_backend "$TARGET_BACKEND"

if [ "$SOURCE_BACKEND" = "$TARGET_BACKEND" ]; then
    print_error "Source and target backends must be different"
    exit 1
fi

# Step 1: Test current backend
print_info "Step 1/6: Testing current backend ($SOURCE_BACKEND)..."
if bash "$(dirname "$0")/test-backend.sh" "$SOURCE_BACKEND"; then
    print_success "Current backend is operational"
else
    print_error "Current backend test failed. Fix before migrating."
    exit 1
fi
echo ""

# Step 2: Test new backend
print_info "Step 2/6: Testing new backend ($TARGET_BACKEND)..."
if bash "$(dirname "$0")/test-backend.sh" "$TARGET_BACKEND"; then
    print_success "New backend is operational"
else
    print_error "New backend test failed. Configure before migrating."
    exit 1
fi
echo ""

# Step 3: Generate dual-write configuration
print_info "Step 3/6: Generating dual-write configuration..."

DUAL_WRITE_SCRIPT=$(mktemp /tmp/celery_dual_write_XXXXXX.py)

cat > "$DUAL_WRITE_SCRIPT" <<'EOF'
"""
Celery Dual-Write Backend for Zero-Downtime Migration
======================================================

This backend writes to both old and new backends during migration.
"""

import os
from celery import Celery
from celery.backends.redis import RedisBackend
from celery.backends.database import DatabaseBackend

class DualWriteBackend:
    """Write to both backends, read from new backend"""

    def __init__(self, app, source_backend, target_backend):
        self.app = app
        self.source = self._create_backend(source_backend)
        self.target = self._create_backend(target_backend)
        print(f"Dual-write mode: {source_backend} → {target_backend}")

    def _create_backend(self, backend_url):
        """Create backend instance from URL"""
        if backend_url.startswith('redis'):
            return RedisBackend(app=self.app, url=backend_url)
        elif backend_url.startswith('db+'):
            return DatabaseBackend(app=self.app, url=backend_url)
        else:
            raise ValueError(f"Unsupported backend: {backend_url}")

    def store_result(self, task_id, result, state, **kwargs):
        """Store result in both backends"""
        try:
            # Write to source (old) backend
            self.source.store_result(task_id, result, state, **kwargs)
        except Exception as e:
            print(f"Warning: Source backend write failed: {e}")

        try:
            # Write to target (new) backend
            self.target.store_result(task_id, result, state, **kwargs)
        except Exception as e:
            print(f"Error: Target backend write failed: {e}")
            raise

    def get_result(self, task_id):
        """Read from new backend (target)"""
        try:
            return self.target.get_result(task_id)
        except Exception as e:
            # Fallback to source backend
            print(f"Target backend read failed, falling back to source: {e}")
            return self.source.get_result(task_id)

    def forget(self, task_id):
        """Delete from both backends"""
        try:
            self.source.forget(task_id)
        except Exception:
            pass

        try:
            self.target.forget(task_id)
        except Exception:
            pass

# Configuration
SOURCE_BACKEND = os.getenv('SOURCE_BACKEND_URL')
TARGET_BACKEND = os.getenv('TARGET_BACKEND_URL')

app = Celery('myapp')
app.backend = DualWriteBackend(app, SOURCE_BACKEND, TARGET_BACKEND)

print("Dual-write backend configured successfully")
print(f"  Source: {SOURCE_BACKEND}")
print(f"  Target: {TARGET_BACKEND}")
EOF

print_success "Dual-write configuration generated: $DUAL_WRITE_SCRIPT"
echo ""

# Step 4: Build backend URLs
print_info "Step 4/6: Building backend connection strings..."

get_backend_url() {
    case "$1" in
        redis)
            REDIS_HOST="${REDIS_HOST:-localhost}"
            REDIS_PORT="${REDIS_PORT:-6379}"
            REDIS_PASSWORD="${REDIS_PASSWORD:-}"
            REDIS_DB="${REDIS_DB:-0}"

            if [ -n "$REDIS_PASSWORD" ]; then
                echo "redis://:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}/${REDIS_DB}"
            else
                echo "redis://${REDIS_HOST}:${REDIS_PORT}/${REDIS_DB}"
            fi
            ;;

        postgresql)
            DB_USER="${DB_USER:-celery}"
            DB_PASSWORD="${DB_PASSWORD:-}"
            DB_HOST="${DB_HOST:-localhost}"
            DB_PORT="${DB_PORT:-5432}"
            DB_NAME="${DB_NAME:-celery_results}"
            echo "db+postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
            ;;

        mysql)
            DB_USER="${DB_USER:-celery}"
            DB_PASSWORD="${DB_PASSWORD:-}"
            DB_HOST="${DB_HOST:-localhost}"
            DB_PORT="${DB_PORT:-3306}"
            DB_NAME="${DB_NAME:-celery_results}"
            echo "db+mysql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
            ;;

        sqlite)
            SQLITE_PATH="${SQLITE_PATH:-./celery_results.db}"
            echo "db+sqlite:///${SQLITE_PATH}"
            ;;
    esac
}

SOURCE_URL=$(get_backend_url "$SOURCE_BACKEND")
TARGET_URL=$(get_backend_url "$TARGET_BACKEND")

print_success "Backend URLs configured"
echo ""

# Step 5: Provide migration instructions
print_info "Step 5/6: Migration instructions..."
echo ""

cat <<INSTRUCTIONS
${GREEN}Migration Plan:${NC}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${YELLOW}Phase 1: Enable Dual-Write Mode${NC}
---------------------------------
Add this to your Celery configuration:

${BLUE}# celeryconfig.py${NC}
import os
from celery.backends.redis import RedisBackend
from celery.backends.database import DatabaseBackend

class DualWriteBackend:
    def __init__(self, app):
        self.source = self._create_backend('$SOURCE_URL')
        self.target = self._create_backend('$TARGET_URL')

    def _create_backend(self, url):
        if url.startswith('redis'):
            return RedisBackend(app=app, url=url)
        elif url.startswith('db+'):
            return DatabaseBackend(app=app, url=url)

    def store_result(self, task_id, result, state, **kwargs):
        # Write to both
        self.source.store_result(task_id, result, state, **kwargs)
        self.target.store_result(task_id, result, state, **kwargs)

    def get_result(self, task_id):
        # Read from new backend
        return self.target.get_result(task_id)

app.backend = DualWriteBackend(app)

${YELLOW}Phase 2: Deploy and Monitor${NC}
----------------------------
1. Deploy dual-write configuration
2. Monitor both backends for errors
3. Verify writes to both backends
4. Run for at least result_expires duration

${YELLOW}Phase 3: Switch to New Backend${NC}
--------------------------------
Once confident, update configuration:

${BLUE}# celeryconfig.py${NC}
result_backend = '$TARGET_URL'

${YELLOW}Phase 4: Deprecate Old Backend${NC}
-------------------------------
1. Deploy new configuration
2. Monitor for errors
3. After result_expires, old results will naturally expire
4. Decommission old backend service

${YELLOW}Phase 5: Cleanup${NC}
-----------------
Remove dual-write code and old backend references

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${GREEN}Environment Variables:${NC}

INSTRUCTIONS

# Show backend-specific env vars
case "$SOURCE_BACKEND" in
    redis)
        echo "# Source ($SOURCE_BACKEND)"
        echo "REDIS_HOST=${REDIS_HOST:-localhost}"
        echo "REDIS_PORT=${REDIS_PORT:-6379}"
        echo "REDIS_PASSWORD=***"
        ;;
    postgresql|mysql)
        echo "# Source ($SOURCE_BACKEND)"
        echo "DB_USER=${DB_USER:-celery}"
        echo "DB_PASSWORD=***"
        echo "DB_HOST=${DB_HOST:-localhost}"
        ;;
esac

echo ""

case "$TARGET_BACKEND" in
    redis)
        echo "# Target ($TARGET_BACKEND)"
        echo "REDIS_HOST=${REDIS_HOST:-localhost}"
        echo "REDIS_PORT=${REDIS_PORT:-6379}"
        echo "REDIS_PASSWORD=***"
        ;;
    postgresql|mysql)
        echo "# Target ($TARGET_BACKEND)"
        echo "DB_USER=${DB_USER:-celery}"
        echo "DB_PASSWORD=***"
        echo "DB_HOST=${DB_HOST:-localhost}"
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 6: Data migration (if needed)
print_info "Step 6/6: Data migration considerations..."
echo ""

print_warning "Data Migration:"
echo "  • Active results will be dual-written automatically"
echo "  • Historical results need manual migration if required"
echo "  • Consider result expiration before migrating historical data"
echo ""

if [ "$SOURCE_BACKEND" = "postgresql" ] || [ "$SOURCE_BACKEND" = "mysql" ]; then
    print_info "To migrate historical data from database:"
    echo "  1. Export results from source database"
    echo "  2. Transform to target backend format"
    echo "  3. Import to target backend"
    echo ""
fi

if [ "$TARGET_BACKEND" = "postgresql" ] || [ "$TARGET_BACKEND" = "mysql" ]; then
    print_info "To migrate historical data to database:"
    echo "  1. Query active results from Redis"
    echo "  2. Transform to database format"
    echo "  3. Insert into target database tables"
    echo ""
fi

# Summary
print_success "Migration plan generated successfully!"
echo ""
print_info "Next steps:"
echo "  1. Review migration instructions above"
echo "  2. Test dual-write configuration in staging"
echo "  3. Deploy to production during low-traffic period"
echo "  4. Monitor both backends for errors"
echo "  5. Switch to new backend after verification"
echo ""
print_warning "Important: Keep dual-write active for at least result_expires duration"
echo ""

exit 0
