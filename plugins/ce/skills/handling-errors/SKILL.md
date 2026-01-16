---
name: handling-errors
description: Prevents silent failures and context loss in error handling. Use when writing try-catch blocks, designing error propagation, reviewing catch blocks, or implementing Result patterns.
---

# Handling Errors

## Iron Laws

1. **Never swallow errors** - Empty catch blocks hide bugs
2. **Never convert errors to booleans** - Loses all context
3. **Preserve error context** when wrapping or propagating
4. **Log once where handled**, not at every layer

## Error Messages

Every error message answers: **What happened? Why? How to recover?**

**For logs (developers):**

```typescript
logger.error("Failed to save user: Connection timeout after 30s", {
  userId: user.id,
  dbHost: config.db.host,
  error: error.stack,
});
```

**For users:**

```typescript
showError({
  title: "Upload Failed",
  message: "Your file is too large. Maximum size is 10MB.",
  actions: [{ label: "Choose smaller file", onClick: selectFile }],
});
```

## Error Categories

| Type         | Examples                           | Handling                    |
| ------------ | ---------------------------------- | --------------------------- |
| **Expected** | Validation, Not found, Unauthorized| Return Result type, log info|
| **Transient**| Network timeout, Rate limit        | Retry with backoff, log warn|
| **Unexpected**| Null reference, DB crash          | Log error, show support ID  |
| **Critical** | Auth down, Payment gateway offline | Circuit breaker, alert      |

## Always Fail Fast

**Never use fallbacks or silent degradation. Errors must surface immediately.**

```typescript
// ✅ Fail fast - error surfaces immediately
await connectToDatabase(); // Throws on failure

// ❌ NEVER: Silent fallback hides the problem
const prefs = await loadPreferences(userId).catch(() => DEFAULT_PREFS);
```

**Why fail fast:**
- Fallbacks hide bugs until production
- Silent failures corrupt data or state
- Easier to debug failures caught early
- Users prefer clear errors over mysterious broken behavior

## Log at the Right Layer

```typescript
// ❌ Logging at every layer = same error 3x
async function fetchData() {
  try { return await fetch(url); }
  catch (e) { console.error("Fetch failed:", e); throw e; }
}

// ✅ Log once where handled
async function fetchData() {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return response;
}
// Top level logs the error once
```

## Language-Specific Patterns

- **Flutter/Dart**: See [reference/flutter-dart.md](reference/flutter-dart.md)
- **TypeScript/React**: See [reference/typescript-react.md](reference/typescript-react.md)

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Empty catch blocks | Hides errors | Log or re-throw |
| `return false` on error | Loses context | Return Result type |
| Generic "Error" messages | Undebuggable | Include what/why/context |
| Logging same error at each layer | Log pollution | Log once at boundary |
| Bare `except:` / `catch (e)` all | Catches system signals | Catch specific types |
