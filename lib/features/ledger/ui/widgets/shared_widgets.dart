import 'package:flutter/material.dart';
import 'package:ledgerone/core/contracts/navigation_contract.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../shared/utils/money_formatting.dart';
import '../../domain/models.dart';

// =============================================================================
// Layout Components
// =============================================================================

/// Standard page padding
const kPagePadding = EdgeInsets.all(16.0);
const kCardPadding = EdgeInsets.all(16.0);
const kItemSpacing = 12.0;
const kSectionSpacing = 24.0;

/// Section header with optional action
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionHeader({required this.title, this.action, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// =============================================================================
// State Indicators
// =============================================================================

/// Loading indicator with optional message
class LoadingView extends StatelessWidget {
  final String? message;

  const LoadingView({this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty state with icon and message
class EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyView({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: kPagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error view with retry option
class ErrorView extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;

  const ErrorView({required this.error, this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: kPagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              error.message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Cards
// =============================================================================

/// Standard card wrapper
class LedgerCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const LedgerCard({
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? const EdgeInsets.only(bottom: kItemSpacing),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(padding: padding ?? kCardPadding, child: child),
      ),
    );
  }
}

/// Summary card with title and large value
class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;
  final Widget? subtitle;
  final Widget? trailing;

  const SummaryCard({
    required this.title,
    required this.value,
    this.valueColor,
    this.subtitle,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LedgerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? theme.colorScheme.primary,
            ),
          ),
          if (subtitle != null) ...[const SizedBox(height: 8), subtitle!],
        ],
      ),
    );
  }
}

/// Metric row for displaying key-value pairs
class MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  const MetricRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// List Items
// =============================================================================

/// Asset list tile
class AssetTile extends StatelessWidget {
  final Asset asset;
  final String balance;
  final String? usdValue;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AssetTile({
    required this.asset,
    required this.balance,
    this.usdValue,
    this.onTap,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LedgerCard(
      onTap: onTap,
      child: Row(
        children: [
          AssetAvatar(symbol: asset.symbol, type: asset.type),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.symbol,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(asset.name, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(balance, style: theme.textTheme.titleSmall),
              if (usdValue != null)
                Text(
                  usdValue!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// Account list tile
class AccountTile extends StatelessWidget {
  final Account account;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AccountTile({
    required this.account,
    this.subtitle,
    this.onTap,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LedgerCard(
      onTap: onTap,
      child: Row(
        children: [
          AccountAvatar(type: account.type),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle ?? account.type.displayName,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final String? amount;
  final NavigationService? navigation;
  final VoidCallback? onTap;

  const TransactionTile({
    required this.transaction,
    this.amount,
    this.navigation,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LedgerCard(
      onTap:
          onTap ??
          (navigation != null
              ? () => navigation!.goToRoute(
                  'transaction_editor',
                  params: {'id': transaction.id},
                )
              : null),
      child: Row(
        children: [
          TransactionTypeIcon(type: transaction.type),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        transaction.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (transaction.type == TransactionType.adjustment) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.edit, size: 16, color: Colors.orange),
                    ],
                  ],
                ),
                Text(
                  MoneyFormatting.formatDate(transaction.timestamp),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (amount != null)
            Text(
              amount!,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Avatars & Icons
// =============================================================================

/// Asset avatar with first letter
class AssetAvatar extends StatelessWidget {
  final String symbol;
  final AssetType type;
  final double size;

  const AssetAvatar({
    required this.symbol,
    required this.type,
    this.size = 40,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = type == AssetType.crypto
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.secondaryContainer;
    final textColor = type == AssetType.crypto
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSecondaryContainer;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      child: Text(
        symbol.isNotEmpty ? symbol[0].toUpperCase() : '?',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

/// Account avatar with icon
class AccountAvatar extends StatelessWidget {
  final AccountType type;
  final double size;

  const AccountAvatar({required this.type, this.size = 40, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        _iconForType(type),
        size: size * 0.5,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  IconData _iconForType(AccountType type) {
    switch (type) {
      case AccountType.exchange:
        return Icons.currency_bitcoin;
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.wallet:
        return Icons.account_balance_wallet;
      case AccountType.cash:
        return Icons.money;
      case AccountType.other:
        return Icons.folder;
    }
  }
}

/// Transaction type icon
class TransactionTypeIcon extends StatelessWidget {
  final TransactionType type;
  final double size;

  const TransactionTypeIcon({required this.type, this.size = 40, super.key});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _styleForType(type);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }

  (Color, IconData) _styleForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return (Colors.green, Icons.arrow_downward);
      case TransactionType.expense:
        return (Colors.red, Icons.arrow_upward);
      case TransactionType.transfer:
        return (Colors.blue, Icons.swap_horiz);
      case TransactionType.trade:
        return (Colors.purple, Icons.compare_arrows);
      case TransactionType.adjustment:
        return (Colors.orange, Icons.edit);
    }
  }
}

// =============================================================================
// Chips & Badges
// =============================================================================

/// Transaction type chip
class TransactionTypeChip extends StatelessWidget {
  final TransactionType type;

  const TransactionTypeChip({required this.type, super.key});

  @override
  Widget build(BuildContext context) {
    final (color, _) = _styleForType(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        type.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  (Color, IconData) _styleForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return (Colors.green, Icons.arrow_downward);
      case TransactionType.expense:
        return (Colors.red, Icons.arrow_upward);
      case TransactionType.transfer:
        return (Colors.blue, Icons.swap_horiz);
      case TransactionType.trade:
        return (Colors.purple, Icons.compare_arrows);
      case TransactionType.adjustment:
        return (Colors.orange, Icons.edit);
    }
  }
}

/// Period selector chips
class PeriodSelector<T extends Enum> extends StatelessWidget {
  final T selected;
  final List<T> values;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  const PeriodSelector({
    required this.selected,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: values.map((value) {
          final isSelected = value == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labelBuilder(value)),
              selected: isSelected,
              onSelected: (_) => onChanged(value),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// Dialogs & Sheets
// =============================================================================

/// Standard bottom sheet container
class LedgerBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const LedgerBottomSheet({
    required this.title,
    required this.child,
    this.actions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          child,
          if (actions != null) ...[
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
          ],
        ],
      ),
    );
  }
}

/// Confirm delete dialog
Future<bool> showDeleteConfirmation(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}
