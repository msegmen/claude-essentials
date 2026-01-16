# Flutter/Dart Error Handling

Dart and Flutter-specific patterns for handling errors effectively.

## Contents
- [Future and Stream Errors](#future-and-stream-errors)
- [FlutterError for Widget Errors](#fluttererror-for-widget-errors)
- [Fail Fast in Flutter](#fail-fast-in-flutter)
- [Firebase Exception Handling](#firebase-exception-handling)
- [Result Pattern (Dart 3 Sealed Classes)](#result-pattern-dart-3-sealed-classes)
- [Error Logging with Crashlytics](#error-logging-with-crashlytics)

## Future and Stream Errors

```dart
// Prefer async/await with try-catch
Future<User> fetchUser(String id) async {
  try {
    final response = await api.getUser(id);
    return User.fromJson(response);
  } on SocketException {
    throw NetworkException('No internet connection');
  } on FormatException catch (e) {
    throw ParseException('Invalid user data: ${e.message}');
  }
}

// Stream error handling
stream.handleError((error, stackTrace) {
  logger.error('Stream error', error, stackTrace);
}).listen(onData);
```

## FlutterError for Widget Errors

```dart
void main() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // Log to Crashlytics in release
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  runApp(const MyApp());
}
```

## Fail Fast in Flutter

**Let errors crash visibly. Never hide them with fallback widgets.**

```dart
void main() {
  // ✅ In debug: Show full error for debugging
  // ✅ In release: Crash and log to Crashlytics (don't hide)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  // ❌ NEVER: Custom ErrorWidget that hides problems
  // ErrorWidget.builder = (details) => Text('Something went wrong');

  runApp(const MyApp());
}
```

## Firebase Exception Handling

```dart
Future<void> signIn(String email, String password) async {
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case 'user-not-found':
        throw AuthException('No user found for this email');
      case 'wrong-password':
        throw AuthException('Invalid password');
      case 'too-many-requests':
        throw AuthException('Too many attempts. Try again later');
      default:
        throw AuthException('Authentication failed: ${e.message}');
    }
  }
}
```

## Result Pattern (Dart 3 Sealed Classes)

```dart
// Native Dart 3 Result type - no external packages needed
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final AppException error;
  const Failure(this.error);
}

// Usage
Future<Result<User>> fetchUser(String id) async {
  try {
    final user = await api.getUser(id);
    return Success(user);
  } catch (e) {
    return Failure(AppException.fromError(e));
  }
}

// Consuming with exhaustive switch
final result = await fetchUser('123');
switch (result) {
  case Success(:final data):
    showProfile(data);
  case Failure(:final error):
    showError(error.message);
}
```

## Error Logging with Crashlytics

```dart
// Non-fatal errors
FirebaseCrashlytics.instance.recordError(
  error,
  stackTrace,
  reason: 'API call failed',
  fatal: false,
);

// Add context
FirebaseCrashlytics.instance.setCustomKey('user_id', userId);
FirebaseCrashlytics.instance.log('Attempting checkout with $itemCount items');
```
