# Node.js/Firebase Testing Patterns

Patterns for testing Firebase Functions, Firestore rules, and Node.js backend services.

## Firebase Functions Testing

```typescript
import * as functions from 'firebase-functions-test';
import * as admin from 'firebase-admin';

const test = functions({ projectId: 'test-project' });

describe('createUser function', () => {
  afterAll(() => test.cleanup());

  it('creates user document on auth create', async () => {
    const wrapped = test.wrap(myFunctions.createUser);

    const user = test.auth.makeUserRecord({ uid: 'test-uid', email: 'test@example.com' });
    await wrapped(user);

    const doc = await admin.firestore().doc('users/test-uid').get();
    expect(doc.exists).toBe(true);
    expect(doc.data()?.email).toBe('test@example.com');
  });
});
```

## Firestore Emulator Integration

```typescript
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'test-project',
    firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') },
  });
});

afterEach(async () => await testEnv.clearFirestore());
afterAll(async () => await testEnv.cleanup());

test('users can read their own data', async () => {
  const alice = testEnv.authenticatedContext('alice');
  await assertSucceeds(alice.firestore().doc('users/alice').get());
});

test('users cannot read other user data', async () => {
  const alice = testEnv.authenticatedContext('alice');
  await assertFails(alice.firestore().doc('users/bob').get());
});
```

## API Testing with Supertest

```typescript
import request from 'supertest';
import { app } from '../src/app';

describe('POST /api/items', () => {
  it('creates item with valid data', async () => {
    const response = await request(app)
      .post('/api/items')
      .send({ name: 'Test Item', price: 100 })
      .set('Authorization', 'Bearer valid-token');

    expect(response.status).toBe(201);
    expect(response.body.name).toBe('Test Item');
  });
});
```

## Tooling Quick Reference

| Tool | Purpose | Command |
|------|---------|---------|
| firebase-functions-test | Function unit tests | `npm test` |
| @firebase/rules-unit-testing | Security rules tests | `npm test` |
| firebase emulators | Local emulation | `firebase emulators:start` |
| supertest | HTTP testing | `npm test` |
