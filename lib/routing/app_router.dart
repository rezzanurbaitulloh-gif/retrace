import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrace/app/bootstrap.dart';
import 'package:retrace/app/design_gallery.dart';
import 'package:retrace/data/auth/auth_user.dart';
import 'package:retrace/data/session/onboarding_store.dart';
import 'package:retrace/features/evidence/evidence_page.dart';
import 'package:retrace/features/pin/pin_recovery_page.dart';
import 'package:retrace/features/pin/recovery_codes_page.dart';
import 'package:retrace/features/trusted_contacts/trusted_contacts_page.dart';
import 'package:retrace/features/lost_mode/lost_mode.dart';
import 'package:retrace/features/finder/finder_page.dart';
import 'package:retrace/features/finder/qr_scanner_page.dart';
import 'package:retrace/features/lost_mode/lost_mode_activation_page.dart';
import 'package:retrace/features/lost_mode/lost_mode_screen.dart';
import 'package:retrace/features/lost_mode/lost_screen_page.dart';
import 'package:retrace/features/activity/activity_page.dart';
import 'package:retrace/features/auth/auth_controller.dart';
import 'package:retrace/features/auth/login_page.dart';
import 'package:retrace/features/auth/recovery_page.dart';
import 'package:retrace/features/auth/register_page.dart';
import 'package:retrace/features/device_registration/device_registration_page.dart';
import 'package:retrace/features/devices/device_detail_page.dart';
import 'package:retrace/features/devices/devices_page.dart';
import 'package:retrace/features/home/home_page.dart';
import 'package:retrace/features/map/live_map_page.dart';
import 'package:retrace/features/map/location_history_page.dart';
import 'package:retrace/features/onboarding/onboarding_page.dart';
import 'package:retrace/features/permissions/permission_center_page.dart';
import 'package:retrace/features/pin/pin_setup_page.dart';
import 'package:retrace/features/profile/profile_page.dart';
import 'package:retrace/features/protection_setup/protection_setup_page.dart';
import 'package:retrace/features/splash/splash_page.dart';

/// Routes a signed-out visitor may open without an account: auth screens
/// plus everything browseable — shell tabs, device views, maps, and the
/// public finder/lost screens (a finder never has an account).
const List<String> guestRoutes = <String>[
  '/splash',
  '/onboarding',
  '/login',
  '/register',
  '/recovery',
  '/design-system',
];

/// Routes that *do* something account-bound — creating, commanding,
/// capturing, or secret-bearing. Guests hitting these land on /login.
/// Everything else is explorable without an account.
bool requiresAuth(String location) {
  if (location == '/devices/new') return true;
  if (location == '/trusted-contacts') return true;
  if (location == '/pin' || location.startsWith('/pin/')) return true;
  if (RegExp(r'^/devices/[^/]+/(lost/activate|evidence)$')
      .hasMatch(location)) {
    return true;
  }
  return false;
}

