# Test Data Management Strategies

Comprehensive guide for managing test data in Supabase E2E tests - from fixtures to factories, isolation to cleanup.

## Overview

Effective test data management is crucial for:
- **Reliability**: Consistent, reproducible tests
- **Isolation**: Tests don't affect each other
- **Performance**: Fast test execution
- **Maintenance**: Easy to update as schema evolves

## Strategy 1: Fixtures

### What are Fixtures?

Fixtures are predefined, static test data loaded before tests run.

### When to Use

- Consistent baseline data needed across tests
- Complex data relationships
- Read-only test scenarios
- Reference data (categories, settings, etc.)

### Implementation

#### Create Fixture Files

`tests/fixtures/users.json`:
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000"
    "email": "test-user-1@example.com"
    "name": "Test User 1"
    "role": "admin"
  }
  {
    "id": "550e8400-e29b-41d4-a716-446655440001"
    "email": "test-user-2@example.com"
    "name": "Test User 2"
    "role": "user"
  }
]
```

#### Fixture Loader

`tests/utils/fixtures.ts`:
```typescript
import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';
import { join } from 'path';

export class FixtureLoader {
  constructor(private supabase: SupabaseClient) {}

  async load(fixtureName: string): Promise<any[]> {
    const filePath = join(__dirname, '../fixtures', `${fixtureName}.json`);
    const data = JSON.parse(readFileSync(filePath, 'utf-8'));

    const { error } = await this.supabase
      .from(fixtureName)
      .insert(data);

    if (error) throw error;

    return data;
  }

  async loadMultiple(...fixtures: string[]): Promise<void> {
    for (const fixture of fixtures) {
      await this.load(fixture);
    }
  }

  async clear(tableName: string): Promise<void> {
    await this.supabase
      .from(tableName)
      .delete()
      .neq('id', 0); // Delete all
  }
}
```

#### Usage in Tests

```typescript
import { FixtureLoader } from './utils/fixtures';

describe('User Tests', () => {
  let fixtureLoader: FixtureLoader;

  beforeAll(async () => {
    fixtureLoader = new FixtureLoader(supabase);
    await fixtureLoader.load('users');
  });

  afterAll(async () => {
    await fixtureLoader.clear('users');
  });

  test('should find admin users', async () => {
    const { data } = await supabase
      .from('users')
      .select('*')
      .eq('role', 'admin');

    expect(data).toHaveLength(1);
    expect(data[0].email).toBe('test-user-1@example.com');
  });
});
```

## Strategy 2: Factories

### What are Factories?

Factories generate test data dynamically with sensible defaults and customization options.

### When to Use

- Need unique data per test
- Testing data validation
- Create-modify-delete scenarios
- Testing with variations

### Implementation

#### Factory Pattern

`tests/factories/userFactory.ts`:
```typescript
import { faker } from '@faker-js/faker';

export interface UserAttributes {
  email?: string;
  name?: string;
  role?: 'admin' | 'user' | 'guest';
  metadata?: Record<string, any>;
}

export class UserFactory {
  constructor(private supabase: SupabaseClient) {}

  async create(attributes: UserAttributes = {}) {
    const userData = {
      email: attributes.email || faker.internet.email()
      name: attributes.name || faker.person.fullName()
      role: attributes.role || 'user'
      metadata: attributes.metadata || {}
      created_at: new Date().toISOString()
    };

    const { data, error } = await this.supabase
      .from('users')
      .insert(userData)
      .select()
      .single();

    if (error) throw error;

    return data;
  }

  async createMany(count: number, attributes: UserAttributes = {}) {
    const users = [];

    for (let i = 0; i < count; i++) {
      users.push(await this.create(attributes));
    }

    return users;
  }

  async createAdmin(attributes: UserAttributes = {}) {
    return this.create({ ...attributes, role: 'admin' });
  }

  async createWithAuth(attributes: UserAttributes = {}) {
    const password = 'TestPassword123!';
    const email = attributes.email || faker.internet.email();

    // Create auth user
    const { data: authData, error: authError } =
      await this.supabase.auth.signUp({
        email
        password
      });

    if (authError) throw authError;

    // Create database user record
    const user = await this.create({
      ...attributes
      email
      auth_id: authData.user!.id
    });

    return {
      user
      email
      password
      authUser: authData.user
    };
  }
}
```

#### Usage in Tests

```typescript
import { UserFactory } from './factories/userFactory';

