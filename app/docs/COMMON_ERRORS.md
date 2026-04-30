# Common Errors and Solutions

This document catalogs common errors encountered in the ResiWash Flutter application and their solutions.

---

## Table of Contents

- [Bloc/Cubit Errors](#bloccubit-errors)
  - [Cannot emit new states after calling close](#cannot-emit-new-states-after-calling-close)

---

## Bloc/Cubit Errors

### Cannot emit new states after calling close

#### Error Message

```
StateError (Bad state: Cannot emit new states after calling close)
```

#### Root Cause

This error occurs when a Cubit or Bloc attempts to emit a new state after it has been closed/disposed. This is a **race condition** that happens when:

1. A widget/screen is disposed (e.g., user navigates away)
2. The associated Cubit/Bloc is closed
3. An async operation (API call, database query, timer) that was started earlier completes
4. The completion handler tries to emit a new state
5. Crash occurs because the Cubit/Bloc is already closed

#### Why This Happens

In Flutter, widgets can be disposed at any time (navigation, hot reload, etc.), but async operations continue running in the background until they complete. By the time the operation finishes, the Cubit may no longer exist.

#### Example

```dart
class MachineListCubit extends Cubit<MachineListState> {
  Future<void> load() async {
    emit(MachineListLoading());

    final result = await apiCall(); // Takes 2 seconds

    // If user navigates away during those 2 seconds:
    // - Widget is disposed
    // - Cubit is closed
    // - This emit() call throws StateError
    result.fold(
      (failure) => emit(MachineListError(failure.toString())),
      (machines) => emit(MachineListLoaded(machines)),
    );
  }
}
```

#### Solution 1: Use `safeEmit` Extension (Current Approach)

We provide a `safeEmit` extension method that checks if the Cubit is closed before emitting:

**File:** `lib/core/extensions/safecubit.dart`

```dart
extension CubitExt<T> on Cubit<T> {
  void safeEmit(T state) {
    if (!isClosed) {
      emit(state);
    }
  }
}
```

**Usage:**

```dart
import 'package:resiwash/core/extensions/safecubit.dart';

class MachineListCubit extends Cubit<MachineListState> {
  Future<void> load() async {
    safeEmit(MachineListLoading());

    final result = await apiCall();

    // Safe - will not throw if cubit is closed
    result.fold(
      (failure) => safeEmit(MachineListError(failure.toString())),
      (machines) => safeEmit(MachineListLoaded(machines)),
    );
  }
}
```

#### Solution 2: Manual `isClosed` Check

You can also manually check `isClosed` before each emit:

```dart
if (!isClosed) {
  emit(MyState());
}
```

This is more verbose but achieves the same result.

#### Solution 3: For Bloc Event Handlers (Using Emitter)

For Blocs that use event handlers with `on<Event>()`, use the `EmitterExt` extension:

```dart
import 'package:resiwash/core/extensions/safecubit.dart';

class MyBloc extends Bloc<MyEvent, MyState> {
  MyBloc() : super(MyInitial()) {
    on<LoadData>((event, emit) async {
      emit(MyLoading()); // Normal emit is fine here initially

      final result = await apiCall();

      // Use .safe() for async completions
      emit.safe(MyLoaded(result));
    });
  }
}
```

#### When to Use Each Solution

| Scenario                             | Solution                               | Notes                       |
| ------------------------------------ | -------------------------------------- | --------------------------- |
| **Cubit with async methods**         | `safeEmit()`                           | Most common case            |
| **Bloc with event handlers**         | `emit.safe()`                          | For `on<Event>()` callbacks |
| **One-off emit after dispose check** | Manual `if (!isClosed)`                | When you need custom logic  |
| **Complex cancellation logic**       | Override `close()` + cancel operations | Most robust but complex     |

#### Best Practices

1. **Always use `safeEmit`** in Cubits when emitting after async operations
2. **Import the extension** in all Cubit files:
   ```dart
   import 'package:resiwash/core/extensions/safecubit.dart';
   ```
3. **Replace regular `emit()` with `safeEmit()`** throughout the Cubit
4. **Don't suppress all errors** - `safeEmit` only prevents the "already closed" error, other errors should still throw

#### Why Not Built Into Bloc Library?

The bloc package maintainers intentionally don't include `safeEmit` in the core library because:

- It can hide legitimate bugs (e.g., operations that should have been cancelled)
- It's similar to Flutter's `mounted` check - a sign that state management might need improvement
- Projects have different opinions on how to handle this scenario
- Easy to implement as an extension method

**Reference:** [GitHub Issue #3403](https://github.com/felangel/bloc/issues/3403)

#### Future Improvement: Automatic Cancellation

A more robust approach would be to cancel async operations when the Cubit closes:

```dart
class MachineListCubit extends Cubit<MachineListState> {
  final _cancellables = <CancelToken>[];

  @override
  Future<void> close() {
    // Cancel all pending operations
    for (final token in _cancellables) {
      token.cancel();
    }
    return super.close();
  }

  Future<void> load() async {
    emit(MachineListLoading());

    final cancelToken = CancelToken();
    _cancellables.add(cancelToken);

    try {
      final result = await apiCall(cancelToken: cancelToken);

      result.fold(
        (failure) => emit(MachineListError(failure.toString())),
        (machines) => emit(MachineListLoaded(machines)),
      );
    } finally {
      _cancellables.remove(cancelToken);
    }
  }
}
```

This requires your API layer to support cancellation (e.g., Dio's `CancelToken`).

---

## Related Resources

- [Bloc Documentation](https://bloclibrary.dev/)
- [Flutter Bloc Best Practices](https://bloclibrary.dev/#/architecture)
- [GitHub Issue: safeEmit Discussion](https://github.com/felangel/bloc/issues/3403)
