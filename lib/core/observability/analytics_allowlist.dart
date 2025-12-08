// lib/core/observability/analytics_allowlist.dart

/// Event parameter definition
class EventParameter {
  final String name;
  final Type type;
  final String description;
  final bool required;

  const EventParameter({
    required this.name,
    required this.type,
    required this.description,
    this.required = false,
  });
}

/// Analytics event definition
class EventDefinition {
  final String name;
  final String description;
  final List<EventParameter> parameters;

  const EventDefinition({
    required this.name,
    required this.description,
    this.parameters = const [],
  });

  /// Validate that parameters match definition
  bool validateParameters(Map<String, dynamic>? params) {
    if (params == null) {
      return parameters.where((p) => p.required).isEmpty;
    }

    // Check required parameters
    for (final param in parameters.where((p) => p.required)) {
      if (!params.containsKey(param.name)) {
        return false;
      }
    }

    // Check parameter types
    for (final entry in params.entries) {
      final paramDef = parameters.where((p) => p.name == entry.key).firstOrNull;
      if (paramDef == null) {
        return false; // Unknown parameter
      }

      if (!_isValidType(entry.value, paramDef.type)) {
        return false;
      }
    }

    return true;
  }

  bool _isValidType(dynamic value, Type expectedType) {
    if (expectedType == String) return value is String;
    if (expectedType == int) return value is int;
    if (expectedType == double) return value is double || value is int;
    if (expectedType == bool) return value is bool;
    return false;
  }
}

/// Central registry of allowed analytics events
/// Events not in this list will be rejected
class AnalyticsAllowlist {
  // ------------------------------------------------------------
  // App lifecycle events
  // ------------------------------------------------------------

  static const appLaunch = EventDefinition(
    name: 'app_launch',
    description: 'App started',
    parameters: [
      EventParameter(
        name: 'cold_start',
        type: bool,
        description: 'Whether this was a cold start',
        required: true,
      ),
      EventParameter(
        name: 'duration_ms',
        type: int,
        description: 'Time to first frame in milliseconds',
      ),
    ],
  );

  static const appResumed = EventDefinition(
    name: 'app_resumed',
    description: 'App brought to foreground',
  );

  static const appPaused = EventDefinition(
    name: 'app_paused',
    description: 'App moved to background',
  );

  // ------------------------------------------------------------
  // Config events
  // ------------------------------------------------------------

  static const configLoaded = EventDefinition(
    name: 'config_loaded',
    description: 'Configuration loaded successfully',
    parameters: [
      EventParameter(
        name: 'source',
        type: String,
        description: 'Config source (cache/remote/default)',
        required: true,
      ),
      EventParameter(
        name: 'duration_ms',
        type: int,
        description: 'Load duration in milliseconds',
      ),
    ],
  );

  static const configFailed = EventDefinition(
    name: 'config_failed',
    description: 'Configuration load failed',
    parameters: [
      EventParameter(
        name: 'error_category',
        type: String,
        description: 'Error category',
        required: true,
      ),
      EventParameter(name: 'attempt', type: int, description: 'Attempt number'),
    ],
  );

  // ------------------------------------------------------------
  // Onboarding events
  // ------------------------------------------------------------

  static const onboardingView = EventDefinition(
    name: 'onboarding_view',
    description: 'Onboarding screen viewed',
  );

  static const onboardingComplete = EventDefinition(
    name: 'onboarding_complete',
    description: 'User completed onboarding',
  );

  static const onboardingSkip = EventDefinition(
    name: 'onboarding_skip',
    description: 'User skipped onboarding',
  );

  // ------------------------------------------------------------
  // Login/Auth events
  // ------------------------------------------------------------

  static const loginView = EventDefinition(
    name: 'login_view',
    description: 'Login screen viewed',
  );

  static const loginAttempt = EventDefinition(
    name: 'login_attempt',
    description: 'User attempted to log in',
  );

  static const loginSuccess = EventDefinition(
    name: 'login_success',
    description: 'User logged in successfully',
    parameters: [
      EventParameter(
        name: 'duration_ms',
        type: int,
        description: 'Login duration in milliseconds',
      ),
    ],
  );

  static const loginFailure = EventDefinition(
    name: 'login_failure',
    description: 'Login attempt failed',
    parameters: [
      EventParameter(
        name: 'error_category',
        type: String,
        description: 'Error category',
        required: true,
      ),
    ],
  );

  static const logoutSuccess = EventDefinition(
    name: 'logout_success',
    description: 'User logged out successfully',
  );

  // ------------------------------------------------------------
  // Home events
  // ------------------------------------------------------------

  static const homeView = EventDefinition(
    name: 'home_view',
    description: 'Home screen viewed',
    parameters: [
      EventParameter(
        name: 'duration_ms',
        type: int,
        description: 'Time from Home load start to ready state in ms',
        // Optional on purpose – event is still valid without it
        required: false,
      ),
    ],
  );

  static const homeRefresh = EventDefinition(
    name: 'home_refresh',
    description: 'User refreshed home content',
    parameters: [
      EventParameter(
        name: 'trigger',
        type: String,
        description: 'Refresh trigger (manual/automatic)',
        required: true,
      ),
    ],
  );

  static const homeError = EventDefinition(
    name: 'home_error',
    description: 'Error occurred on home screen',
    parameters: [
      EventParameter(
        name: 'error_category',
        type: String,
        description: 'Error category',
        required: true,
      ),
    ],
  );

  // ------------------------------------------------------------
  // Error events
  // ------------------------------------------------------------

