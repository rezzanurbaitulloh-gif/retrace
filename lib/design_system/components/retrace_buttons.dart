import 'package:flutter/material.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';

/// Primary CTA (solid mint) + secondary (outline). Single icon family:
/// Material Symbols — never emoji as structural icons (§54, ProMax rules).
class RetraceButton extends StatelessWidget {
  const RetraceButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isSecondary = false,
    this.isDestructive = false,
    this.isLoading = false,
    this.semanticHint,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isSecondary;
  final bool isDestructive;
  final bool isLoading;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool disabled = onPressed == null && !isLoading;
    final Widget? iconWidget = isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : (icon == null ? null : Icon(icon, size: 18));

    final ButtonStyle style = (isSecondary
            ? OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(RetraceRadius.md),
                ),
              )
            : FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: isDestructive
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                foregroundColor: isDestructive
                    ? theme.colorScheme.onError
                    : theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(RetraceRadius.md),
                ),
              ))
        .copyWith(
      tapTargetSize: MaterialTapTargetSize.padded,
    );

    final Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (iconWidget != null) ...[
          iconWidget,
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final Widget button = isSecondary
        ? OutlinedButton(
            onPressed: (disabled || isLoading) ? null : onPressed,
            style: style,
            child: child,
          )
        : FilledButton(
            onPressed: (disabled || isLoading) ? null : onPressed,
            style: style,
            child: child,
          );

    return Semantics(
      button: true,
      enabled: !disabled && !isLoading,
      hint: semanticHint,
      child: button,
    );
  }
}

/// 48dp-minimum icon button with expanded hit area (§57/§58).
class RetraceIconButton extends StatelessWidget {
  const RetraceIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    );
  }
}

/// Remote-command action tile (Ring / Vibrate / Lock / Locate ...).
class CommandButton extends StatelessWidget {
  const CommandButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.sublabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String? sublabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(RetraceRadius.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(RetraceSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RetraceRadius.md),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: RetraceSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge),
                    if (sublabel != null)
                      Text(sublabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
