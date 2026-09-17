import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrace/core/security/pin_crypto.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/data/security/recovery_codes_repository.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/features/notifications/notifications_controller.dart';
import 'package:retrace/features/pin/pin_setup_page.dart';

/// Forgotten-PIN flow (§41): burn one recovery code, then set a new PIN.
/// Route: /pin/recovery. Wrong codes count toward the same 5-attempt/60s
/// lockout as the PIN, and a burned code can never be reused.
class PinRecoveryPage extends ConsumerStatefulWidget {
  const PinRecoveryPage({super.key});

  @override
  ConsumerState<PinRecoveryPage> createState() => _PinRecoveryPageState();
}

class _PinRecoveryPageState extends ConsumerState<PinRecoveryPage> {
  final TextEditingController _code = TextEditingController();
  final TextEditingController _pin = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _codeAccepted = false;
  bool _working = false;
  String? _error;
  String? _lockMessage;

  @override
  void dispose() {
    _code.dispose();
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _working = true;
      _error = null;
      _lockMessage = null;
    });
    try {
      final RecoveryCodesRepository repo =
          ref.read(recoveryCodesRepositoryProvider);
      if (await repo.isLocked()) {
        final Duration? rem = await repo.lockRemaining();
        if (mounted) {
          setState(() {
            _lockMessage = rem == null
                ? 'Too many attempts — try again shortly.'
                : 'Too many attempts — try again in ${rem.inSeconds}s.';
            _working = false;
          });
        }
        return;
      }
      final bool ok = await repo.verifyAndBurn(_code.text);
      if (!mounted) return;
      if (ok) {
        final int remaining = await repo.remainingCount();
        unawaited(
          ref.read(notificationControllerProvider).lastCodeWarning(
                remaining: remaining,
              ),
        );
        setState(() {
          _codeAccepted = true;
          _working = false;
        });
      } else {
        if (await repo.isLocked()) {
          final Duration? rem = await repo.lockRemaining();
          setState(() {
            _lockMessage = rem == null
                ? 'Too many attempts — try again shortly.'
                : 'Too many attempts — try again in ${rem.inSeconds}s.';
          });
        } else {
          setState(() => _error = 'That code is not valid. Check it and try again.');
        }
        setState(() => _working = false);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _working = false;
        });
      }
    }
  }

  Future<void> _setNewPin() async {
    FocusScope.of(context).unfocus();
    final String pin = _pin.text.trim();
    if (!PinCrypto.isValidPin(pin)) {
      setState(() => _error = 'PIN must be 4-8 digits.');
      return;
    }
    if (pin != _confirm.text.trim()) {
      setState(() => _error = 'PINs do not match.');
      return;
    }
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await ref.read(pinRepositoryProvider).setPin(pin);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New PIN saved securely.')),
      );
      context.go('/pin');
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('ArgumentError: ', '');
          _working = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reset PIN')),
      body: ListView(
        padding: const EdgeInsets.all(RetraceSpacing.md),
        children: <Widget>[
          Text(
            _codeAccepted ? 'Set a new PIN' : 'Use a recovery code',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            _codeAccepted
                ? 'Your code was accepted and burned. Choose a new PIN.'
                : 'Enter one of the 8 recovery codes you wrote down. '
                    'It will be burned after this reset.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: RetraceSpacing.md),
          if (!_codeAccepted) ...<Widget>[
            TextField(
              controller: _code,
              decoration: const InputDecoration(
                labelText: 'Recovery code',
                hintText: 'XXXX-XXXX',
              ),
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enabled: !_working,
              onSubmitted: (_) => _submitCode(),
            ),
          ] else ...<Widget>[
            TextField(
              controller: _pin,
              decoration: const InputDecoration(
                labelText: 'New PIN (4-8 digits)',
                hintText: '••••',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              enabled: !_working,
            ),
            const SizedBox(height: RetraceSpacing.sm),
            TextField(
              controller: _confirm,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                hintText: '••••',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              enabled: !_working,
            ),
          ],
          if (_error != null) ...<Widget>[
            const SizedBox(height: RetraceSpacing.sm),
            Text(_error!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.error)),
          ],
          if (_lockMessage != null) ...<Widget>[
            const SizedBox(height: RetraceSpacing.sm),
            Text(_lockMessage!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: RetraceSpacing.lg),
          RetraceButton(
            label: _codeAccepted ? 'Save new PIN' : 'Verify code',
            isLoading: _working,
            onPressed:
                _working ? null : (_codeAccepted ? _setNewPin : _submitCode),
          ),
        ],
      ),
    );
  }
}
