#!/bin/bash
set -euo pipefail

# Setup Test Environment for Supabase E2E Testing
# This script initializes the test environment, creates test database,
# and sets up necessary configuration files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Supabase CLI is installed
check_supabase_cli() {
    if ! command -v supabase &> /dev/null; then
        log_error "Supabase CLI not found. Install it first:"
        echo "  npm install -g supabase"
        echo "  or visit: https://supabase.com/docs/guides/cli"
        exit 1
    fi
    log_info "Supabase CLI found: $(supabase --version)"
}

# Create test directory structure
create_test_directories() {
    log_info "Creating test directory structure..."

    mkdir -p "$PROJECT_ROOT/tests"/{database,auth,vector,realtime,integration,fixtures}
    mkdir -p "$PROJECT_ROOT/supabase/tests/database"

    log_info "Test directories created"
}

# Create .env.test file
create_env_test() {
    local env_file="$PROJECT_ROOT/.env.test"

    if [[ -f "$env_file" ]]; then
        log_warn ".env.test already exists, skipping creation"
        return
    fi

    log_info "Creating .env.test file..."

    cat > "$env_file" << 'EOF'
# Supabase Test Environment Configuration
# IMPORTANT: Use a dedicated test project, never production!

# Test Database Connection
SUPABASE_TEST_URL=http://localhost:54321
SUPABASE_TEST_ANON_KEY=your-test-anon-key-here
SUPABASE_TEST_SERVICE_ROLE_KEY=your-test-service-role-key-here

# Test Database Direct Connection (for pgTAP)
DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres

# Test Configuration
NODE_ENV=test
TEST_TIMEOUT=30000
TEST_CLEANUP_ENABLED=true

# OpenAI (for embedding tests - optional)
OPENAI_API_KEY=your-openai-api-key-here

# Test Data Settings
TEST_USER_EMAIL_PREFIX=test-user
TEST_USER_PASSWORD=Test123!@#
EOF

    log_info ".env.test created - PLEASE UPDATE WITH YOUR TEST PROJECT CREDENTIALS"
}

# Initialize local Supabase instance
init_local_supabase() {
    log_info "Checking for local Supabase instance..."

    if [[ ! -f "$PROJECT_ROOT/supabase/config.toml" ]]; then
        read -p "Initialize local Supabase instance? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "$PROJECT_ROOT"
            supabase init
            log_info "Local Supabase initialized"
        else
            log_warn "Skipping local Supabase initialization"
            return
        fi
    fi

    # Check if Supabase is running
    if ! supabase status &> /dev/null; then
        read -p "Start local Supabase instance? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "$PROJECT_ROOT"
            supabase start
            log_info "Local Supabase started"

            # Get credentials
            supabase status | grep -E "(API URL|anon key|service_role key)"
        fi
    else
        log_info "Local Supabase is already running"
    fi
}

# Create sample pgTAP test
create_sample_pgtap_test() {
    local test_file="$PROJECT_ROOT/supabase/tests/database/example.test.sql"

    if [[ -f "$test_file" ]]; then
        log_warn "Sample pgTAP test already exists, skipping"
        return
    fi

    log_info "Creating sample pgTAP test..."

    cat > "$test_file" << 'EOF'
begin;

-- Enable pgTAP
create extension if not exists pgtap;

select plan(3);

-- Test 1: Check if pgvector extension exists
select has_extension('vector', 'pgvector extension should be enabled');

-- Test 2: Check if a table exists (example)
select has_table('public', 'users', 'users table should exist');

-- Test 3: Check RLS is enabled
select row_security_on('public', 'users', 'RLS should be enabled on users table');

select * from finish();

rollback;
EOF

    log_info "Sample pgTAP test created at $test_file"
}

