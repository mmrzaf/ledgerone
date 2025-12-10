import 'package:flutter/material.dart';
import '../../../../core/contracts/i18n_contract.dart';
import '../../../../core/i18n/string_keys.dart';
import '../../domain/models.dart';

/// Badge to visually indicate adjustment transactions
class AdjustmentBadge extends StatelessWidget {
  final TransactionType type;
  final double? amount;

  const AdjustmentBadge({required this.type, this.amount, super.key});

  @override
  Widget build(BuildContext context) {
    if (type != TransactionType.adjustment) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = context.l10n;

    final isPositive = amount != null && amount! > 0;
    final color = isPositive ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            l10n.get('ledger.tx_type.adjustment'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Transaction type chip with color coding
class TransactionTypeChip extends StatelessWidget {
  final TransactionType type;
  final bool showLabel;

  const TransactionTypeChip({
    required this.type,
    this.showLabel = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final (color, icon) = _getTypeStyle(type);

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: showLabel
          ? Text(
              l10n.get('ledger.tx_type.${type.name}'),
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            )
          : const SizedBox.shrink(),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color, width: 1),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  (Color, IconData) _getTypeStyle(TransactionType type) {
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

/// Helper text for adjustment transactions
class AdjustmentHelperText extends StatelessWidget {
  const AdjustmentHelperText({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.get(L10nKeys.ledgerTxEditorAdjustmentHelper),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
