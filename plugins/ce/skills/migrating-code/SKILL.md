---
name: migrating-code
description: Guides safe code migrations including database schema changes, API versioning, framework upgrades, and language/library transitions. Use when upgrading dependencies, changing data models, or transitioning between technologies.
---

# Migrating Code

Apply these patterns when performing code migrations to ensure safety, reversibility, and minimal disruption.

## Migration Principles

1. **Never break production** - Migrations must be backward compatible until fully rolled out
2. **Small, reversible steps** - Each migration step should be independently deployable and reversible
3. **Test at every stage** - Verify behavior before, during, and after migration
4. **Communicate changes** - Document breaking changes and migration paths for consumers

Copy this checklist and track your progress:

```
Migration Progress:
- [ ] Pre-Migration
  - [ ] Read changelog and migration guide
  - [ ] Identify breaking changes
  - [ ] Check dependency compatibility
  - [ ] Ensure test coverage
  - [ ] Plan rollback strategy
- [ ] During Migration
  - [ ] Implement in small, reversible steps
  - [ ] Test at each step
  - [ ] Monitor error rates
  - [ ] Have rollback ready
- [ ] Post-Migration
  - [ ] Verify all tests pass
  - [ ] Check metrics match expectations
  - [ ] Remove migration scaffolding
  - [ ] Update documentation
```

## Database Schema Migrations

### Safe Migration Patterns

**Adding columns:**
- Add as nullable first, then backfill, then add constraints
- Never add NOT NULL columns without defaults to tables with data

**Removing columns:**
1. Stop writing to the column
2. Deploy code that doesn't read from the column
3. Remove the column in a separate deployment

**Renaming columns:**
1. Add new column
2. Dual-write to both columns
3. Backfill old data to new column
4. Switch reads to new column
5. Stop writing to old column
6. Drop old column

**Changing column types:**
- Create new column with new type
- Dual-write during transition
- Migrate data in batches (not one big transaction)
- Switch reads, then drop old column

### Migration File Structure

```
migrations/
├── 001_create_users_table.sql
├── 002_add_email_to_users.sql
├── 003_create_orders_table.sql
└── rollback/
    ├── 001_drop_users_table.sql
    └── ...
```

Always include rollback scripts. Test rollbacks before deploying.

## API Migrations

### Versioning Strategy

**URL versioning** (recommended for public APIs):
```
/api/v1/users
/api/v2/users
```

**Header versioning** (cleaner URLs):
```
Accept: application/vnd.api+json; version=2
```

### Deprecation Process

1. Add deprecation warnings to old endpoints
2. Document migration path in responses
3. Set and communicate sunset date
4. Monitor usage of deprecated endpoints
5. Remove only after usage drops to acceptable level

```json
{
  "data": { ... },
  "_warnings": [{
    "code": "DEPRECATED_ENDPOINT",
    "message": "This endpoint is deprecated. Use /api/v2/users instead.",
    "sunset": "2025-06-01"
  }]
}
```

## Framework/Library Upgrades

### Pre-Migration Checklist

- [ ] Read the changelog and migration guide
- [ ] Identify breaking changes that affect your code
- [ ] Check dependency compatibility
- [ ] Ensure test coverage for affected areas
- [ ] Plan rollback strategy

### Incremental Upgrade Strategy

For major version jumps (e.g., React 16 to 18):

1. **Upgrade to latest minor first** - Get all deprecation warnings
2. **Fix deprecation warnings** - Before attempting major upgrade
3. **Upgrade major version** - One major version at a time
4. **Run tests after each step** - Don't batch upgrades

### Adapter Pattern for Library Swaps

When replacing a library, wrap it first:

```typescript
// Before: direct usage scattered everywhere
import moment from 'moment';
const formatted = moment(date).format('YYYY-MM-DD');

// After: wrapped in adapter
// lib/date.ts
import moment from 'moment';
export const formatDate = (date: Date, format: string) =>
  moment(date).format(format);

// Usage
import { formatDate } from '@/lib/date';
const formatted = formatDate(date, 'YYYY-MM-DD');

// Migration: just change the adapter
import { format } from 'date-fns';
export const formatDate = (date: Date, fmt: string) =>
  format(date, fmt);
```

## Language/Runtime Migrations

### Strangler Fig Pattern

Gradually replace old system with new:

1. Create facade in front of legacy system
2. Route new features through new system
3. Incrementally migrate existing features
4. Remove legacy system when empty

### Feature Flags for Migration

```typescript
if (featureFlags.useNewPaymentSystem) {
  return newPaymentService.process(order);
} else {
  return legacyPaymentService.process(order);
}
```

Roll out gradually:
- 1% of traffic
- 10% of traffic
- 50% of traffic
- 100% of traffic
- Remove flag and old code

## Migration Verification

### Before Migration

- Snapshot current behavior with integration tests
- Document expected changes
- Capture metrics baseline

### During Migration

- Monitor error rates
- Compare old vs new behavior in parallel when possible
- Have rollback ready

### After Migration

- Verify all tests pass
- Check metrics match expectations
- Remove migration scaffolding (feature flags, dual-writes)
- Update documentation

## Common Pitfalls

**Avoid:**
- Big bang migrations (all at once)
- Migrations without rollback plans
- Skipping the dual-write phase
- Migrating data in single large transactions
- Removing old code before new code is proven

**Do:**
- Migrate in small, reversible steps
- Test rollback procedures
- Use feature flags for gradual rollout
- Batch large data migrations
- Keep old code paths until new ones are verified