describe('User CRUD', () => {
  let userFactory: UserFactory;
  let createdUsers: any[] = [];

  beforeAll(() => {
    userFactory = new UserFactory(supabase);
  });

  afterEach(async () => {
    // Cleanup created users
    for (const user of createdUsers) {
      await supabase.from('users').delete().eq('id', user.id);
    }
    createdUsers = [];
  });

  test('should create user with factory', async () => {
    const user = await userFactory.create({
      name: 'Specific Name'
      role: 'admin'
    });

    createdUsers.push(user);

    expect(user.name).toBe('Specific Name');
    expect(user.role).toBe('admin');
    expect(user.email).toMatch(/@/); // Generated email
  });

  test('should create multiple users', async () => {
    const users = await userFactory.createMany(5);

    createdUsers.push(...users);

    expect(users).toHaveLength(5);
    expect(new Set(users.map(u => u.email)).size).toBe(5); // Unique emails
  });
});
```

## Strategy 3: Database Transactions

### Transaction-Based Isolation

Each test runs in a transaction that's rolled back after the test.

### Implementation

```typescript
import { createClient } from '@supabase/supabase-js';

export class TransactionalTestContext {
  private transactionId: string;

  async begin() {
    // Note: Supabase JS client doesn't support transactions directly
    // This requires using pg directly or custom RPC functions

    const { data } = await supabase.rpc('begin_test_transaction');
    this.transactionId = data.transaction_id;
  }

  async rollback() {
    await supabase.rpc('rollback_test_transaction', {
      transaction_id: this.transactionId
    });
  }
}

// Usage
describe('Transactional Tests', () => {
  let context: TransactionalTestContext;

  beforeEach(async () => {
    context = new TransactionalTestContext();
    await context.begin();
  });

  afterEach(async () => {
    await context.rollback();
  });

  test('changes are isolated', async () => {
    // All database changes in this test will be rolled back
    await supabase.from('users').insert({ email: 'temp@test.com' });
    // ...test logic...
  });
});
```

## Strategy 4: Namespace Isolation

### Prefix-Based Isolation

Use prefixes to identify and cleanup test data.

### Implementation

```typescript
export class TestDataManager {
  private readonly prefix = `test_${Date.now()}_`;
  private createdIds: Map<string, any[]> = new Map();

  generateEmail(): string {
    return `${this.prefix}${Math.random().toString(36).substring(7)}@test.com`;
  }

  async create<T>(table: string, data: any): Promise<T> {
    const { data: created, error } = await supabase
      .from(table)
      .insert(data)
      .select()
      .single();

    if (error) throw error;

    // Track for cleanup
    if (!this.createdIds.has(table)) {
      this.createdIds.set(table, []);
    }
    this.createdIds.get(table)!.push(created.id);

    return created;
  }

  async cleanup(): Promise<void> {
    for (const [table, ids] of this.createdIds.entries()) {
      await supabase.from(table).delete().in('id', ids);
    }
    this.createdIds.clear();
  }

  async cleanupByPrefix(): Promise<void> {
    // Cleanup users with test prefix
    await supabase
      .from('users')
      .delete()
      .like('email', `${this.prefix}%`);
  }
}

// Usage
describe('Namespace Isolated Tests', () => {
  let testData: TestDataManager;

  beforeEach(() => {
    testData = new TestDataManager();
  });

  afterEach(async () => {
    await testData.cleanup();
  });

  test('creates isolated data', async () => {
    const user = await testData.create('users', {
      email: testData.generateEmail()
      name: 'Test User'
    });

    expect(user.email).toContain('test_');
  });
});
```

## Strategy 5: Time-Based Cleanup

### Automatic Cleanup of Old Test Data

```typescript
export class TimeBasedCleaner {
  async cleanupOldTestData(
    olderThanHours: number = 24
  ): Promise<void> {
    const cutoffTime = new Date();
    cutoffTime.setHours(cutoffTime.getHours() - olderThanHours);

    // Clean users created for testing
    await supabase
      .from('users')
      .delete()
      .like('email', 'test-%@%')
      .lt('created_at', cutoffTime.toISOString());

    // Clean other test tables
    await supabase
      .from('test_documents')
      .delete()
      .lt('created_at', cutoffTime.toISOString());
  }
}

// Run in CI/CD or scheduled job
const cleaner = new TimeBasedCleaner();
await cleaner.cleanupOldTestData(24);
```

## Strategy 6: Seed Scripts

### Database Seeding for Tests

`scripts/seed-test-db.ts`:
```typescript
import { createClient } from '@supabase/supabase-js';