  static const errorShown = EventDefinition(
    name: 'error_shown',
    description: 'Error displayed to user',
    parameters: [
      EventParameter(
        name: 'error_category',
        type: String,
        description: 'Error category',
        required: true,
      ),
      EventParameter(
        name: 'presentation',
        type: String,
        description: 'How error was shown (inline/banner/toast)',
        required: true,
      ),
      EventParameter(
        name: 'screen',
        type: String,
        description: 'Screen where error occurred',
      ),
    ],
  );

  static const errorRetry = EventDefinition(
    name: 'error_retry',
    description: 'User retried after error',
    parameters: [
      EventParameter(
        name: 'error_category',
        type: String,
        description: 'Error category',
        required: true,
      ),
    ],
  );

  // ------------------------------------------------------------
  // Ledger – transaction events
  // ------------------------------------------------------------

  static const transactionCreated = EventDefinition(
    name: 'transaction_created',
    description: 'A new transaction was created',
    parameters: [
      EventParameter(
        name: 'type',
        type: String,
        description:
            'Transaction type (income|expense|transfer|trade|adjustment)',
        required: true,
      ),
      // For income/expense/transfer
      EventParameter(
        name: 'asset_id',
        type: String,
        description: 'Primary asset identifier',
      ),
      EventParameter(
        name: 'amount',
        type: double,
        description: 'Primary amount for the transaction',
      ),
      // For trades
      EventParameter(
        name: 'from_asset',
        type: String,
        description: 'Sold asset for a trade',
      ),
      EventParameter(
        name: 'to_asset',
        type: String,
        description: 'Bought asset for a trade',
      ),
    ],
  );

  static const transactionSaved = EventDefinition(
    name: 'transaction_saved',
    description: 'Transaction persisted successfully',
    parameters: [
      EventParameter(
        name: 'type',
        type: String,
        description: 'Transaction type',
        required: true,
      ),
      EventParameter(
        name: 'duration_ms',
        type: int,
        description: 'Latency from user submit to DB commit',
      ),
    ],
  );

  static const transactionFailed = EventDefinition(
    name: 'transaction_failed',
    description: 'Transaction creation or update failed',
    parameters: [
      EventParameter(
        name: 'type',
        type: String,
        description: 'Transaction type',
      ),
      EventParameter(
        name: 'error',
        type: String,
        description: 'Error description',
      ),
    ],
  );

  static const transactionDeleted = EventDefinition(
    name: 'transaction_deleted',
    description: 'Transaction deleted',
    parameters: [
      EventParameter(
        name: 'transaction_id',
        type: String,
        description: 'ID of deleted transaction',
        required: true,
      ),
    ],
  );

  // ------------------------------------------------------------
  // Ledger – price update events
  // ------------------------------------------------------------

  static const priceUpdateStarted = EventDefinition(
    name: 'price_update_started',
    description: 'Bulk price update started',
  );

  static const priceUpdateFinished = EventDefinition(
    name: 'price_update_finished',
    description: 'Bulk price update completed',
    parameters: [
      EventParameter(
        name: 'success_count',
        type: int,
        description: 'Number of assets updated successfully',
        required: true,
      ),
      EventParameter(
        name: 'failure_count',
        type: int,
        description: 'Number of assets that failed to update',
        required: true,
      ),
      EventParameter(
        name: 'duration_ms',
        type: int,
        description: 'Total duration of the bulk update',
      ),
    ],
  );

  static const priceUpdateFailed = EventDefinition(
    name: 'price_update_failed',
    description: 'Single-asset price update failed',
    parameters: [
      EventParameter(name: 'error', type: String, description: 'Error message'),
    ],
  );

  static const priceUpdateSuccess = EventDefinition(
    name: 'price_update_success',
    description: 'Single-asset price update succeeded',
    parameters: [
      EventParameter(
        name: 'asset_id',
        type: String,
        description: 'Asset identifier',
        required: true,
      ),
      EventParameter(
        name: 'price',
        type: double,
        description: 'Updated price in quote currency',
        required: true,
      ),
    ],
  );

  // ------------------------------------------------------------
  // All allowed events (frozen list)
  // ------------------------------------------------------------

  static const List<EventDefinition> allowedEvents = [
    // Core app
    appLaunch,
    appResumed,
    appPaused,
    configLoaded,
    configFailed,
    onboardingView,
    onboardingComplete,
    onboardingSkip,
    loginView,
    loginAttempt,
    loginSuccess,
    loginFailure,
    logoutSuccess,
    homeView,
    homeRefresh,
    homeError,
    errorShown,
    errorRetry,

    // Ledger
    transactionCreated,
    transactionSaved,
    transactionFailed,
    transactionDeleted,
    priceUpdateStarted,
    priceUpdateFinished,
    priceUpdateFailed,
    priceUpdateSuccess,
  ];

  /// Get event definition by name
  static EventDefinition? getEvent(String name) {
    try {
      return allowedEvents.firstWhere((e) => e.name == name);
    } catch (_) {
      return null;
    }
  }

  /// Check if event is allowed
  static bool isAllowed(String name) {
    return getEvent(name) != null;
  }

  /// Validate event and parameters
  static bool validate(String name, Map<String, dynamic>? parameters) {
    final event = getEvent(name);
    if (event == null) return false;
    return event.validateParameters(parameters);
  }

  /// Get all event names (for testing/validation)
  static List<String> get allEventNames {
    return allowedEvents.map((e) => e.name).toList();
  }
}
