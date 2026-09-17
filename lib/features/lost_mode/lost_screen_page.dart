import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:retrace/core/theme/retrace_colors.dart'
    show RetraceColors;
import 'package:retrace/core/theme/retrace_spacing.dart'
    show RetraceSpacing, RetraceRadius;
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/features/lost_mode/lost_mode.dart'
    show LostScreenData;
import 'package:retrace/features/lost_mode/lost_mode_repository.dart';

/// Lost Screen — shown on lost device or via QR (§30).
/// No finder auth required — public recovery info only.
class LostScreenPage extends ConsumerWidget {
  const LostScreenPage({super.key, required this.recoveryId});

  final String recoveryId;

@override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<LostScreenData> data = ref.watch(lostScreenDataProvider(recoveryId));

    Widget child;
    if (data is AsyncLoading) {
      child = const Center(child: CircularProgressIndicator(color: Colors.white));
    } else if (data is AsyncError) {
      child = _ErrorScreen(
        message: 'Unable to load recovery info: ${data.error.toString().replaceFirst('Exception: ', '')}',
        onRetry: () => ref.invalidate(lostScreenDataProvider(recoveryId)),
      );
    } else if (data is AsyncData<LostScreenData>) {
      child = _Content(data: data.value);
    } else {
      child = const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: RetraceColors.danger,
      body: SafeArea(child: child),
    );
  }
}

/// Content shown to finder.
class _Content extends StatelessWidget {
  const _Content({required this.data});

  final LostScreenData data;

  @override
  Widget build(BuildContext context) {
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
              'If you\'ve found this device,\nplease help return it.',
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
                    'RT-XXXXXX',
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
              onPressed: () => _launchContact(context, data.contactUrl),
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

  Future<void> _launchContact(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
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
        padding: const EdgeInsets.all(32),
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

/// Provider for lost screen data.
final lostScreenDataProvider = FutureProvider.family<LostScreenData, String>(
  (Ref ref, String recoveryId) async {
    return ref.watch(lostModeRemoteRepositoryProvider).getLostScreenData(recoveryId);
  },
);