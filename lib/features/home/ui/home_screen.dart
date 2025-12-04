import 'package:flutter/material.dart';

import '../../../app/presentation/error_presenter.dart';
import '../../../core/contracts/auth_contract.dart';
import '../../../core/contracts/config_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/runtime/cancellation_token.dart';
import '../../../core/runtime/retry_helper.dart';

enum HomeContentState { loading, ready, empty, error }

class HomeData {
  final String message;
  final DateTime timestamp;

  HomeData({required this.message, required this.timestamp});
}

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final NavigationService navigation;
  final ConfigService configService;

  const HomeScreen({
    required this.authService,
    required this.navigation,
    required this.configService,
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

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _cancellationSource.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() {
      _state = HomeContentState.loading;
      _error = null;
    });

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
      return;
    }

    if (result.isSuccess) {
      setState(() {
        _data = result.data;
        _state = _data == null
            ? HomeContentState.empty
            : HomeContentState.ready;
      });
    } else if (result.isFailure) {
      setState(() {
        _error = result.error;
        _state = HomeContentState.error;
      });
    }
  }

  /// Demo async operation that simulates network call
  Future<HomeData> _fetchDemoData() async {
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

  @override
  Widget build(BuildContext context) {
    final showPromo = widget.configService.getFlag('home.promo_banner.enabled');
    final variant = widget.configService.getString('ui.theme_variant');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _state == HomeContentState.loading ? null : _loadContent,
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
        onRefresh: _loadContent,
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
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
          child: ErrorCard(error: _error!, onRetry: _loadContent),
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
