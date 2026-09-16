import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/data/session/preferences_store.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/features/auth/auth_controller.dart';
import 'package:retrace/features/auth/login_page.dart';
import 'package:retrace/features/auth/validators.dart';

/// Password recovery: request reset link → honest success state.
/// Session expiry surfaces here too — an expired session lands on /login
/// with the recovery path one tap away (§10).
class RecoveryPage extends ConsumerStatefulWidget {
  const RecoveryPage({super.key});

  @override
  ConsumerState<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends ConsumerState<RecoveryPage> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .sendPasswordReset(email: _email.text.trim());
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Object {
      if (mounted) {
        setState(() => _error =
            'Unable to send the reset link. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return AuthScaffold(
        title: 'Check your inbox',
        subtitle:
            'If an account exists for ${_email.text.trim()}, a reset link is on its way.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.mark_email_read_outlined,
                size: 56, color: RetraceColors.success),
            const SizedBox(height: RetraceSpacing.md),
            RetraceButton(
              label: 'Back to Sign In',
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
      );
    }
    return AuthScaffold(
      title: 'Reset Password',
      subtitle: 'Enter your account email to receive a reset link.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              AuthErrorBanner(message: _error!),
              const SizedBox(height: RetraceSpacing.md),
            ],
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email address',
                hintText: 'you@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enabled: !_loading,
              validator: (String? v) =>
                  Validators.email(v ?? ''),
            ),
            const SizedBox(height: RetraceSpacing.md),
            RetraceButton(
              label: 'Send Reset Link',
              isLoading: _loading,
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
