import 'package:flutter/material.dart';
import '../../core/contracts/network_contract.dart';

/// Banner that appears when app goes offline
class OfflineBanner extends StatelessWidget {
  final NetworkStatus status;

  const OfflineBanner({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    if (status.isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade800,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withAlpha((255 * 0.1).round()),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                status == NetworkStatus.offline
                    ? 'No internet connection'
                    : 'Connection status unknown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (status == NetworkStatus.offline)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((255 * 0.2).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Offline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget that wraps content with offline banner
class OfflineAwareScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final NetworkStatus networkStatus;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const OfflineAwareScaffold({
    required this.body,
    required this.networkStatus,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Column(
        children: [
          OfflineBanner(status: networkStatus),
          Expanded(child: body),
        ],
      ),
    );
  }
}
