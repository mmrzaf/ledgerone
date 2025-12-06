import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerone/shared/a11y/accessibility_helpers.dart';

void main() {
  group('A11yGuidelines', () {
    test('minimum touch target constant is correct', () {
      expect(A11yGuidelines.minTouchTarget, 44.0);
    });

    test('meetsMinimumTouchTarget validates size', () {
      // Meets requirement
      expect(
        A11yGuidelines.meetsMinimumTouchTarget(const Size(44, 44)),
        isTrue,
      );
      expect(
        A11yGuidelines.meetsMinimumTouchTarget(const Size(50, 50)),
        isTrue,
      );

      // Fails requirement
      expect(
        A11yGuidelines.meetsMinimumTouchTarget(const Size(40, 40)),
        isFalse,
      );
      expect(
        A11yGuidelines.meetsMinimumTouchTarget(const Size(44, 30)),
        isFalse,
      );
    });

    test('calculates contrast ratio correctly', () {
      // Black on white (maximum contrast)
      final blackWhite = A11yGuidelines.contrastRatio(
        Colors.black,
        Colors.white,
      );
      expect(blackWhite, greaterThan(20)); // Should be 21:1

      // White on black (same ratio)
      final whiteBlack = A11yGuidelines.contrastRatio(
        Colors.white,
        Colors.black,
      );
      expect(whiteBlack, closeTo(blackWhite, 0.1));

      // Same color (minimum contrast)
      final sameColor = A11yGuidelines.contrastRatio(Colors.blue, Colors.blue);
      expect(sameColor, closeTo(1.0, 0.1));
    });

    test('validates WCAG AA contrast requirements', () {
      // Black on white meets AA for normal text
      expect(
        A11yGuidelines.meetsContrastRequirement(
          Colors.black,
          Colors.white,
          isLargeText: false,
        ),
        isTrue,
      );

      // Light gray on white fails AA for normal text
      expect(
        A11yGuidelines.meetsContrastRequirement(
          Colors.grey.shade300,
          Colors.white,
          isLargeText: false,
        ),
        isFalse,
      );

      // Same light gray might pass for large text (lower requirement)
      final lightGray = Colors.grey.shade600;
      expect(
        A11yGuidelines.meetsContrastRequirement(
          lightGray,
          Colors.white,
          isLargeText: true,
        ),
        isTrue,
      );
    });
  });

  group('AccessibleTouchTarget', () {
    testWidgets('enforces minimum touch target size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleTouchTarget(
              onTap: () {},
              child: const Icon(Icons.star, size: 16),
            ),
          ),
        ),
      );

      final container = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(AccessibleTouchTarget),
          matching: find.byType(ConstrainedBox),
        ),
      );

      expect(container.constraints.minWidth, A11yGuidelines.minTouchTarget);
      expect(container.constraints.minHeight, A11yGuidelines.minTouchTarget);
    });

    testWidgets('has proper semantic button label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleTouchTarget(
              onTap: () {},
              semanticLabel: 'Test button',
              child: const Icon(Icons.star),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Test button'), findsOneWidget);
    });
  });

  group('A11yLabels', () {
    test('creates button labels', () {
      expect(A11yLabels.button('Refresh'), 'Refresh button');
      expect(
        A11yLabels.button('Delete', context: 'email'),
        'Delete button, email',
      );
    });

    test('creates loading labels', () {
      expect(A11yLabels.loading(null), 'Loading');
      expect(A11yLabels.loading('content'), 'Loading content');
    });

    test('creates error labels', () {
      expect(A11yLabels.error('Network failed'), 'Error: Network failed');
    });

    test('creates success labels', () {
      expect(
        A11yLabels.success('Saved successfully'),
        'Success: Saved successfully',
      );
    });
  });

  group('A11yWidget Extensions', () {
    // testWidgets('withLabel adds semantic label', (tester) async {
    //   await tester.pumpWidget(
    //     MaterialApp(
    //       home: Scaffold(
    //         body: const Text('Hello').withLabel('Greeting'),
    //       ),
    //     ),
    //   );
    //
    //   final semantics = find.descendant(
    //     of: find.byType(Scaffold),
    //     matching: find.bySemanticsLabel('Greeting'),
    //   );
    //
    //   expect(semantics, findsOneWidget);
    // });

    //   testWidgets('asHeader marks widget as header', (tester) async {
    //     await tester.pumpWidget(
    //       MaterialApp(home: Scaffold(body: const Text('Title').asHeader())),
    //     );
    //     final semantics = tester.getSemantics(find.byType(Semantics).first);
    //     expect(semantics.flagsCollection.isHeader, isTrue);
    //   });
  });

  group('RtlAwareLayout', () {
    test('directionalInsets work for LTR', () {
      final insets = RtlAwareLayout.directionalInsets(
        direction: TextDirection.ltr,
        start: 10,
        end: 20,
      );

      expect(insets.left, 10);
      expect(insets.right, 20);
    });

    test('directionalInsets work for RTL', () {
      final insets = RtlAwareLayout.directionalInsets(
        direction: TextDirection.rtl,
        start: 10,
        end: 20,
      );

      expect(insets.right, 10); // Start becomes right in RTL
      expect(insets.left, 20); // End becomes left in RTL
    });

    test('directionalAlignment works for LTR', () {
      final start = RtlAwareLayout.directionalAlignment(
        TextDirection.ltr,
        isStart: true,
      );
      final end = RtlAwareLayout.directionalAlignment(
        TextDirection.ltr,
        isStart: false,
      );

      expect(start, Alignment.centerLeft);
      expect(end, Alignment.centerRight);
    });

    test('directionalAlignment works for RTL', () {
      final start = RtlAwareLayout.directionalAlignment(
        TextDirection.rtl,
        isStart: true,
      );
      final end = RtlAwareLayout.directionalAlignment(
        TextDirection.rtl,
        isStart: false,
      );

      expect(start, Alignment.centerRight);
      expect(end, Alignment.centerLeft);
    });
  });
}