async function seedTestDatabase() {
  const supabase = createClient(
    process.env.SUPABASE_TEST_URL!
    process.env.SUPABASE_TEST_SERVICE_ROLE_KEY!
  );

  // Insert seed data
  await supabase.from('categories').insert([
    { name: 'Technology', slug: 'technology' }
    { name: 'Science', slug: 'science' }
    { name: 'Arts', slug: 'arts' }
  ]);

  await supabase.from('settings').insert([
    { key: 'site_name', value: 'Test Site' }
    { key: 'maintenance_mode', value: 'false' }
  ]);

  console.log('Test database seeded successfully');
}

seedTestDatabase().catch(console.error);
```

Run before tests:
```bash
tsx scripts/seed-test-db.ts
npm test
```

## Strategy 7: Snapshot Testing

### Database State Snapshots

```typescript
export class DatabaseSnapshot {
  async capture(table: string): Promise<any[]> {
    const { data } = await supabase.from(table).select('*');
    return data || [];
  }

  async restore(table: string, snapshot: any[]): Promise<void> {
    // Clear table
    await supabase.from(table).delete().neq('id', 0);

    // Restore snapshot
    await supabase.from(table).insert(snapshot);
  }
}

// Usage
describe('Snapshot Tests', () => {
  let snapshot: DatabaseSnapshot;
  let initialState: any[];

  beforeAll(async () => {
    snapshot = new DatabaseSnapshot();
    initialState = await snapshot.capture('users');
  });

  afterAll(async () => {
    await snapshot.restore('users', initialState);
  });

  test('modifies data', async () => {
    await supabase.from('users').insert({ email: 'new@test.com' });
    // State will be restored after test
  });
});
```

## Best Practices

### 1. Minimize Data Volume

Create only the data you need:

```typescript
// ❌ Bad: Creates unnecessary data
await factory.createMany(100);

// ✅ Good: Creates just what's needed
await factory.createMany(3);
```

### 2. Use Meaningful Test Data

```typescript
// ❌ Bad: Unclear test data
const user = await factory.create({ email: 'a@b.com' });

// ✅ Good: Descriptive test data
const user = await factory.create({
  email: 'admin-user-for-permission-test@example.com'
  role: 'admin'
});
```

### 3. Isolate Test Data

```typescript
// Each test should be independent
describe('User Tests', () => {
  beforeEach(async () => {
    // Setup fresh data for each test
  });

  afterEach(async () => {
    // Cleanup after each test
  });
});
```

### 4. Avoid Hardcoded IDs

```typescript
// ❌ Bad: Hardcoded ID might not exist
const user = await supabase.from('users').select().eq('id', 123);

// ✅ Good: Create and use dynamic ID
const created = await factory.create();
const user = await supabase.from('users').select().eq('id', created.id);
```

### 5. Handle Cleanup Failures Gracefully

```typescript
afterEach(async () => {
  try {
    await testData.cleanup();
  } catch (error) {
    console.warn('Cleanup failed:', error);
    // Don't fail the test due to cleanup errors
  }
});
```

## Performance Optimization

### Batch Operations

```typescript
// ❌ Slow: Individual inserts
for (let i = 0; i < 100; i++) {
  await supabase.from('users').insert({ email: `user${i}@test.com` });
}

// ✅ Fast: Batch insert
const users = Array.from({ length: 100 }, (_, i) => ({
  email: `user${i}@test.com`
}));
await supabase.from('users').insert(users);
```

### Lazy Loading

```typescript
class LazyFixtures {
  private loaded = new Set<string>();

  async load(fixture: string) {
    if (this.loaded.has(fixture)) {
      return; // Already loaded
    }

    // Load fixture
    await this.loadFixtureFile(fixture);
    this.loaded.add(fixture);
  }
}
```

## Troubleshooting

### Foreign Key Constraints

```typescript
// Load related data in correct order
await fixtureLoader.load('users');     // Parent first
await fixtureLoader.load('posts');     // Child second
await fixtureLoader.load('comments');  // Grandchild last
```

### Unique Constraint Violations

```typescript
// Use unique identifiers
const email = `test-${Date.now()}-${Math.random()}@example.com`;
```

### Cleanup Not Running

```typescript
// Use try-finally to ensure cleanup
describe('Tests', () => {
  afterEach(async () => {
    try {
      await cleanup();
    } finally {
      // Additional cleanup if needed
    }
  });
});
```

## Conclusion

Choose the right strategy for your needs:

- **Fixtures**: Static, read-only reference data
- **Factories**: Dynamic, customizable test data
- **Transactions**: Complete isolation (if supported)
- **Namespaces**: Easy cleanup with prefixes
- **Time-based**: Automated cleanup of old data
- **Seeds**: Baseline data for all tests
- **Snapshots**: State preservation and restoration

Most projects benefit from combining multiple strategies.
