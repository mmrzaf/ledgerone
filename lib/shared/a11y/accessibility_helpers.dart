import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility guidelines and helpers
class A11yGuidelines {
  // Minimum touch target size (44x44 dp per iOS/Android guidelines)
  static const double minTouchTarget = 44.0;

  // Text scaling limits
  static const double minTextScale = 1.0;
  static const double maxTextScale = 2.0;

  // Contrast ratios (WCAG AA)
  static const double minContrastRatioNormal = 4.5;
  static const double minContrastRatioLarge = 3.0;

  /// Check if a size meets minimum touch target requirements
  static bool meetsMinimumTouchTarget(Size size) {
    return size.width >= minTouchTarget && size.height >= minTouchTarget;
  }

  /// Calculate contrast ratio between two colors
  static double contrastRatio(Color foreground, Color background) {
    final fgLuminance = foreground.computeLuminance();
    final bgLuminance = background.computeLuminance();

    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if contrast ratio meets WCAG AA standards
  static bool meetsContrastRequirement(
    Color foreground,
    Color background, {
    bool isLargeText = false,
  }) {
    final ratio = contrastRatio(foreground, background);
    final minRatio = isLargeText
        ? minContrastRatioLarge
        : minContrastRatioNormal;
    return ratio >= minRatio;
  }
}

/// Widget that ensures minimum touch target size
class AccessibleTouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const AccessibleTouchTarget({
    required this.child,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: A11yGuidelines.minTouchTarget,
            minHeight: A11yGuidelines.minTouchTarget,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Wrapper that announces changes to screen readers
class AccessibleAnnouncement extends StatefulWidget {
  final String message;
  final Widget child;
  final bool announce;

  const AccessibleAnnouncement({
    required this.message,
    required this.child,
    this.announce = true,
    super.key,
  });

  @override
  State<AccessibleAnnouncement> createState() => _AccessibleAnnouncementState();
}

class _AccessibleAnnouncementState extends State<AccessibleAnnouncement> {
  @override
  void didUpdateWidget(AccessibleAnnouncement oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.announce && widget.message != oldWidget.message) {
      _announce();
    }
  }

  void _announce() {
    final view = View.of(context);
    final textDirection = Directionality.of(context);

    SemanticsService.sendAnnouncement(view, widget.message, textDirection);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Focus management helpers
class A11yFocus {
  /// Request focus on a widget
  static void requestFocus(BuildContext context, FocusNode node) {
    FocusScope.of(context).requestFocus(node);
  }

  /// Move focus to next field
  static void nextFocus(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Move focus to previous field
  static void previousFocus(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// Unfocus current field
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}

/// Semantic label helpers
class A11yLabels {
  /// Create a descriptive label for a button
  static String button(String action, {String? context}) {
    if (context != null) {
      return '$action button, $context';
    }
    return '$action button';
  }

  /// Create a label for a loading state
  static String loading(String? context) {
    if (context != null) {
      return 'Loading $context';
    }
    return 'Loading';
  }

  /// Create a label for an error state
  static String error(String message) {
    return 'Error: $message';
  }

  /// Create a label for a success state
  static String success(String message) {
    return 'Success: $message';
  }
}

/// Extension for adding accessibility to common widgets
extension A11yWidget on Widget {
  /// Wrap widget with semantic label
  Widget withLabel(String label) {
    return Semantics(label: label, child: this);
  }

  /// Exclude from accessibility tree
  Widget excludeFromSemantics() {
    return ExcludeSemantics(child: this);
  }

  /// Mark as header for screen readers
  Widget asHeader() {
    return Semantics(header: true, child: this);
  }

  /// Mark as link
  Widget asLink() {
    return Semantics(link: true, child: this);
  }

  /// Mark as image with description
  Widget asImage(String description) {
    return Semantics(image: true, label: description, child: this);
  }
}

/// RTL-aware layout helpers
class RtlAwareLayout {
  /// Get correct edge insets based on text direction
  static EdgeInsets directionalInsets({
    required TextDirection direction,
    double start = 0,
    double top = 0,
    double end = 0,
    double bottom = 0,
  }) {
    return EdgeInsetsDirectional.only(
      start: start,
      top: top,
      end: end,
      bottom: bottom,
    ).resolve(direction);
  }

  /// Get correct alignment based on text direction
  static Alignment directionalAlignment(
    TextDirection direction, {
    bool isStart = true,
  }) {
    if (direction == TextDirection.rtl) {
      return isStart ? Alignment.centerRight : Alignment.centerLeft;
    }
    return isStart ? Alignment.centerLeft : Alignment.centerRight;
  }
}
