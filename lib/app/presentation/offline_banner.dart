import 'package:flutter/material.dart';

import '../../core/contracts/i18n_contract.dart';
import '../../core/contracts/network_contract.dart';
import '../../core/i18n/string_keys.dart';

class OfflineBanner extends StatelessWidget {
  final NetworkStatus status;

  const OfflineBanner({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    if (status.isOnline) return const SizedBox.shrink();

    final l10n = context.l10n;
    final messageKey = switch (status) {
      NetworkStatus.offline => L10nKeys.networkOffline,
      NetworkStatus.online => L10nKeys.networkOnline,
      _ => L10nKeys.networkUnknown,
    };

    return Container(
      color: Colors.orange.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.get(messageKey),
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          TextButton(
            onPressed: () {
              // Optional: trigger manual retry from parent via callback
            },
            child: Text(
              l10n.get(L10nKeys.retry),
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        ],
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
