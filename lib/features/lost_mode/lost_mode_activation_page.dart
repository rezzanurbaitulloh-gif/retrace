import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/design_system/components/retrace_overlays.dart';
import 'package:retrace/features/auth/auth_controller.dart';
import 'package:retrace/features/lost_mode/lost_mode.dart';
import 'package:retrace/features/lost_mode/lost_mode_repository.dart';

/// Lost Mode activation with confirmation (§23).
class LostModeActivationPage extends ConsumerStatefulWidget {
  const LostModeActivationPage({super.key, required this.deviceId, required this.deviceName});

  final String deviceId;
  final String deviceName;

  @override
  ConsumerState<LostModeActivationPage> createState() => _LostModeActivationPageState();
}

class _LostModeActivationPageState extends ConsumerState<LostModeActivationPage> {
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Activate Lost Mode')),
      body: Padding(
        padding: const EdgeInsets.all(RetraceSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning icon
            Container(
              padding: const EdgeInsets.all(RetraceSpacing.lg),
              decoration: BoxDecoration(
                color: RetraceColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(RetraceRadius.lg),
                border: Border.all(color: RetraceColors.danger.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 48, color: RetraceColors.danger),
                  const SizedBox(height: RetraceSpacing.md),
                  Text(
                    'Mark ${widget.deviceName} as lost?',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(color: RetraceColors.danger),
                  ),
                  const SizedBox(height: RetraceSpacing.sm),
                  Text(
                    'RETRACE will:\n'
                    '• Increase tracking priority\n'
                    '• Enable recovery state\n'
                    '• Prepare remote commands\n'
                    '• Display recovery information',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: RetraceSpacing.lg),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(RetraceSpacing.md),
                decoration: BoxDecoration(
                  color: RetraceColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(RetraceRadius.md),
                  border: Border.all(color: RetraceColors.danger.withValues(alpha: 0.3)),
                ),
                child: Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: RetraceColors.danger)),
              ),
              const SizedBox(height: RetraceSpacing.md),
            ],
            RetraceButton(
              label: 'Activate Lost Mode',
              isDestructive: true,
              isLoading: _loading,
              onPressed: _loading ? null : _activate,
            ),
            const SizedBox(height: RetraceSpacing.sm),
            RetraceButton(
              label: 'Cancel',
              isSecondary: true,
              onPressed: _loading ? null : () => context.pop(),
            ),
            const SizedBox(height: RetraceSpacing.lg),
            Text(
              'This will enable recovery mode on the device. You can deactivate from the device detail page.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _activate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await ref.read(lostModeControllerProvider).activate(
        widget.deviceId,
        ref.read(authControllerProvider).valueOrNull?.email ?? 'unknown',
      );
      if (mounted) {
        context.go('/devices/${widget.deviceId}/lost', extra: info);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}