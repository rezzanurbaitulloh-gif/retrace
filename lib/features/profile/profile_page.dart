import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrace/app/theme_controller.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/data/auth/auth_user.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/design_system/components/retrace_overlays.dart';
import 'package:retrace/features/auth/auth_controller.dart';

/// Profile shell (§6). Account/Appearance/Security/Support are live;
/// sections not yet built show an honest "coming soon" sheet instead of a
/// dead button or a fake screen — never a placeholder page (§50 no-fake).
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AuthUser? user =
        ref.watch(authControllerProvider).valueOrNull;
    final ThemeMode mode = ref.watch(themeModeProvider);
    final String email = user?.email ?? '';
    final String initial =
        email.isEmpty ? '?' : email[0].toUpperCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(RetraceSpacing.md),
        children: [
          Row(
            children: [
              CircleAvatar(radius: 28, child: Text(initial)),
              const SizedBox(width: RetraceSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: RetraceSpacing.lg),
          Text('Account', style: theme.textTheme.titleMedium),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Email'),
            subtitle: Text(email,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const Divider(height: 1),
          const SizedBox(height: RetraceSpacing.md),
          Text('Appearance', style: theme.textTheme.titleMedium),
          const SizedBox(height: RetraceSpacing.sm),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined)),
              ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined)),
            ],
            selected: <ThemeMode>{mode},
            onSelectionChanged: (Set<ThemeMode> s) =>
                ref.read(themeModeProvider.notifier).setMode(s.first),
          ),
          Text('Security', style: theme.textTheme.titleMedium),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_outlined),
            title: const Text('RETRACE PIN'),
            subtitle: const Text('Hashed, rate-limited — tap to set (Phase 3 live)'),
            trailing: const Icon(Icons.chevron_right_outlined),
            onTap: () => context.push('/pin'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Recovery'),
            subtitle: const Text('PIN recovery codes & account fallback',
                maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right_outlined),
            onTap: () => context.push('/pin/codes'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.group_outlined),
            title: const Text('Trusted Contacts'),
            subtitle: const Text('Emergency / Recovery / Location scopes',
                maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right_outlined),
            onTap: () => context.push('/trusted-contacts'),
          ),
          const Divider(height: 1),
          const SizedBox(height: RetraceSpacing.md),
          Text('Preferences', style: theme.textTheme.titleMedium),
          const _UpcomingTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Categories + deep links (Phase 10)',
            sheetTitle: 'Notifications',
            sheetBody:
                'Push + local notifications with deep links are Phase 10. The current build shows no fake notifications.',
          ),
          const _UpcomingTile(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'English · Indonesian ready (Phase 2 shell)',
            sheetTitle: 'Language',
            sheetBody:
                'Architecture is localization-ready (en/id). Full language switch ships with the next content phase — no string is hardcoded without a l10n path.',
          ),
          const SizedBox(height: RetraceSpacing.md),
          Text('Support', style: theme.textTheme.titleMedium),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outlined),
            title: const Text('About RETRACE'),
            subtitle:
                const Text('Find. Protect. Recover.'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'RETRACE',
              applicationLegalese:
                  'Advanced device tracking and recovery.',
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                const Icon(Icons.description_outlined),
            title: const Text('Open-source licenses'),
            onTap: () => showLicensePage(context: context),
          ),
          const SizedBox(height: RetraceSpacing.lg),
          RetraceButton(
            label: 'Sign Out',
            isSecondary: true,
            icon: Icons.logout_outlined,
            onPressed: () async {
              final bool ok = await ConfirmationDialog.show(
                context,
                title: 'Sign out?',
                explanation:
                    'You will need your email and password to sign back in on this device.',
                confirmLabel: 'Sign Out',
              );
              if (ok) {
                await ref
                    .read(authControllerProvider.notifier)
                    .signOut();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.sheetTitle,
    required this.sheetBody,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String sheetTitle;
  final String sheetBody;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle,
          maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(RetraceRadius.pill),
        ),
        child: Text('Soon',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.primary)),
      ),
      onTap: () => showRetraceSheet<void>(
        context,
        semanticLabel: sheetTitle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sheetTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: RetraceSpacing.sm),
            Text(sheetBody, style: theme.textTheme.bodyMedium),
            const SizedBox(height: RetraceSpacing.md),
            SizedBox(
              width: double.infinity,
              child: RetraceButton(
                label: 'Got it',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
