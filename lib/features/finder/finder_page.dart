import 'dart:async';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/design_system/components/retrace_overlays.dart';
import 'package:retrace/features/finder/finder.dart';
import 'package:retrace/features/finder/finder_repository.dart';
import 'package:retrace/features/lost_mode/lost_mode.dart';
import 'package:retrace/features/notifications/notifications_controller.dart';

/// Finder page — public recovery page (§31).
/// Finder doesn't need to install RETRACE.
class FinderPage extends ConsumerStatefulWidget {
  const FinderPage({super.key, required this.recoveryId, this.session});

  final String recoveryId;
  final FinderSession? session;

  @override
  ConsumerState<FinderPage> createState() => _FinderPageState();
}

class _FinderPageState extends ConsumerState<FinderPage> {
  LostScreenData? _data;
  FinderSession? _session;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final controller = ref.read(finderControllerProvider);
      final data = await controller.getRecoveryData(widget.recoveryId);
      // A session is required to send contact/sighting. The device behind
      // a recoveryId is resolved server-side when tables land; until then
      // the session is local-first and queued (never a silent no-op).
      FinderSession? session;
      try {
        session = await controller.startSession(widget.recoveryId, '');
      } on Object {
        session = null;
      }
      if (mounted) setState(() {
        _data = data;
        _session = session ?? widget.session;
        _loading = false;
      });
    } on Object catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color onDanger = Colors.white;

    return Scaffold(
      backgroundColor: RetraceColors.danger,
      appBar: AppBar(
        backgroundColor: RetraceColors.danger,
        foregroundColor: onDanger,
        title: const Text('Device Found'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? _ErrorScreen(message: _error!, onRetry: _loadData)
              : _Content(data: _data!, session: _session),
    );
  }
}

/// Content shown to finder.
class _Content extends ConsumerWidget {
  const _Content({required this.data, this.session});

  final LostScreenData data;
  final FinderSession? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Color onDanger = Colors.white;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(RetraceSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              'DEVICE LOST',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: onDanger,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: RetraceSpacing.sm),
            Text(
              data.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: onDanger.withValues(alpha: 0.9)),
            ),
            const SizedBox(height: RetraceSpacing.lg),

            // QR Code
            Container(
              padding: const EdgeInsets.all(RetraceSpacing.lg),
              decoration: BoxDecoration(
                color: onDanger,
                borderRadius: BorderRadius.circular(RetraceRadius.lg),
              ),
              child: QrImageView(
                data: data.qrData ?? 'https://retrace.app/recover/RT-XXXXXX',
                version: QrVersions.auto,
                size: 200,
                backgroundColor: onDanger,
                foregroundColor: RetraceColors.danger,
              ),
            ),
            const SizedBox(height: RetraceSpacing.md),
            Text(
              'Scan to view recovery info',
              style: theme.textTheme.bodySmall?.copyWith(color: onDanger.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: RetraceSpacing.lg),

            // Recovery ID
            Container(
              padding: const EdgeInsets.all(RetraceSpacing.md),
              decoration: BoxDecoration(
                color: onDanger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(RetraceRadius.md),
                border: Border.all(color: onDanger.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text('Recovery ID', style: theme.textTheme.labelMedium?.copyWith(color: onDanger.withValues(alpha: 0.7))),
                  const SizedBox(height: RetraceSpacing.xs),
                  Text(
                    data.recoveryId,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: onDanger,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: RetraceSpacing.lg),

            // Contact button
            RetraceButton(
              label: 'Contact Owner',
              isDestructive: false,
              icon: Icons.email_outlined,
              onPressed: () => _showContactForm(context, ref, session),
            ),
            const SizedBox(height: RetraceSpacing.md),

            // Share location button
            RetraceButton(
              label: 'Share My Location',
              isSecondary: true,
              icon: Icons.my_location,
              onPressed: () => _shareLocation(context, ref),
            ),
            const SizedBox(height: RetraceSpacing.md),

            // What not to expose
            Text(
              'Private information (email, PIN, address) is never shown.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: onDanger.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showContactForm(BuildContext context, WidgetRef ref, FinderSession? session) async {
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Session unavailable — go back and rescan the QR code.',
          ),
        ),
      );
      return;
    }
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final messageController = TextEditingController();

    await showRetraceSheet<ContactOwnerForm>(
      context,
      semanticLabel: 'Contact Owner',
      child: Padding(
        padding: const EdgeInsets.all(RetraceSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact Owner', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: RetraceSpacing.sm),
            Text('Your info will be sent to the device owner.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: RetraceSpacing.md),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Your name', hintText: 'John Doe'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: RetraceSpacing.sm),
            TextField(
              controller: contactController,
              decoration: const InputDecoration(labelText: 'Contact (email/phone)', hintText: 'john@example.com'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: RetraceSpacing.sm),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(labelText: 'Message (optional)', hintText: 'Found your device at...'),
              maxLines: 3,
            ),
            const SizedBox(height: RetraceSpacing.md),
            RetraceButton(
              label: 'Send',
              isLoading: false,
              onPressed: () async {
                final form = ContactOwnerForm(
                  name: nameController.text.trim(),
                  contact: contactController.text.trim(),
                  message: messageController.text.trim().isEmpty ? null : messageController.text.trim(),
                );
                if (!form.isValid) return;
                if (session != null) {
                  await ref.read(finderControllerProvider).sendContact(session.id, form);
                  unawaited(
                    ref.read(notificationControllerProvider).contactSent(
                          recoveryId: data.recoveryId,
                        ),
                  );
                }
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareLocation(BuildContext context, WidgetRef ref) async {
    final FinderSession? session = this.session;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Session unavailable — go back and rescan the QR code.',
          ),
        ),
      );
      return;
    }
    ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final FinderLocation location = FinderLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        timestamp: pos.timestamp,
      );
      await ref
          .read(finderControllerProvider)
          .reportSighting(session.id, location);
      unawaited(
        ref.read(notificationControllerProvider).sightingReported(
              recoveryId: data.recoveryId,
            ),
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Location shared — queued for the owner.'),
        ),
      );
    } on Object {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not get your location. Check location permission '
            'in Protection Status and try again.',
          ),
        ),
      );
    }
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RetraceSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Provider for recovery data.
final lostScreenDataProvider = FutureProvider.family<LostScreenData, String>(
  (Ref ref, String recoveryId) async {
    return ref.watch(finderRemoteRepositoryProvider).getRecoveryData(recoveryId);
  },
);