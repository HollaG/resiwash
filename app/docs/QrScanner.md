# QR Scanner Implementation & Navigation State Management

## Overview

This document details the implementation of the QR scanner screen and the challenges encountered with state management in `StatefulShellRoute` navigation.

## Problem Statement

The QR scanner needed to:

1. Scan QR codes containing machine information
2. Navigate to machine detail screens
3. Restart the camera when returning to the scanner page
4. Handle back navigation properly (back from detail should go to home, not scanner)

## Initial Issues

### Issue 1: Context.read() in Async Callbacks

**Error:** `FlutterError (Looking up a deactivated widget's ancestor is unsafe.)`

**Cause:** Using `context.read<ClaimCubit>()` in async callbacks where the widget might be disposed.

**Solution:** Cache cubit references in `initState()`:

```dart
late final ClaimCubit _claimCubit;

@override
void initState() {
  super.initState();
  _claimCubit = context.read<ClaimCubit>();
}

// Later use:
await _claimCubit.unclaimMachine(widget.machine);
```

### Issue 2: Scanner Not Restarting After Navigation

**Problem:** When navigating back to the scan QR page via the bottom navigation FAB, the camera remained paused.

**Root Cause:** `StatefulShellRoute.indexedStack` keeps all branch widgets alive in memory. Traditional lifecycle methods like `didPushNext()` and `didPopNext()` from `RouteAware` don't fire when switching between branches.

**Attempts:**

#### Attempt 1: RouteAware Mixin

```dart
class _MobileScannerSimpleState extends State<MobileScannerSimple>
    with RouteAware {

  @override
  void didPushNext() {
    controller.stop();
  }

  @override
  void didPopNext() {
    controller.start(); // Never fires!
  }
}
```

**Result:** ❌ Callbacks never fired because branch switching isn't push/pop navigation.

#### Attempt 2: AutomaticKeepAliveClientMixin

```dart
class _MobileScannerSimpleState extends State<MobileScannerSimple>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => false;
}
```

**Result:** ❌ Doesn't work with `StatefulShellRoute.indexedStack` - branches are always kept alive.

#### Attempt 3: didChangeDependencies()

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (TickerMode.of(context)) {
    controller.start();
  }
}
```

**Result:** ❌ Doesn't fire when switching branches in `StatefulShellRoute`.

#### Final Solution: TickerMode in Build

```dart
bool _wasVisible = false;

@override
Widget build(BuildContext context) {
  final isVisible = TickerMode.of(context);

  // Detect visibility changes
  if (isVisible && !_wasVisible) {
    // Became visible - restart scanner
    print("debug qr became visible, restarting scanner");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !controller.value.isRunning &&
          controller.value.hasCameraPermission) {
        unawaited(controller.start());
      }
    });
  } else if (!isVisible && _wasVisible) {
    // Became invisible - stop scanner
    print("debug qr became invisible, stopping scanner");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && controller.value.isRunning) {
        unawaited(controller.stop());
      }
    });
  }

  _wasVisible = isVisible;

  return BlocProvider(...);
}
```

**Result:** ✅ Works! `TickerMode.of(context)` changes when branch visibility changes, triggering scanner start/stop.

**Key Points:**

- Detects both visibility transitions: `false → true` (restart) and `true → false` (stop)
- Uses `addPostFrameCallback` to defer camera operations until after build completes
- Prevents camera from running in background when user navigates away
- Automatically restarts when user returns to scanner page

## Navigation Flow & Back Button Behavior

### Issue 3: Back Button Navigation Path

**Problem:** After scanning a QR code and navigating to machine detail, pressing back should go to home, not back to the scanner.

**Initial Route Structure:**

```dart
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/',
      routes: [
        GoRoute(
          path: 'machines',
          routes: [
            GoRoute(path: ':machineId'), // Nested under machines
          ],
        ),
      ],
    ),
  ],
),
```

**Result:** Back from detail → machine list → home (extra step)

**Solution:** Flatten machine detail as a sibling of machine list:

```dart
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/',
      routes: [
        GoRoute(path: 'machines'),          // Sibling
        GoRoute(path: 'machines/:machineId'), // Sibling
      ],
    ),
  ],
),
```

**Navigation Path:**

```dart
// From scan QR:
final uri = Uri(
  path: '/machines/$machineId',
  queryParameters: {
    'roomIds[]': [roomId],
    'types[]': ['washer', 'dryer'],
  },
);
context.go(uri.toString(), extra: {...});
```

**Result:** Back from detail → home (direct)

## Key Learnings

### StatefulShellRoute Behavior

1. **Always keeps widgets alive** - `AutomaticKeepAliveClientMixin` has no effect
2. **Branch switching ≠ push/pop** - `RouteAware` callbacks don't fire
3. **Use `TickerMode.of(context)`** to detect branch visibility changes
4. **Monitor in `build()`** - it's called when branch visibility changes

### Navigation Patterns

1. **`context.push()`** - Adds to stack, can await result
2. **`context.go()`** - Replaces entire location, resets stack
3. **`context.replace()`** - Don't use! Removes current route from stack
4. **Nested routes** control back button behavior

### Best Practices

1. **Cache cubit references** in `initState()` for async operations
2. **Use `TickerMode.of(context)`** to detect visibility in `StatefulShellRoute`
3. **Use `addPostFrameCallback()`** to defer state changes after build
4. **Flatten routes** when you want direct back navigation

## Alternative Approaches Considered

### Article Solution: ExtendedShellBranch

A Medium article proposed a custom `ExtendedShellBranch` class with a `saveState` parameter to control per-branch state persistence.

**Pros:**

- Centralized control in router config
- Can mix persistent and non-persistent branches

**Cons:**

- Complex implementation (custom classes, mixins, containers)
- Overkill for single-screen use case

**Decision:** Stick with `TickerMode` approach - simpler and more maintainable for our needs.

## Code References

### Key Files

- [scan_qr_screen.dart](../lib/features/my-machines/presentation/screens/scan_qr_screen.dart) - Scanner implementation
- [router.dart](../lib/router.dart) - Route configuration
- [machine_row.dart](../lib/features/machine/presentation/widgets/machine_row.dart) - Cached cubit example
- [base-view.dart](../lib/views/base-view.dart) - Bottom navigation with scan FAB

### Related Issues

- Flutter issue: StatefulShellRoute doesn't provide lifecycle callbacks for branch switches
- Medium article: [How to disable saving state in StatefulShellRoute](https://medium.com/@valerii.novykov/how-to-disable-saving-state-of-certain-branches-in-statefulshellroute-gorouter-42c8d6cc4a34)

## Testing Checklist

- [ ] Scanner starts on first visit
- [ ] Scanner restarts when returning via FAB
- [ ] Scanner pauses when navigating away
- [ ] Scanner restarts after app backgrounding
- [ ] Back from machine detail goes to home
- [ ] QR codes navigate correctly
- [ ] Invalid QR codes show error message
- [ ] Camera permissions handled properly
- [ ] No crashes when widget is disposed during async operations

## Future Improvements

1. Consider implementing proper deep linking for QR codes
2. Add scanner animation/feedback when QR detected
3. Improve error handling for camera permission denials
4. Add analytics tracking for scan events
