# Flutter/Dart Refactoring Patterns

Language-specific patterns for refactoring Flutter and Dart code.

## Widget Structure

### Extract Widget Pattern

```dart
// Before: Large build method
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 50 lines of header code
        // 50 lines of body code
        // 50 lines of footer code
      ],
    );
  }
}

// After: Extracted widgets
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ProfileHeader(),
        _ProfileBody(),
        _ProfileFooter(),
      ],
    );
  }
}
```

### Composition Over Inheritance

```dart
// Avoid: Custom base widget
class BaseButton extends StatelessWidget { ... }
class PrimaryButton extends BaseButton { ... }

// Prefer: Composition with factory constructors
class AppButton extends StatelessWidget {
  final ButtonStyle style;
  final Widget child;
  final VoidCallback? onPressed;

  const AppButton({required this.child, this.onPressed, this.style = const ButtonStyle()});

  const AppButton.primary({required Widget child, VoidCallback? onPressed})
      : this(child: child, onPressed: onPressed, style: _primaryStyle);
}
```

## Dart Type Safety

### Sealed Classes (Dart 3+)

```dart
sealed class AuthState {}

class Authenticated extends AuthState {
  final User user;
  Authenticated(this.user);
}

class Unauthenticated extends AuthState {}

class AuthLoading extends AuthState {}

// Exhaustive switch
String getMessage(AuthState state) => switch (state) {
  Authenticated(user: var u) => 'Welcome, ${u.name}',
  Unauthenticated() => 'Please sign in',
  AuthLoading() => 'Loading...',
};
```

### Extension Methods

```dart
extension StringExtensions on String {
  String get capitalize => '${this[0].toUpperCase()}${substring(1)}';
  bool get isValidEmail => RegExp(r'^[\w-\.]+@[\w-]+\.[a-z]{2,}$').hasMatch(this);
}

extension DateTimeExtensions on DateTime {
  String get formatted => '${day}/${month}/${year}';
  bool get isToday => DateUtils.isSameDay(this, DateTime.now());
}
```

## State Management Refactoring

### Lift State Up

```dart
// Before: State scattered across widgets
class ParentWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ChildA(), // Has its own counter state
        ChildB(), // Needs counter value
      ],
    );
  }
}

// After: State lifted to common ancestor
class ParentWidget extends StatefulWidget {
  @override
  State<ParentWidget> createState() => _ParentWidgetState();
}

class _ParentWidgetState extends State<ParentWidget> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ChildA(counter: _counter, onIncrement: () => setState(() => _counter++)),
        ChildB(counter: _counter),
      ],
    );
  }
}
```

## Flutter Refactoring Checklist

- [ ] Replace StatefulWidget with StatelessWidget where possible
- [ ] Add `const` constructors to immutable widgets
- [ ] Extract widgets >100 lines into separate classes
- [ ] Use named parameters for >2 parameters
- [ ] Prefer composition over inheritance
- [ ] Use sealed classes for finite state sets
- [ ] Extract repeated logic into extension methods
- [ ] Use `late final` for lazy initialization
- [ ] Remove unnecessary `this.` prefixes
