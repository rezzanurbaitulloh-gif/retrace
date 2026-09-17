import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/core/theme/retrace_spacing.dart'
    show RetraceSpacing, RetraceRadius;
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/design_system/components/retrace_overlays.dart';
import 'package:retrace/features/auth/auth_controller.dart';
import 'package:retrace/features/lost_mode/lost_mode.dart';
import 'package:retrace/features/lost_mode/lost_mode_repository.dart';
import 'package:retrace/features/notifications/notifications_controller.dart';

/// Lost Mode screen — recovery command center (§24).
class LostModeScreen extends ConsumerStatefulWidget {
  const LostModeScreen({super.key, required this.info});

  final LostModeInfo info;

  @override
  ConsumerState<LostModeScreen> createState() => _LostModeScreenState();
}

class _LostModeScreenState extends ConsumerState<LostModeScreen> {
  LostModeInfo _info = LostModeInfo(
    deviceId: '',
    state: LostModeState.inactive,
    activatedAt: DateTime.now(),
  );
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _info = widget.info;
  }

@override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    final Widget scaffold = Scaffold(
      appBar: AppBar(
        title: const Text('DEVICE LOST'),
        backgroundColor: RetraceColors.danger,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Deactivate Lost Mode',
            onPressed: _loading ? null : _confirmDeactivate,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView(
              padding: const EdgeInsets.all(RetraceSpacing.md),
              children: [
                // Status header
                Container(
                  padding: const EdgeInsets.all(RetraceSpacing.lg),
                  decoration: BoxDecoration(
                    color: RetraceColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(RetraceRadius.lg),
                    border: Border.all(color: RetraceColors.danger.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 48, color: RetraceColors.danger),
                      const SizedBox(height: RetraceSpacing.sm),
                      Text(
                        'Tracking is active',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: RetraceSpacing.xs),
                      Text(
                        'Last update: ${_formatTime(DateTime.now())}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: RetraceSpacing.lg),

                // Device status
                Text('Device Status', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: RetraceSpacing.sm),
                _StatusRow(label: 'Battery', value: 'Unknown', icon: Icons.battery_unknown),
                _StatusRow(label: 'Network', value: 'Unknown', icon: Icons.wifi_off),
                _StatusRow(label: 'Last Location', value: 'Not available', icon: Icons.location_off),
                _StatusRow(label: 'Last Update', value: _formatTime(_info.activatedAt), icon: Icons.access_time),
                const SizedBox(height: RetraceSpacing.lg),

                // Recovery actions
                Text('Recovery Actions', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: RetraceSpacing.sm),
                ..._buildActionButtons(context),

                const SizedBox(height: RetraceSpacing.lg),

                // Finder info
                const _FinderInfoCard(),

                const SizedBox(height: RetraceSpacing.lg),

                // Deactivate button
                RetraceButton(
                  label: 'Deactivate Lost Mode',
                  isSecondary: true,
                  onPressed: _loading ? null : _confirmDeactivate,
                ),
              ],
            ),
          );
    return scaffold;
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {'type': CommandType.ring, 'icon': Icons.volume_up, 'label': 'Ring', 'subtitle': 'Play sound at max volume', 'supported': true},
      {'type': CommandType.vibrate, 'icon': Icons.vibration, 'label': 'Vibrate', 'subtitle': 'Trigger vibration', 'supported': true},
      {'type': CommandType.lock, 'icon': Icons.lock, 'label': 'Lock', 'subtitle': 'Lock with RETRACE PIN', 'supported': true},
      {'type': CommandType.showLostScreen, 'icon': Icons.phone_android, 'label': 'Show Lost Screen', 'subtitle': 'Display recovery info on device', 'supported': true},
      {'type': CommandType.captureEvidence, 'icon': Icons.camera_alt, 'label': 'Capture Evidence', 'subtitle': 'Take photo (platform limited)', 'supported': false},
      {'type': CommandType.requestLocation, 'icon': Icons.my_location, 'label': 'Request Location', 'subtitle': 'Force location update', 'supported': true},
    ];

    final List<Widget> widgets = [];
    for (final a in actions) {
      final bool supported = a['supported'] as bool;
      final String effectiveSubtitle = supported ? a['subtitle'] as String : '${a['subtitle'] as String} (Limited)';
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: RetraceSpacing.sm),
          child: CommandButton(
            icon: a['icon'] as IconData,
            label: a['label'] as String,
            sublabel: supported ? a['subtitle'] as String : '${a['subtitle'] as String} (Limited)',
            onPressed: supported ? () => _sendCommand(a['type'] as CommandType) : null,
          ),
        ),
      );
    }
    return widgets;
  }

  Future<void> _sendCommand(CommandType type) async {
    setState(() => _loading = true);
    try {
      final command = RemoteCommand(
        id: 'cmd_${DateTime.now().millisecondsSinceEpoch}',
        deviceId: widget.info.deviceId,
        type: type,
        status: CommandStatus.pending,
        createdAt: DateTime.now(),
        requestedBy: ref.read(authControllerProvider).valueOrNull?.email ?? 'unknown',
      );
      final RemoteCommand sent =
          await ref.read(lostModeControllerProvider).sendCommand(command);
      unawaited(
        ref.read(notificationControllerProvider).commandStatus(
              command: sent,
              delivered: sent.status != CommandStatus.pending,
            ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type.label} command sent')),
        );
      }
    } on Object catch (e) {
      if (mounted) {
        // Error handling could be added here
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDeactivate() async {
    final bool ok = await ConfirmationDialog.show(
      context,
      title: 'Deactivate Lost Mode?',
      explanation: 'This will stop enhanced tracking and recovery mode for this device.',
      confirmLabel: 'Deactivate',
      isDestructive: false,
    );
    if (!ok) return;

    setState(() => _loading = true);
    try {
      final info = await ref.read(lostModeControllerProvider).deactivate(
        widget.info.deviceId,
        ref.read(authControllerProvider).valueOrNull?.email ?? 'unknown',
      );
      if (mounted) {
        context.go('/devices/${widget.info.deviceId}');
      }
    } on Object catch (e) {
      // Error handling could be added here
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatTime(DateTime dt) {
    final Duration d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

/// Simple status row for lost mode screen.
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

/// Finder info card.
class _FinderInfoCard extends StatelessWidget {
  const _FinderInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text('Finder Information', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'If someone finds the device, they can scan the QR code or visit the recovery URL to see this information and contact you.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text('Recovery ID: RT-XXXXXX', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Text(
              'DEVICE LOST\n\nIf you\'ve found this device, please help return it.\n\n[ Contact Owner ]\n\nRecovery ID\nRT-XXXXXX\n\n[ QR ]',
              style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}