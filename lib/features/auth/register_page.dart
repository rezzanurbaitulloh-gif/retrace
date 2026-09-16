import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/data/auth/auth_user.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/features/auth/auth_controller.dart';
import 'package:retrace/features/auth/login_page.dart';
import 'package:retrace/features/auth/validators.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;
  bool _verificationSent = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    await ref.read(authControllerProvider.notifier).signUp(
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
    // Email-confirmation projects return no session: say so honestly
    // instead of pretending the user is signed in.
    if (mounted &&
        ref.read(authControllerProvider).valueOrNull == null &&
        ref.read(authControllerProvider) is AsyncData<AuthUser?>) {
      setState(() => _verificationSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<AuthUser?> auth = ref.watch(authControllerProvider);
    final bool loading = auth.isLoading;
    final Object? error = auth is AsyncError ? auth.error : null;
    if (_verificationSent) {
      return AuthScaffold(
        title: 'Check your inbox',
        subtitle:
            'We created your account. Verify your email, then sign in.',
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
      title: 'Create Account',
      subtitle: 'Join RETRACE today.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error != null) ...[
              AuthErrorBanner(
                message: error
                    .toString()
                    .replaceFirst('AuthException: ', ''),
              ),
              const SizedBox(height: RetraceSpacing.md),
            ],
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Full name',
                hintText: 'Rezza Nur Baitulloh',
              ),
              textCapitalization: TextCapitalization.words,
              enabled: !loading,
              validator: (String? v) =>
                  Validators.fullName(v ?? ''),
            ),
            const SizedBox(height: RetraceSpacing.sm),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email address',
                hintText: 'reza@gmail.com',
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enabled: !loading,
              validator: (String? v) =>
                  Validators.email(v ?? ''),
            ),
            const SizedBox(height: RetraceSpacing.sm),
            TextFormField(
              controller: _password,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'At least 8 characters',
                suffixIcon: IconButton(
                  tooltip:
                      _obscure ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                ),
              ),
              obscureText: _obscure,
              enabled: !loading,
              validator: (String? v) =>
                  Validators.password(v ?? ''),
            ),
            const SizedBox(height: RetraceSpacing.md),
            Text(
              'Only the data needed to protect your devices is collected (§11).',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: RetraceSpacing.sm),
            RetraceButton(
              label: 'Create Account',
              isLoading: loading,
              onPressed: loading ? null : _submit,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account?'),
                TextButton(
                  onPressed:
                      loading ? null : () => context.pop(),
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