# Create package.json test scripts
create_package_scripts() {
    log_info "Checking for package.json..."

    if [[ ! -f "$PROJECT_ROOT/package.json" ]]; then
        log_warn "package.json not found, creating basic one..."

        cat > "$PROJECT_ROOT/package.json" << 'EOF'
{
  "name": "supabase-e2e-tests",
  "version": "1.0.0",
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:db": "supabase test db",
    "test:auth": "jest tests/auth",
    "test:vector": "jest tests/vector",
    "test:realtime": "jest tests/realtime",
    "test:e2e": "jest tests/integration",
    "test:all": "npm run test:db && npm run test"
  },
  "devDependencies": {
    "@supabase/supabase-js": "^2.39.0",
    "@types/jest": "^29.5.11",
    "jest": "^29.7.0",
    "ts-jest": "^29.1.1",
    "typescript": "^5.3.3",
    "dotenv": "^16.3.1"
  }
}
EOF
        log_info "package.json created with test scripts"
    else
        log_info "package.json already exists"
    fi
}

# Create Jest configuration
create_jest_config() {
    local config_file="$PROJECT_ROOT/jest.config.js"

    if [[ -f "$config_file" ]]; then
        log_warn "jest.config.js already exists, skipping"
        return
    fi

    log_info "Creating Jest configuration..."

    cat > "$config_file" << 'EOF'
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/tests'],
  testMatch: ['**/*.test.ts'],
  setupFilesAfterEnv: ['<rootDir>/tests/setup.ts'],
  collectCoverageFrom: [
    'tests/**/*.ts',
    '!tests/**/*.test.ts',
    '!tests/fixtures/**'
  ],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70
    }
  },
  testTimeout: 30000,
  maxWorkers: 4
};
EOF

    log_info "Jest configuration created"
}

# Create test setup file
create_test_setup() {
    local setup_file="$PROJECT_ROOT/tests/setup.ts"

    if [[ -f "$setup_file" ]]; then
        log_warn "tests/setup.ts already exists, skipping"
        return
    fi

    log_info "Creating test setup file..."

    cat > "$setup_file" << 'EOF'
import { config } from 'dotenv';
import { createClient } from '@supabase/supabase-js';

// Load test environment variables
config({ path: '.env.test' });

// Global test configuration
export const testConfig = {
  supabaseUrl: process.env.SUPABASE_TEST_URL!,
  supabaseAnonKey: process.env.SUPABASE_TEST_ANON_KEY!,
  supabaseServiceRoleKey: process.env.SUPABASE_TEST_SERVICE_ROLE_KEY!,
  testTimeout: parseInt(process.env.TEST_TIMEOUT || '30000'),
  cleanupEnabled: process.env.TEST_CLEANUP_ENABLED === 'true'
};

// Create test client
export const supabase = createClient(
  testConfig.supabaseUrl,
  testConfig.supabaseAnonKey
);

// Create admin client (service role)
export const supabaseAdmin = createClient(
  testConfig.supabaseUrl,
  testConfig.supabaseServiceRoleKey
);

// Global setup
beforeAll(() => {
  console.log('Starting E2E tests...');
});

// Global teardown
afterAll(async () => {
  console.log('E2E tests completed');
});
EOF

    log_info "Test setup file created"
}

# Create .gitignore entries
update_gitignore() {
    local gitignore_file="$PROJECT_ROOT/.gitignore"

    if [[ ! -f "$gitignore_file" ]]; then
        touch "$gitignore_file"
    fi

    # Check if test entries exist
    if ! grep -q "# Test files" "$gitignore_file"; then
        log_info "Adding test entries to .gitignore..."

        cat >> "$gitignore_file" << 'EOF'

# Test files
.env.test
coverage/
*.test.js
*.test.js.map
test-results/
junit.xml
EOF
        log_info ".gitignore updated"
    else
        log_info ".gitignore already has test entries"
    fi
}

# Main execution
main() {
    log_info "Setting up Supabase E2E test environment..."

    check_supabase_cli
    create_test_directories
    create_env_test
    init_local_supabase
    create_sample_pgtap_test
    create_package_scripts
    create_jest_config
    create_test_setup
    update_gitignore

    echo ""
    log_info "Test environment setup complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Update .env.test with your test project credentials"
    echo "  2. Install dependencies: npm install"
    echo "  3. Run database tests: npm run test:db"
    echo "  4. Run integration tests: npm test"
    echo ""
    echo "For local development:"
    echo "  - Start Supabase: supabase start"
    echo "  - Stop Supabase: supabase stop"
    echo "  - Reset database: supabase db reset"
}

main "$@"
