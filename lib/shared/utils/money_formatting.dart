import '../../features/ledger/domain/models.dart';

class MoneyFormatting {
  MoneyFormatting._();

  /// Format a USD currency value with thousand separators
  /// Example: 1234.56 → "1,234.56"
  static String formatCurrency(double value) {
    return value
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  /// Format a balance with asset-specific decimals
  /// Example: 0.12345678 BTC → "0.12345678"
  static String formatBalance(double value, int decimals) {
    return value.toStringAsFixed(decimals);
  }

  /// Format a balance with asset context
  static String formatBalanceWithAsset(double value, Asset asset) {
    return '${formatBalance(value, asset.decimals)} ${asset.symbol}';
  }

  /// Format a date-time for display
  /// Example: 2024-12-09 14:30
  static String formatDateTime(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Format a date only (no time)
  /// Example: 2024-12-09
  static String formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  /// Format a relative time string
  /// Example: "2 hours ago", "just now"
  static String formatRelativeTime(
    DateTime time,
    String Function(String) translate,
  ) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return translate('ledger.dashboard.just_now');
    }
    if (diff.inMinutes < 60) {
      return translate(
        'ledger.dashboard.minutes_ago',
      ).replaceAll('{minutes}', diff.inMinutes.toString());
    }
    if (diff.inHours < 24) {
      return translate(
        'ledger.dashboard.hours_ago',
      ).replaceAll('{hours}', diff.inHours.toString());
    }
    return translate(
      'ledger.dashboard.days_ago',
    ).replaceAll('{days}', diff.inDays.toString());
  }

  /// Format a percentage
  /// Example: 0.1234 → "12.3%"
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  /// Format a compact currency value (for large numbers)
  /// Example: 1234567 → "1.23M"
  static String formatCompactCurrency(double value) {
    if (value.abs() >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (value.abs() >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    }
    return '\$${value.toStringAsFixed(2)}';
  }
}
