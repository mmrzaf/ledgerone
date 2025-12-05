import 'package:flutter/material.dart';
import '../../../app/di.dart';
import '../../../app/presentation/error_presenter.dart';
import '../../../app/services/crash_service_impl.dart';
import '../../../core/contracts/analytics_contract.dart';
import '../../../core/contracts/auth_contract.dart';
import '../../../core/contracts/crash_contract.dart';
import '../../../core/contracts/navigation_contract.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/observability/analytics_allowlist.dart';
import '../../../core/observability/performance_tracker.dart';
import '../../../core/runtime/cancellation_token.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final NavigationService navigation;

  const LoginScreen({
    required this.authService,
    required this.navigation,
    super.key,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cancellationSource = CancellationTokenSource();

  late final AnalyticsService _analytics;
  late final CrashServiceImpl _crash;

  bool _isLoading = false;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    _analytics = ServiceLocator().get<AnalyticsService>();
    _crash = ServiceLocator().get<CrashService>() as CrashServiceImpl;

    // Log screen view
    _analytics.logScreenView('login');
    _analytics.logEvent(AnalyticsAllowlist.loginView.name);

    _crash.addBreadcrumb('Viewed login screen', category: 'navigation');
  }

  @override
  void dispose() {
    _cancellationSource.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    return email.isNotEmpty && email.contains('@') && password.length >= 6;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Start performance tracking
    PerformanceTracker().start(PerformanceMetrics.loginAttempt);

    // Log attempt
    await _analytics.logEvent(AnalyticsAllowlist.loginAttempt.name);
    _crash.addBreadcrumb('Login attempt', category: 'auth');

    try {
      _cancellationSource.token.throwIfCancelled();

      await widget.authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      _cancellationSource.token.throwIfCancelled();

      // Stop performance tracking
      final metric = PerformanceTracker().stop(PerformanceMetrics.loginAttempt);

      // Log success
      await _analytics.logEvent(
        AnalyticsAllowlist.loginSuccess.name,
        parameters: {if (metric != null) 'duration_ms': metric.durationMs},
      );

      _crash.addBreadcrumb('Login successful', category: 'auth');

      // Set user ID (hashed)
      final userId = await widget.authService.userId;
      await _analytics.setUserId(userId);

      widget.navigation.clearAndGoTo('home');
    } on OperationCancelledException {
      // Navigation away during login - do nothing
      debugPrint('Login cancelled by navigation');
      _crash.addBreadcrumb('Login cancelled', category: 'auth');
    } catch (e) {
      if (!mounted) return;

      final appError = e is AppError
          ? e
          : AppError(
              category: ErrorCategory.invalidCredentials,
              message: 'Login failed',
              originalError: e,
            );

      setState(() {
        _error = appError;
        _isLoading = false;
      });

      // Log failure
      await _analytics.logEvent(
        AnalyticsAllowlist.loginFailure.name,
        parameters: {'error_category': appError.category.name},
      );

      _crash.recordErrorCategory(appError.category.name, 'login');

      // Record error to crash service
      await _crash.recordError(appError, appError.stackTrace);
      if (!mounted) return;
      ErrorPresenter.showError(context, appError, onRetry: _handleLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_outline, size: 80, color: Colors.blue),
                  const SizedBox(height: 32),
                  const Text(
                    'Sign In',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    ErrorCard(
                      screen: 'login',
                      error: _error!,
                      onRetry: () {
                        _analytics.logEvent(
                          AnalyticsAllowlist.errorRetry.name,
                          parameters: {'error_category': _error!.category.name},
                        );
                        _handleLogin();
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading || !_isValid ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign In', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
