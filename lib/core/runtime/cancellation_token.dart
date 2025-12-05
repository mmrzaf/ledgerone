/// Exception thrown when an operation is cancelled
class OperationCancelledException implements Exception {
  final String message;

  const OperationCancelledException([this.message = 'Operation was cancelled']);

  @override
  String toString() => 'OperationCancelledException: $message';
}

/// Token that can be used to cancel long-running operations
class CancellationToken {
  bool _isCancelled = false;
  final List<void Function()> _callbacks = [];

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;

    for (final callback in _callbacks) {
      try {
        callback();
      } catch (_) {
        // Ignore errors in callbacks
      }
    }
    _callbacks.clear();
  }

  void onCancel(void Function() callback) {
    if (_isCancelled) {
      callback();
    } else {
      _callbacks.add(callback);
    }
  }

  void throwIfCancelled() {
    if (_isCancelled) {
      throw const OperationCancelledException();
    }
  }

  factory CancellationToken() => CancellationToken._();

  CancellationToken._();

  static final none = _NoneCancellationToken();
}

/// Special token that is never cancelled
class _NoneCancellationToken extends CancellationToken {
  _NoneCancellationToken() : super._();

  @override
  bool get isCancelled => false;

  @override
  void cancel() {
    // Do nothing
  }

  @override
  void throwIfCancelled() {
    // Never throws
  }
}

/// Helper to create cancellation tokens tied to widget lifecycle
class CancellationTokenSource {
  final CancellationToken token = CancellationToken();

  void cancel() {
    token.cancel();
  }

  void dispose() {
    cancel();
  }
}
