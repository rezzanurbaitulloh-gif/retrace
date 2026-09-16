import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrace/app/bootstrap.dart';
import 'package:retrace/app/design_gallery.dart';
import 'package:retrace/data/auth/auth_user.dart';
import 'package:retrace/data/session/onboarding_store.dart';
import 'package:retrace/features/activity/activity_page.dart';
import 'package:retrace/features/auth/auth_controller.dart';
import 'package:retrace/features/auth/login_page.dart';
import 'package:retrace/features/auth/recovery_page.dart';
import 'package:retrace/features/auth/register_page.dart';
import 'package:retrace/features/devices/device_detail_page.dart';
import 'package:retrace/features/devices/devices_page.dart';
import 'package:retrace/features/home/home_page.dart';
import 'package:retrace/features/onboarding/onboarding_page.dart';
import 'package:retrace/features/profile/profile_page.dart';
import 'package:retrace/features/splash/splash_page.dart';

/// All Phase 2 routes (§75 shell subset). Command/lost/finder/evidence/
/// trusted/recovery routes are added by their phases — never as stubs.
/// Protected routes redirect to /login when no session exists.
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
      const List<String> guestRoutes = <String>[
        '/splash',
        '/onboarding',
        '/login',
        '/register',
        '/recovery',
      ];
      if (user == null) {
        if (guestRoutes.contains(loc)) {
          return loc == '/splash' ? '/login' : null;
        }
        return '/login';
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

/// 4-tab native shell (§6). Everything else rides contextual navigation.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: BottomNavigationBar(
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
    );
  }
}
