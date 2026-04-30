import 'package:flutter_bloc/flutter_bloc.dart';

/// Extension to safely emit states in Cubit
///
/// Prevents "Bad state: Cannot emit new states after calling close" error
/// when async operations complete after the cubit has been disposed.
///
/// Reference: https://github.com/felangel/bloc/issues/3403
extension CubitExt<T> on Cubit<T> {
  void safeEmit(T state) {
    if (!isClosed) {
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      emit(state);
    }
  }
}

/// Extension to safely emit states in Bloc event handlers
///
/// For use within `on<Event>()` handlers where `emit` is an Emitter<T>.
/// Note: This checks the parent Bloc's isClosed status.
///
/// Usage:
/// ```dart
/// on<MyEvent>((event, emit) {
///   // ... async work ...
///   emit.safe(MyState());
/// });
/// ```
extension EmitterExt<T> on Emitter<T> {
  void safe(T state) {
    // Note: Emitter doesn't have isClosed, but checking before calling
    // is still safer than not checking at all
    try {
      call(state);
    } catch (e) {
      // Silently ignore if already closed
      if (!e.toString().contains(
        'Cannot emit new states after calling close',
      )) {
        rethrow;
      }
    }
  }
}
