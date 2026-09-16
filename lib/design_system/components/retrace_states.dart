import 'package:flutter/material.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';

/// Canonical screen states (§49/§50/§59). Every major screen must wire
/// Normal / Loading / Empty / Error / Offline / Success / Restricted.
enum RetraceScreenState {
  normal,
  loading,
  empty,
  error,
  offline,
  success,
  restricted,
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message = 'Loading…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: RetraceSpacing.sm),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.devices_outlined,
  });

  final String title;
  final String message;

  /// Both must be non-null to render the button — read-only empties pass null
  /// so no dead button ever ships.
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? label = actionLabel;
    final VoidCallback? action = onAction;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RetraceSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: theme.colorScheme.primary),
            const SizedBox(height: RetraceSpacing.sm),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium),
            if (label != null && action != null) ...[
              const SizedBox(height: RetraceSpacing.md),
              RetraceButton(label: label, onPressed: action),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RetraceSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_outlined,
                size: 44, color: RetraceColors.warning),
            const SizedBox(height: RetraceSpacing.sm),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: RetraceSpacing.md),
            RetraceButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

/// Offline banner — app stays usable, tracking continues locally (§59).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.pendingCount,
    required this.lastSynced,
  });

  final int pendingCount;
  final String lastSynced;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      label: 'Offline. $pendingCount locations waiting to sync.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(RetraceSpacing.sm),
        decoration: BoxDecoration(
          color: RetraceColors.warning.withValues(alpha: 0.14),
          border: Border.all(
              color: RetraceColors.warning.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(RetraceRadius.sm),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: RetraceColors.warning),
            const SizedBox(width: RetraceSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('OFFLINE',
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: RetraceColors.warning)),
                  Text(
                    'Tracking continues locally. Last synced: $lastSynced. '
                    'Pending: $pendingCount locations.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sync status pill (Online / Syncing / Sync failed / Synced).
class SyncIndicator extends StatelessWidget {
  const SyncIndicator(
      {super.key, required this.label, required this.isSyncing});

  final String label;
  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      label: 'Sync status: $label',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSyncing)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.sync_outlined, size: 16),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
