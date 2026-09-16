import 'package:flutter/material.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';

/// Confirmation dialog — required for destructive actions (§60).
/// Destructive commands need warning + explanation + confirmation.
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.explanation,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
  });

  final String title;
  final String explanation;
  final String confirmLabel;
  final String cancelLabel;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String explanation,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: title,
        explanation: explanation,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: Text(title,
          maxLines: 2, overflow: TextOverflow.ellipsis),
      content: Text(explanation, style: theme.textTheme.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        RetraceButton(
          label: confirmLabel,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

/// Bottom sheet helper with safe-area + keyboard padding.
Future<T?> showRetraceSheet<T>(
  BuildContext context, {
  required Widget child,
  required String semanticLabel,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => Semantics(
      label: semanticLabel,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: RetraceSpacing.md,
            right: RetraceSpacing.md,
            top: RetraceSpacing.sm,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                RetraceSpacing.md,
          ),
          child: child,
        ),
      ),
    ),
  );
}
