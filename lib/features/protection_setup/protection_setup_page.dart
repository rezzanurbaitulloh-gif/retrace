import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/services/permission_service.dart';

/// Setup wizard (§14): Location, Notifications, Background location, Network,
/// Battery optimization, Camera, Bluetooth + Protection Score from real states.
class ProtectionSetupPage extends ConsumerStatefulWidget {
  const ProtectionSetupPage({super.key});

  @override
  ConsumerState<ProtectionSetupPage> createState() =>
      _ProtectionSetupPageState();
}

class _ProtectionSetupPageState extends ConsumerState<ProtectionSetupPage> {
  List<PermissionState>? _states;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<PermissionState> s =
        await ref.read(permissionServiceProvider).checkAll();
    if (mounted) {
      setState(() {
        _states = s;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Protection Setup')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(RetraceSpacing.md),
              children: [
                Text('Enable protection', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'RETRACE works best when these are enabled. Each item shows its real state.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: RetraceSpacing.md),
                ...(_states ?? <PermissionState>[]).map(
                  (PermissionState s) {
                    final bool ok = s.isGranted;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        ok ? Icons.check_circle : Icons.warning_amber_outlined,
                        color: ok ? RetraceColors.success : RetraceColors.warning,
                      ),
                      title: Text(s.permission.title),
                      subtitle: Text(ok ? '✓ Enabled' : '⚠ Needs attention',
                          style: theme.textTheme.bodySmall),
                    );
                  },
                ),
                const SizedBox(height: RetraceSpacing.md),
                _Score(states: _states ?? <PermissionState>[]),
                const SizedBox(height: RetraceSpacing.md),
                RetraceButton(
                  label: 'Open Permission Center',
                  onPressed: () => context.push('/permissions'),
                ),
                const SizedBox(height: RetraceSpacing.sm),
                RetraceButton(
                  label: 'Done',
                  isSecondary: true,
                  onPressed: () => context.pop(),
                ),
              ],
            ),
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({required this.states});
  final List<PermissionState> states;
  @override
  Widget build(BuildContext context) {
    final int score = protectionScore(states);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Protection Score  $score%',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: score / 100,
          minHeight: 8,
          backgroundColor: Theme.of(context).dividerColor,
          valueColor: AlwaysStoppedAnimation<Color>(
            score >= 80 ? RetraceColors.success : RetraceColors.warning,
          ),
        ),
      ],
    );
  }
}
