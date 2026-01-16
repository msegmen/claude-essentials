# Flutter/Dart Testing Patterns

Language-specific patterns for testing Flutter applications with flutter_test, mockito, and integration_test.

## Contents
- [Widget Test Pattern](#widget-test-pattern)
- [Integration Test Pattern](#integration-test-pattern)
- [Golden Tests](#golden-tests)
- [Query Strategy (Finders)](#query-strategy-finders)
- [Mocking with Mockito](#mocking-with-mockito)
- [Firebase Test Setup](#firebase-test-setup)
- [Async Waiting Patterns](#async-waiting-patterns)
- [Tooling Quick Reference](#tooling-quick-reference)

## Widget Test Pattern

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/counter.dart';

void main() {
  group('Counter', () {
    testWidgets('increments when button tapped', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Counter()));

      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });
  });
}
```

## Integration Test Pattern

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full app flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Test complete user workflow
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
  });
}
```

## Golden Tests

```dart
testWidgets('matches golden file', (tester) async {
  await tester.pumpWidget(const MyWidget());
  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('goldens/my_widget.png'),
  );
});
```

**Note:** Run `flutter test --update-goldens` to regenerate.

## Query Strategy (Finders)

| Priority | Finder | Use Case |
|----------|--------|----------|
| 1st | `find.byKey(Key('submit'))` | Explicit test keys |
| 2nd | `find.byType(ElevatedButton)` | Widget type |
| 3rd | `find.text('Submit')` | Visible text |
| 4th | `find.byIcon(Icons.add)` | Icon buttons |
| Avoid | `find.byElementType` | Implementation detail |

## Mocking with Mockito

```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([AuthService, FirestoreService])
void main() {
  late MockAuthService mockAuth;

  setUp(() {
    mockAuth = MockAuthService();
  });

  test('login success', () async {
    when(mockAuth.signIn(any, any))
        .thenAnswer((_) async => User(id: '123'));

    final result = await mockAuth.signIn('email', 'pass');

    expect(result.id, '123');
    verify(mockAuth.signIn('email', 'pass')).called(1);
  });
}
```

Run `dart run build_runner build` to generate mocks.

## Firebase Test Setup

```dart
// test/firebase_test_setup.dart
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
}

// For Firestore, use fake_cloud_firestore
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

test('firestore operations', () async {
  final firestore = FakeFirebaseFirestore();
  await firestore.collection('users').add({'name': 'Test'});

  final snapshot = await firestore.collection('users').get();
  expect(snapshot.docs.length, 1);
});
```

## Async Waiting Patterns

| Method | When to Use |
|--------|-------------|
| `pump()` | Single frame advance |
| `pump(Duration)` | Advance specific time |
| `pumpAndSettle()` | Wait for all animations |
| `tester.runAsync()` | Real async operations |

```dart
// For real async (HTTP, timers)
await tester.runAsync(() async {
  await Future.delayed(Duration(seconds: 1));
});
await tester.pumpAndSettle();
```

## Tooling Quick Reference

| Tool | Purpose | Command |
|------|---------|---------|
| flutter_test | Widget/unit tests | `flutter test` |
| integration_test | E2E tests | `flutter test integration_test/` |
| mockito | Mocking | `dart run build_runner build` |
| bloc_test | BLoC testing | `flutter test` |
| golden_toolkit | Visual regression | `flutter test --update-goldens` |
