import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/data/security/pin_repository.dart';
import 'package:retrace/data/session/onboarding_store.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';

final pinRepositoryProvider = Provider<PinRepository>(
  (Ref ref) => PinRepository(ref.watch(preferencesStoreProvider)),
);

/// RETRACE PIN (§13) — app credential, not system lock. Hashed, rate-limited,
/// brute-force protected. UI never shows plaintext, always via secure storage.
class PinSetupPage extends ConsumerStatefulWidget {
  const PinSetupPage({super.key});

  @override
  ConsumerState<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends ConsumerState<PinSetupPage> {
  final TextEditingController _pin = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _saving = false;
  String? _error;
  bool _hasPin = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final bool has = await ref.read(pinRepositoryProvider).hasPin();
    if (mounted) {
      setState(() {
        _hasPin = has;
        _checking = false;
      });
    }
  }

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final String pin = _pin.text.trim();
    final String confirm = _confirm.text.trim();
    if (pin != confirm) {
      setState(() => _error = 'PINs do not match.');
      return;
    }
    if (pin.length < 4 || pin.length > 8 || int.tryParse(pin) == null) {
      setState(() => _error = 'PIN must be 4-8 digits.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(pinRepositoryProvider).setPin(pin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN saved securely.')),
        );
        setState(() => _hasPin = true);
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (_checking) {
      return Scaffold(
        appBar: AppBar(title: const Text('RETRACE PIN')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('RETRACE PIN')),
      body: ListView(
        padding: const EdgeInsets.all(RetraceSpacing.md),
        children: [
          Text(
            _hasPin ? 'PIN is set' : 'Set RETRACE PIN',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'This PIN is RETRACE-only (§13), not your Android lock. It is hashed, never stored plaintext, and rate-limited (5 attempts → 60s lockout).',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: RetraceSpacing.md),
          TextField(
            controller: _pin,
            decoration: const InputDecoration(
              labelText: 'New PIN (4-8 digits)',
              hintText: '••••',
            ),
            keyboardType: TextInputType.number,
            obscureText: true,
            enabled: !_saving,
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
            enabled: !_saving,
          ),
          if (_error != null) ...[
            const SizedBox(height: RetraceSpacing.sm),
            Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: RetraceSpacing.lg),
          RetraceButton(label: 'Save PIN', isLoading: _saving, onPressed: _saving ? null : _save),
          if (_hasPin) ...[
            const SizedBox(height: RetraceSpacing.sm),
            RetraceButton(
              label: 'Recovery codes',
              icon: Icons.key_outlined,
              isSecondary: true,
              onPressed: () => context.push('/pin/codes'),
            ),
            const SizedBox(height: RetraceSpacing.sm),
            RetraceButton(
              label: 'Forgot PIN? Reset with a code',
              isSecondary: true,
              onPressed: () => context.push('/pin/recovery'),
            ),
            const SizedBox(height: RetraceSpacing.sm),
            Text(
              'IMEI+PIN never equals full access (§13). Without your codes, recovery is reinstall + re-auth.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