/// All Phase 2 routes (§75 shell subset). Command/lost/finder/evidence/
/// trusted/recovery routes are added by their phases — never as stubs.
/// Only [requiresAuth] routes bounce guests to /login; the rest of the app
/// is explorable first, account only when using features.
final routerProvider = Provider<GoRouter>((Ref ref) {
  final ValueNotifier<int> refresh = ValueNotifier<int>(0);
  void bump() => refresh.value++;
  final ProviderSubscription<AsyncValue<void>> subBoot =
      ref.listen<AsyncValue<void>>(
          bootstrapProvider,
          // ignore: unnecessary_underscores
          (_, __) => bump());
  final ProviderSubscription<AsyncValue<AuthUser?>> subAuth =
      ref.listen<AsyncValue<AuthUser?>>(
          authControllerProvider,
          // ignore: unnecessary_underscores
          (_, __) => bump());
  ref.onDispose(() {
    subBoot.close();
    subAuth.close();
    refresh.dispose();
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState gs) {
      final AsyncValue<void> boot = ref.read(bootstrapProvider);
      final String loc = gs.matchedLocation;
      if (boot.isLoading || boot.hasError) {
        return loc == '/splash' ? null : '/splash';
      }
      final bool seen = ref.read(onboardingSeenProvider);
      if (!seen) {
        return loc == '/onboarding' ? null : '/onboarding';
      }
      final AuthUser? user =
          ref.read(authControllerProvider).valueOrNull;
      if (user == null) {
        if (guestRoutes.contains(loc)) {
          // Returning guests land in the shell as guests — sign-in
          // happens at the first account-bound feature, not at launch.
          return loc == '/splash' ? '/home' : null;
        }
        if (requiresAuth(loc)) return '/login';
        return null;
      }
      if (guestRoutes.contains(loc)) return '/home';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState s) =>
            const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState s) =>
            const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState s) =>
            const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (BuildContext context, GoRouterState s) =>
            const RegisterPage(),
      ),
      GoRoute(
        path: '/recovery',
        builder: (BuildContext context, GoRouterState s) =>
            const RecoveryPage(),
      ),
      GoRoute(
        path: '/design-system',
        builder: (BuildContext context, GoRouterState s) =>
            const DesignGalleryPage(),
      ),
      GoRoute(
        path: '/devices/new',
        builder: (BuildContext context, GoRouterState s) =>
            const DeviceRegistrationPage(),
      ),
      GoRoute(
        path: '/permissions',
        builder: (BuildContext context, GoRouterState s) =>
            const PermissionCenterPage(),
      ),
      GoRoute(
        path: '/protection-setup',
        builder: (BuildContext context, GoRouterState s) =>
            const ProtectionSetupPage(),
      ),
      GoRoute(
        path: '/pin',
        builder: (BuildContext context, GoRouterState s) =>
            const PinSetupPage(),
      ),
      GoRoute(
        path: '/pin/codes',
        builder: (BuildContext context, GoRouterState s) =>
            const RecoveryCodesPage(),
      ),
      GoRoute(
        path: '/pin/recovery',
        builder: (BuildContext context, GoRouterState s) =>
            const PinRecoveryPage(),
      ),
      GoRoute(
        path: '/trusted-contacts',
        builder: (BuildContext context, GoRouterState s) =>
            const TrustedContactsPage(),
      ),
      GoRoute(
        path: '/devices/:id/lost/activate',
        builder: (BuildContext context, GoRouterState s) =>
            LostModeActivationPage(
              deviceId: s.pathParameters['id'] ?? '',
              deviceName: s.extra as String? ?? 'Device',
            ),
      ),
      GoRoute(
        path: '/devices/:id/lost',
        builder: (BuildContext context, GoRouterState s) =>
            LostModeScreen(
              info: s.extra as LostModeInfo? ??
                  LostModeInfo(
                    deviceId: s.pathParameters['id'] ?? '',
                    state: LostModeState.active,
                    activatedAt: DateTime.now(),
                  ),
            ),
      ),
      GoRoute(
        path: '/lost/:recoveryId',
        builder: (BuildContext context, GoRouterState s) =>
            LostScreenPage(recoveryId: s.pathParameters['recoveryId'] ?? ''),
      ),
      GoRoute(
        path: '/finder/scan',
        builder: (BuildContext context, GoRouterState s) =>
            const QrScannerPage(),
      ),
      GoRoute(
        path: '/finder/:recoveryId',
        builder: (BuildContext context, GoRouterState s) =>
            FinderPage(
              recoveryId: s.pathParameters['recoveryId'] ?? '',
            ),
      ),
      GoRoute(
        path: '/map/live',
        builder: (BuildContext context, GoRouterState s) =>
            const LiveMapPage() as Widget,
      ),
      GoRoute(
        path: '/map/history',
        builder: (BuildContext context, GoRouterState s) =>
            const LocationHistoryPage(),
      ),
      GoRoute(
        path: '/devices/:id/map',
        builder: (BuildContext context, GoRouterState s) =>
            LocationHistoryPage(deviceId: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/devices/:id/evidence',
        builder: (BuildContext context, GoRouterState s) =>
            EvidencePage(deviceId: s.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/devices/:id',
        builder: (BuildContext context, GoRouterState s) =>
            DeviceDetailPage(
                deviceId: s.pathParameters['id'] ?? ''),
      ),
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState s,
          StatefulNavigationShell shell,
        ) =>
            AppShell(shell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                builder: (BuildContext context, GoRouterState s) =>
                    const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/devices',
                builder: (BuildContext context, GoRouterState s) =>
                    const DevicesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/activity',
                builder: (BuildContext context, GoRouterState s) =>
                    const ActivityPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/profile',
                builder: (BuildContext context, GoRouterState s) =>
                    const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Slim banner marking guest exploration. Rendered above the tab bar
/// whenever there is no session — tapping signs in, dismissing is done by
/// signing in. Never blocks content.
class GuestModeBanner extends StatelessWidget {
  const GuestModeBanner({super.key, required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      label: 'Exploring as guest. Sign in to protect devices.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          border: Border(
            top: BorderSide(color: theme.dividerColor),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.explore_outlined,
                size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Exploring as guest — sign in to protect devices.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            TextButton(
              onPressed: onSignIn,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 40),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 4-tab native shell (§6). Everything else rides contextual navigation.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isGuest =
        ref.watch(authControllerProvider).valueOrNull == null;
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isGuest) GuestModeBanner(onSignIn: () => context.go('/login')),
          BottomNavigationBar(
            currentIndex: shell.currentIndex,
            onTap: (int i) => shell.goBranch(i),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.devices_outlined),
                  activeIcon: Icon(Icons.devices),
                  label: 'Devices'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.timeline_outlined),
                  activeIcon: Icon(Icons.timeline),
                  label: 'Activity'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outlined),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile'),
            ],
          ),
        ],
      ),
    );
  }
}
