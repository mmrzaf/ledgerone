import 'package:app_flutter_starter/app/presentation/offline_banner.dart';
import 'package:app_flutter_starter/app/services/localization_service_impl.dart';
import 'package:app_flutter_starter/core/contracts/network_contract.dart';
import 'package:app_flutter_starter/core/i18n/string_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_services.dart';

void main() {
  group('OfflineBanner', () {
    late LocalizationServiceImpl localization;

    setUp(() async {
      final storage = MockStorageService();
      localization = LocalizationServiceImpl(storage: storage);
      await localization.initialize();
    });

    testWidgets('is hidden when status is online', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OfflineBanner(status: NetworkStatus.online)),
        ),
      );

      // Should render nothing (SizedBox.shrink)
      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(
        find.text(localization.get(L10nKeys.networkOffline)),
        findsNothing,
      );
      expect(find.text(localization.get(L10nKeys.retry)), findsNothing);
    });

    testWidgets('shows offline message and retry when offline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OfflineBanner(status: NetworkStatus.offline)),
        ),
      );

      expect(
        find.text(localization.get(L10nKeys.networkOffline)),
        findsOneWidget,
      );
      expect(find.text(localization.get(L10nKeys.retry)), findsOneWidget);
    });

    testWidgets('shows unknown message when status is unknown', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OfflineBanner(status: NetworkStatus.unknown)),
        ),
      );

      expect(
        find.text(localization.get(L10nKeys.networkUnknown)),
        findsOneWidget,
      );
    });
  });
}
