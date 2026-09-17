import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/services/permission_service.dart';

/// Permission center (§15): real statuses, Granted/Limited chips,
/// tap → sheet explains why/status/risk/fix + Open Settings.
class PermissionCenterPage extends ConsumerStatefulWidget {
  const PermissionCenterPage({super.key});

  @override
  ConsumerState<PermissionCenterPage> createState() =>
      _PermissionCenterPageState();
}

class _PermissionCenterPageState extends ConsumerState<PermissionCenterPage> {
  List<PermissionState>? _states;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<PermissionState> s =
          await ref.read(permissionServiceProvider).checkAll();
      if (mounted) {
        setState(() {
          _states = s;
          _loading = false;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Protection Status'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(RetraceSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Unable to check permissions: $_error',
                            style: theme.textTheme.bodyMedium),
                        const SizedBox(height: RetraceSpacing.md),
                        RetraceButton(label: 'Retry', onPressed: _load),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(RetraceSpacing.md),
                  children: [
                    ...(_states ?? <PermissionState>[]).map(
                      (PermissionState s) => _PermissionTile(state: s),
                    ),
                    const SizedBox(height: RetraceSpacing.lg),
                    _ScoreBar(states: _states ?? <PermissionState>[]),
                    const SizedBox(height: RetraceSpacing.sm),
                    Text(
                      'Tap an item for details. Open Settings is the only honest path — RETRACE never toggles itself.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
    );
  }
}

class _PermissionTile extends ConsumerWidget {
  const _PermissionTile({required this.state});
  final PermissionState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final bool granted = state.isGranted;
    final Color c = granted ? RetraceColors.success : RetraceColors.warning;
    final String label = granted ? 'Granted' : 'Limited';
    return Card(
      margin: const EdgeInsets.only(bottom: RetraceSpacing.sm),
      child: ListTile(
        leading: Icon(
          _icon(state.permission),
          color: c,
        ),
        title: Text(state.permission.title),
        subtitle: Text('Tap for details', style: theme.textTheme.bodySmall),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(RetraceRadius.pill),
          ),
          child: Text(label,
              style: theme.textTheme.labelMedium?.copyWith(color: c)),
        ),
        onTap: () => _showSheet(context, ref, state),
      ),
    );
  }

  static IconData _icon(AppPermission p) => switch (p) {
        AppPermission.location => Icons.location_on_outlined,
        AppPermission.backgroundLocation => Icons.location_searching_outlined,
        AppPermission.notifications => Icons.notifications_outlined,
        AppPermission.camera => Icons.camera_alt_outlined,
        AppPermission.bluetooth => Icons.bluetooth_outlined,
        AppPermission.batteryOptimization => Icons.battery_charging_full_outlined,
      };

  static void _showSheet(
      BuildContext context, WidgetRef ref, PermissionState s) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) {
        final ThemeData theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(RetraceSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.permission.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(s.permission.why, style: theme.textTheme.bodyMedium),
                const SizedBox(height: RetraceSpacing.sm),
                Text('Status: ${s.status.name}',
                    style: theme.textTheme.bodySmall),
                Text(
                  s.isGranted
                      ? 'Risk if disabled: tracking/notifications may stop.'
                      : 'Risk: ${s.permission.why} Fix via Settings.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: RetraceSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: RetraceButton(
                    label: 'Open Settings',
                    onPressed: () async {
                      final ScaffoldMessengerState messenger =
                          ScaffoldMessenger.of(ctx);
                      Navigator.of(ctx).pop();
                      try {
                        await ref
                            .read(permissionServiceProvider)
                            .openSettings();
                      } on PermissionSettingsUnavailable catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(e.message)),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: RetraceSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.states});
  final List<PermissionState> states;
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int score = protectionScore(states);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Protection score', style: theme.textTheme.titleMedium),
            Text('$score%', style: theme.textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(RetraceRadius.sm),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 10,
            backgroundColor: theme.dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              score >= 80 ? RetraceColors.success : RetraceColors.warning,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('Based on real permission states only — never fake (§14).',
            style: theme.textTheme.bodySmall),
      ],
    );
  }
}
