import 'package:flutter/material.dart';

import '../../../app/presentation/error_presenter.dart';
import '../../../app/presentation/offline_banner.dart';
import '../../../core/contracts/cache_contract.dart';
import '../../../core/contracts/config_contract.dart';
import '../../../core/contracts/i18n_contract.dart';
import '../../../core/contracts/lifecycle_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/contracts/network_contract.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/errors/result.dart';
import '../../../core/i18n/string_keys.dart';
import '../../../core/runtime/cancellation_token.dart';
import '../domain/home_models.dart';
import '../domain/home_repository.dart';

enum HomeContentState { loading, ready, empty, error }

class HomeScreen extends StatefulWidget {
  final NavigationService navigation;
  final ConfigService configService;
  final NetworkService networkService;
  final CacheService cacheService;
  final AppLifecycleService lifecycleService;
  final HomeRepository homeRepository;

  const HomeScreen({
    required this.navigation,
    required this.configService,
    required this.networkService,
    required this.cacheService,
    required this.lifecycleService,
    required this.homeRepository,
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
  // static const String _cacheKey = 'home_data';

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

  void _handleAppResume() {
    debugPrint('Home: App resumed from background');

    if (_shouldRefreshOnResume()) {
      debugPrint('Home: Triggering background refresh');
      _loadContent(isBackgroundRefresh: true);
    } else {
      debugPrint('Home: Skipping refresh (too soon since last refresh)');
    }
  }

  bool _shouldRefreshOnResume() {
    if (_networkStatus.isOffline) {
      return false;
    }

    if (_isRefreshing) {
      return false;
    }

    if (_lastRefreshTime != null) {
      final timeSinceRefresh = DateTime.now().difference(_lastRefreshTime!);
      if (timeSinceRefresh < _minRefreshInterval) {
        return false;
      }
    }

    return true;
  }

  Future<void> _loadContent({bool isBackgroundRefresh = false}) async {
    final token = _cancellationSource.token;

    if (!isBackgroundRefresh) {
      setState(() {
        _state = HomeContentState.loading;
        _error = null;
      });
    } else {
      setState(() => _isRefreshing = true);
    }

    token.throwIfCancelled();

    final repositoryResult = await widget.homeRepository.load(
      forceRefresh: isBackgroundRefresh,
    );

    if (!mounted) return;

    if (repositoryResult is Success<HomeData>) {
      final freshData = repositoryResult.data;
      setState(() {
        _data = freshData;
        _state = HomeContentState.ready;
        _error = null;
        _isRefreshing = false;
        _lastRefreshTime = DateTime.now();
      });
    } else if (repositoryResult is Failure<HomeData>) {
      setState(() {
        _error = repositoryResult.error;
        _state = _data == null
            ? HomeContentState.error
            : HomeContentState.ready;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _handleManualRefresh() async {
    await _loadContent();
  }

  @override
  Widget build(BuildContext context) {
    final showPromo = widget.configService.getFlag('home.promo_banner.enabled');
    final l10n = context.l10n;

    return OfflineAwareScaffold(
      networkStatus: _networkStatus,
      appBar: AppBar(
        title: Text(l10n.get(L10nKeys.homeTitle)),
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
              tooltip: l10n.get(L10nKeys.homeRefresh),
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
                      ),
                    ],
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 24),
                    Text(
                      l10n.get(L10nKeys.homeDemoContent),
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
                            Expanded(
                              child: Text(
                                l10n.get(L10nKeys.homeOfflineWarning),
                                style: const TextStyle(fontSize: 12),
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
                child: _buildContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = context.l10n;
    switch (_state) {
      case HomeContentState.loading:
        return LoadingIndicator(message: l10n.get(L10nKeys.homeLoadingContent));

      case HomeContentState.ready:
        return _buildReadyState(context);

      case HomeContentState.empty:
        return EmptyState(
          message: l10n.get(L10nKeys.homeNoContent),
          icon: Icons.inbox_outlined,
        );

      case HomeContentState.error:
        return Center(
          child: ErrorCard(
            error: _error!,
            screen: 'home',
            onRetry: _handleManualRefresh,
          ),
        );
    }
  }

  Widget _buildReadyState(BuildContext context) {
    final l10n = context.l10n;
    final timestamp = _data?.timestamp.toLocal().toString().split('.')[0] ?? '';
    final loadedAt = l10n.get(
      L10nKeys.homeLoadedAt,
      args: {'timestamp': timestamp},
    );

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
                _data?.message ?? l10n.get(L10nKeys.homeNoContent),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                loadedAt,
                style: TextStyle(fontSize: 12, color: Colors.green.shade700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.get(L10nKeys.homeRefreshInstruction),
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
