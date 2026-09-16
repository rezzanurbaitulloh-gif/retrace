import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/data/auth/auth_user.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/features/auth/auth_controller.dart';
import 'package:retrace/features/auth/validators.dart';

/// Shared auth chrome: title, subtitle, error banner, backend-status note.
/// No social buttons until a real provider is wired (§10 — no fake login).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: RetraceSpacing.gutter(
                MediaQuery.sizeOf(context).width),
            vertical: RetraceSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title,
                  style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodyMedium),
              const SizedBox(height: RetraceSpacing.lg),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline human-readable error banner (§48). Never raw exceptions.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      label: 'Error: $message',
      child: Container(
        padding: const EdgeInsets.all(RetraceSpacing.sm),
        decoration: BoxDecoration(
          color: RetraceColors.danger.withValues(alpha: 0.12),
          border: Border.all(
              color: RetraceColors.danger.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(RetraceRadius.sm),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outlined,
                color: RetraceColors.danger),
            const SizedBox(width: RetraceSpacing.sm),
            Expanded(
              child: Text(message,
                  style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    await ref.read(authControllerProvider.notifier).signIn(
          email: _email.text.trim(),
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AuthUser?> auth = ref.watch(authControllerProvider);
    final bool loading = auth.isLoading;
    final Object? error = auth is AsyncError ? auth.error : null;
    return AuthScaffold(
      title: 'Sign In',
      subtitle: 'Welcome back. Please log in to your account.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error != null) ...[
              AuthErrorBanner(message: _message(error)),
              const SizedBox(height: RetraceSpacing.md),
            ],
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email or phone number',
                hintText: 'you@example.com',
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
                hintText: 'Enter password',
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading
                    ? null
                    : () => context.push('/recovery'),
                child: const Text('Forgot password?'),
              ),
            ),
            RetraceButton(
              label: 'Sign In',
              isLoading: loading,
              onPressed: loading ? null : _submit,
            ),
            const SizedBox(height: RetraceSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Don\'t have an account?'),
                TextButton(
                  onPressed: loading
                      ? null
                      : () => context.push('/register'),
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _message(Object error) =>
      error.toString().replaceFirst('AuthException: ', '');
}
