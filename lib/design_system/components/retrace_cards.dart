import 'package:flutter/material.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';

/// Generic elevated-surface card. No manual per-screen styling (§51).
class RetraceCard extends StatelessWidget {
  const RetraceCard({super.key, required this.child, this.onTap, this.label});

  final Widget child;
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final Widget card = Card(
      child: Padding(
        padding: const EdgeInsets.all(RetraceSpacing.md),
        child: child,
      ),
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: RetraceRadius.card,
        child: card,
      ),
    );
  }
}

/// Status badge — ALWAYS icon + text, never color-only (§57).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final DeviceStatus status;

  IconData get _icon => switch (status) {
        DeviceStatus.protected => Icons.verified_outlined,
        DeviceStatus.online => Icons.circle,
        DeviceStatus.offline => Icons.cloud_off_outlined,
        DeviceStatus.limited => Icons.warning_amber_outlined,
        DeviceStatus.lost => Icons.error_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = RetraceColors.statusColor(status);
    return Semantics(
      label: 'Status: ${status.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(RetraceRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              '● ${status.label}',
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Device overview card used on Home + Devices list.
class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.name,
    required this.meta,
    required this.status,
    required this.lastSeen,
    this.onTap,
  });

  final String name;
  final String meta;
  final DeviceStatus status;
  final String lastSeen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return RetraceCard(
      onTap: onTap,
      label: '$name, ${status.label}, $lastSeen',
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(RetraceRadius.sm),
            ),
            child: const Icon(Icons.smartphone_outlined, size: 24),
          ),
          const SizedBox(width: RetraceSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium),
                Text(meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                StatusBadge(status: status),
              ],
            ),
          ),
          const SizedBox(width: RetraceSpacing.sm),
          Flexible(
            child: Text(lastSeen,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// Map placeholder card — real tiles arrive in Phase 4 (flutter_map).
/// Never claims LIVE location before the engine exists (§19).
class MapCard extends StatelessWidget {
  const MapCard({
    super.key,
    required this.statusLine,
    this.accuracyLine,
  });

  final String statusLine;
  final String? accuracyLine;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return RetraceCard(
      label: 'Map. $statusLine',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(RetraceRadius.sm),
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              border: Border.all(color: theme.dividerColor),
            ),
            child: const Center(
              child: Icon(Icons.map_outlined, size: 40),
            ),
          ),
          const SizedBox(height: RetraceSpacing.sm),
          Text(statusLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge),
          if (accuracyLine != null)
            Text(accuracyLine!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
