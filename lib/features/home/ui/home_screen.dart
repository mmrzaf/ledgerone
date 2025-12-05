import 'package:flutter/material.dart';

import '../../../app/presentation/error_presenter.dart';
import '../../../app/presentation/offline_banner.dart';
import '../../../core/contracts/auth_contract.dart';
import '../../../core/contracts/cache_contract.dart';
import '../../../core/contracts/config_contract.dart';
import '../../../core/contracts/lifecycle_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/contracts/network_contract.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/runtime/cancellation_token.dart';
import '../../../core/runtime/retry_helper.dart';

enum HomeContentState { loading, ready, empty, error }

class HomeData {
  final String message;
  final DateTime timestamp;

  HomeData({required this.message, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'message': message,
    'timestamp': timestamp.toIso8601String(),
  };

  factory HomeData.fromJson(Map<String, dynamic> json) => HomeData(
    message: json['message'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final NavigationService navigation;
  final ConfigService configService;
  final NetworkService networkService;
  final CacheService cacheService;
  final AppLifecycleService lifecycleService;

  const HomeScreen({
    required this.authService,
    required this.navigation,
    required this.configService,
    required this.networkService,
    required this.cacheService,
    required this.lifecycleService,
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cancellationSource = CancellationTokenSource();

  HomeContentState _state = HomeContentState.loading;
  HomeData? _data;
  AppError? _error;
  NetworkStatus _networkStatus = NetworkStatus.unknown;
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;

  // Backpressure: don't refresh more than once per minute
  static const Duration _minRefreshInterval = Duration(minutes: 1);
  static const String _cacheKey = 'home_data';

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    // Monitor network status
    _networkStatus = await widget.networkService.status;
    widget.networkService.statusStream.listen((status) {
      if (mounted) {
        setState(() => _networkStatus = status);
      }
    });

    // Register lifecycle callbacks
    widget.lifecycleService.onResume(_handleAppResume);

    // Initial load
    await _loadContent();
  }

  @override
  void dispose() {
    _cancellationSource.dispose();
    super.dispose();
  }

  /// Handle app returning from background
  void _handleAppResume() {
    debugPrint('Home: App resumed from background');

    // Check if we should refresh
    if (_shouldRefreshOnResume()) {
      debugPrint('Home: Triggering background refresh');
      _loadContent(isBackgroundRefresh: true);
    } else {
      debugPrint('Home: Skipping refresh (too soon since last refresh)');
    }
  }

  /// Determine if we should refresh on app resume
  bool _shouldRefreshOnResume() {
    // Don't refresh if offline
    if (_networkStatus.isOffline) {
      return false;
    }

    // Don't refresh if already refreshing
    if (_isRefreshing) {
      return false;
    }

    // Don't refresh if we refreshed recently
    if (_lastRefreshTime != null) {
      final timeSinceRefresh = DateTime.now().difference(_lastRefreshTime!);
      if (timeSinceRefresh < _minRefreshInterval) {
        return false;
      }
    }

    return true;
  }

  Future<void> _loadContent({bool isBackgroundRefresh = false}) async {
    // Don't show loading spinner for background refreshes
    if (!isBackgroundRefresh) {
      setState(() {
        _state = HomeContentState.loading;
        _error = null;
      });
    } else {
      setState(() => _isRefreshing = true);
    }

    // Try to load from cache first (last-known-good)
    final cached = await widget.cacheService.get<Map<String, dynamic>>(
      _cacheKey,
    );
    if (cached != null) {
      try {
        final cachedData = HomeData.fromJson(cached.data);
        debugPrint('Home: Loaded from cache (age: ${cached.age.inMinutes}m)');

        if (mounted) {
          setState(() {
            _data = cachedData;
            _state = HomeContentState.ready;
          });
        }
      } catch (e) {
        debugPrint('Home: Failed to parse cached data: $e');
      }
    }

    // Fetch fresh data (with retry)
    final result = await RetryHelper.executeWithPolicy<HomeData>(
      operation: () => _fetchDemoData(),
      category: ErrorCategory.timeout,
      cancellationToken: _cancellationSource.token,
      onRetry: (attempt, error) {
        debugPrint('Home: Retry attempt $attempt after ${error.category}');
      },
    );

    if (!mounted) return;

    if (result.wasCancelled) {
      debugPrint('Home: Load cancelled');
      setState(() => _isRefreshing = false);
      return;
    }

    if (result.isSuccess) {
      final freshData = result.data!;
      _lastRefreshTime = DateTime.now();

      // Cache the fresh data
      await widget.cacheService.set(
        _cacheKey,
        freshData.toJson(),
        ttl: const Duration(minutes: 10),
      );

      setState(() {
        _data = freshData;
        _state = HomeContentState.ready;
        _error = null;
        _isRefreshing = false;
      });
    } else if (result.isFailure) {
      // If we have cached data, keep showing it with error indicator
      if (_data != null) {
        debugPrint('Home: Fetch failed, but showing cached data');
        setState(() {
          _error = result.error;
          _isRefreshing = false;
          // Keep state as ready to show cached data
        });
      } else {
        // No cached data, show error state
        setState(() {
          _error = result.error;
          _state = HomeContentState.error;
          _isRefreshing = false;
        });
      }
    }
  }

  /// Demo async operation that simulates network call
  Future<HomeData> _fetchDemoData() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Simulate occasional failures for demo
    final now = DateTime.now();
    if (now.second % 10 == 0) {
      throw const AppError(
        category: ErrorCategory.timeout,
        message: 'Simulated timeout',
      );
    }

    return HomeData(message: 'Content loaded successfully', timestamp: now);
  }

  Future<void> _handleLogout() async {
    await widget.authService.logout();
    if (mounted) {
      widget.navigation.clearAndGoTo('login');
    }
  }

  Future<void> _handleManualRefresh() async {
    await _loadContent();
  }

  @override
  Widget build(BuildContext context) {
    final showPromo = widget.configService.getFlag('home.promo_banner.enabled');
    final variant = widget.configService.getString('ui.theme_variant');

    return OfflineAwareScaffold(
      networkStatus: _networkStatus,
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          if (_isRefreshing)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _state == HomeContentState.loading
                  ? null
                  : _handleManualRefresh,
              tooltip: 'Refresh',
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleManualRefresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showPromo) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '✨ New Feature Enabled!',
                              style: TextStyle(
                                color: Colors.brown,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    FutureBuilder<String?>(
                      future: widget.authService.userId,
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back!',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'User: ${snapshot.data}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Theme: $variant',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey.shade500),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 24),
                    Text(
                      'Demo Content',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    if (_error != null && _data != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Colors.orange.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Showing cached data - refresh failed',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case HomeContentState.loading:
        return const LoadingIndicator(message: 'Loading content...');

      case HomeContentState.ready:
        return _buildReadyState();

      case HomeContentState.empty:
        return const EmptyState(
          message: 'No content available',
          icon: Icons.inbox_outlined,
        );

      case HomeContentState.error:
        return Center(
          child: ErrorCard(
            error: _error!,
            screen: "home",
            onRetry: _handleManualRefresh,
          ),
        );
    }
  }

  Widget _buildReadyState() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: Colors.green.shade700),
              const SizedBox(height: 12),
              Text(
                _data?.message ?? 'No data',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Loaded at ${_data?.timestamp.toLocal().toString().split('.')[0] ?? ''}',
                style: TextStyle(fontSize: 12, color: Colors.green.shade700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Pull down to refresh or tap the refresh button above.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
