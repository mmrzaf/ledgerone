import 'package:flutter/material.dart';

/// An accessible card with proper touch targets and semantics
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const AccessibleCard({
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.padding,
    this.margin,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: 0,
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    if (semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: card,
      );
    }

    return card;
  }
}

/// A loading indicator with accessible label
class AccessibleLoadingIndicator extends StatelessWidget {
  final String? message;
  final String? semanticLabel;

  const AccessibleLoadingIndicator({
    this.message,
    this.semanticLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: semanticLabel ?? 'Loading',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// An empty state with icon and message
class AccessibleEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AccessibleEmptyState({
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// An accessible icon button with proper semantics
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final String semanticLabel;
  final Color? color;

  const AccessibleIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.semanticLabel,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip,
        color: color,
      ),
    );
  }
}

/// An accessible list tile with proper minimum height
class AccessibleListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const AccessibleListTile({
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      minVerticalPadding: 12,
    );

    if (semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: tile,
      );
    }

    return tile;
  }
}

/// A section header with proper semantics
class AccessibleSectionHeader extends StatelessWidget {
  final String text;
  final EdgeInsets? padding;

  const AccessibleSectionHeader({required this.text, this.padding, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      header: true,
      child: Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// A text field with proper accessibility
class AccessibleTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? semanticLabel;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final int? maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const AccessibleTextField({
    this.controller,
    required this.label,
    this.hint,
    this.semanticLabel,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      textField: true,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        maxLines: maxLines,
      ),
    );
  }
}

/// A dropdown with proper accessibility
class AccessibleDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final String? semanticLabel;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const AccessibleDropdown({
    required this.value,
    required this.label,
    this.semanticLabel,
    required this.items,
    required this.onChanged,
    this.validator,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      button: true,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}

/// An accessible button with proper minimum size
class AccessibleButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final IconData? icon;
  final bool isPrimary;

  const AccessibleButton({
    required this.text,
    required this.onPressed,
    this.semanticLabel,
    this.icon,
    this.isPrimary = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(text),
            style: ElevatedButton.styleFrom(minimumSize: const Size(88, 48)),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(minimumSize: const Size(88, 48)),
            child: Text(text),
          );

    return Semantics(
      label: semanticLabel ?? text,
      button: true,
      enabled: onPressed != null,
      child: button,
    );
  }
}

/// RTL-aware padding helper
class RtlPadding extends StatelessWidget {
  final Widget child;
  final double start;
  final double top;
  final double end;
  final double bottom;

  const RtlPadding({
    required this.child,
    this.start = 0,
    this.top = 0,
    this.end = 0,
    this.bottom = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: start,
        top: top,
        end: end,
        bottom: bottom,
      ),
      child: child,
    );
  }
}
