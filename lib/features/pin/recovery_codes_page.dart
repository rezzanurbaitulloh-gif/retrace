import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/data/security/recovery_codes_repository.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/design_system/components/retrace_overlays.dart';
import 'package:retrace/design_system/components/retrace_states.dart';

/// Recovery codes (§41 codes leg): one-time display after generation,
/// single-use burn on verify, regenerate invalidates the old batch.
/// Route: /pin/codes. Requires the device PIN to already be set — codes
/// are the fallback for a forgotten PIN, not a second credential.
class RecoveryCodesPage extends ConsumerStatefulWidget {
  const RecoveryCodesPage({super.key});

  @override
  ConsumerState<RecoveryCodesPage> createState() => _RecoveryCodesPageState();
}

class _RecoveryCodesPageState extends ConsumerState<RecoveryCodesPage> {
  bool _checking = true;
  bool _working = false;
  int _remaining = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final int n =
        await ref.read(recoveryCodesRepositoryProvider).remainingCount();
    if (mounted) {
      setState(() {
        _remaining = n;
        _checking = false;
      });
    }
  }

  Future<void> _generate({required bool isRegenerate}) async {
    if (isRegenerate) {
      final bool ok = await ConfirmationDialog.show(
        context,
        title: 'Generate new codes?',
        explanation:
            'This invalidates all unused codes immediately. Only do this '
            'if the old codes are lost or may be compromised.',
        confirmLabel: 'Generate new',
      );
      if (!ok) return;
    }
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final List<String> codes =
          await ref.read(recoveryCodesRepositoryProvider).generateCodes();
      if (!mounted) return;
      setState(() => _working = false);
      await _showOnce(codes);
      await _refresh();
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _working = false;
        });
      }
    }
  }

  /// One-time display. Codes are never stored as plaintext and cannot be
  /// re-shown — the sheet is the only chance to write them down.
  Future<void> _showOnce(List<String> codes) {
    bool acknowledged = false;
    return showRetraceSheet<void>(
      context,
      semanticLabel: 'Your recovery codes — write them down',
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheet) {
          final ThemeData theme = Theme.of(context);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('Write these down now',
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Each code works once to reset a forgotten PIN, then it '
                'burns. They will never be shown again.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: RetraceSpacing.sm),
              Container(
                padding: const EdgeInsets.all(RetraceSpacing.sm),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius:
                      BorderRadius.circular(RetraceRadius.md),
                ),
                child: Column(
                  children: <Widget>[
                    for (final String c in codes)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          c,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "I've written them down somewhere safe",
                  style: theme.textTheme.bodyMedium,
                ),
                value: acknowledged,
                onChanged: (bool? v) =>
                    setSheet(() => acknowledged = v ?? false),
              ),
              RetraceButton(
                label: 'Done',
                onPressed: acknowledged
                    ? () => Navigator.of(context).pop()
                    : null,
              ),
              const SizedBox(height: RetraceSpacing.sm),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (_checking) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recovery Codes')),
        body: const LoadingState(message: 'Checking codes…'),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Codes')),
      body: ListView(
        padding: const EdgeInsets.all(RetraceSpacing.md),
        children: <Widget>[
          Text(
            _remaining == 0 ? 'No codes yet' : '$_remaining of 8 codes left',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Recovery codes reset a forgotten RETRACE PIN. Each code is '
            'single-use and verified against hashes on this device — '
            'nothing leaves the phone.',
            style: theme.textTheme.bodyMedium,
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: RetraceSpacing.sm),
            Text(_error!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: RetraceSpacing.lg),
          RetraceButton(
            label: _remaining == 0 ? 'Generate codes' : 'Generate new codes',
            icon: Icons.key_outlined,
            isLoading: _working,
            onPressed: _working
                ? null
                : () => _generate(isRegenerate: _remaining > 0),
          ),
          if (_remaining > 0) ...<Widget>[
            const SizedBox(height: RetraceSpacing.sm),
            Text(
              'Generating new codes invalidates every unused code right away.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
