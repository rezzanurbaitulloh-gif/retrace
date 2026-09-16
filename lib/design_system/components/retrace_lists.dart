import 'package:flutter/material.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';

/// Timeline row for Activity (§37). Icon-dot + title + timestamp.
class ActivityItem extends StatelessWidget {
  const ActivityItem({
    super.key,
    required this.icon,
    required this.title,
    required this.timestamp,
    this.subtitle,
    this.tone,
  });

  final IconData icon;
  final String title;
  final String timestamp;
  final String? subtitle;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color dot = tone ?? theme.colorScheme.primary;
    return Semantics(
      label: '$title, $timestamp',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dot.withValues(alpha: 0.14),
            ),
            child: Icon(icon, size: 18, color: dot),
          ),
          const SizedBox(width: RetraceSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium),
                if (subtitle != null)
                  Text(subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: RetraceSpacing.sm),
          Text(timestamp,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Permission row — real status + Granted/Limited badge (§15).
class PermissionItem extends StatelessWidget {
  const PermissionItem({
    super.key,
    required this.icon,
    required this.title,
    required this.granted,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool granted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color =
        granted ? RetraceColors.success : RetraceColors.warning;
    final String state = granted ? 'Granted' : 'Limited';
    return Semantics(
      button: true,
      label: '$title permission, $state. Tap for details.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RetraceRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: RetraceSpacing.sm),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: RetraceSpacing.sm),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius:
                      BorderRadius.circular(RetraceRadius.pill),
                ),
                child: Text(state,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: color)),
              ),
              const Icon(Icons.chevron_right_outlined, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trusted contact row with permission-scope label (§40).
class TrustedContactCard extends StatelessWidget {
  const TrustedContactCard({
    super.key,
    required this.name,
    required this.scope,
    this.onTap,
  });

  final String name;
  final String scope;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        minVerticalPadding: RetraceSpacing.sm,
        leading: CircleAvatar(
          child: Text(
            name.isEmpty ? '?' : name[0].toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        ),
        title: Text(name,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(scope,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right_outlined),
      ),
    );
  }
}
