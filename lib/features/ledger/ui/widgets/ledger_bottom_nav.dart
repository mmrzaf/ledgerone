import 'package:flutter/material.dart';
import '../../../../core/contracts/i18n_contract.dart';
import '../../../../core/contracts/navigation_contract.dart';
import '../../../../core/i18n/string_keys.dart';

enum LedgerTab { dashboard, crypto, money }

class LedgerBottomNav extends StatelessWidget {
  final LedgerTab currentTab;
  final NavigationService navigation;

  const LedgerBottomNav({
    required this.currentTab,
    required this.navigation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BottomNavigationBar(
      currentIndex: currentTab.index,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: l10n.get(L10nKeys.ledgerNavDashboard),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.currency_bitcoin),
          label: l10n.get(L10nKeys.ledgerNavCrypto),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.account_balance_wallet),
          label: l10n.get(L10nKeys.ledgerNavMoney),
        ),
      ],
      onTap: (index) {
        final tab = LedgerTab.values[index];
        if (tab == currentTab) return;

        switch (tab) {
          case LedgerTab.dashboard:
            navigation.goToRoute('dashboard');
            break;
          case LedgerTab.crypto:
            navigation.goToRoute('crypto');
            break;
          case LedgerTab.money:
            navigation.goToRoute('money');
            break;
        }
      },
    );
  }
}
