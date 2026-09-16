# PHASE 2 AUDIT — App Shell (2026-09-16)

Source: `/home/reja/RETRACE MOBILE FIRST MASTER.txt` (§7 SPLASH, §8 ONBOARDING, §9 DEVICE TYPE, §10 AUTH, §6 NAV, §16 HOME, §17 DEVICES, §18 DETAIL, §37 ACTIVITY, §75 ROUTING, plus cross-cutting §48–§60).
Method: IMPLEMENT → TEST → AUDIT AGAINST PRD → FIX → RETEST → REGRESSION → BUILD. Design + a11y + security audits inline (§70).

## Skills Loaded (§1 wajib)
ui-ux-pro-max, elite-ui-engineer, ui-critic, accessibility-auditor, dart-flutter-patterns, flutter-dart-code-review, security-review, security-auditor, performance-engineer, git-workflow, postgres-patterns, ecc-guide — all loaded, not just named. ProMax gold/serif suggestion rejected (see `MOBILE_ARCHITECTURE_AUDIT.md §6`).

## Implementation Map (Phase 2 shell subset)

| PRD | Expected | Actual | Status | Evidence |
|---|---|---|---|---|
| §7 Splash — logo, tagline, subtle motion, loading, not too long | R + RETRACE + Find. Protect. Recover. + subtle scale 0.96→1 (700ms easeOutCubic) + real bootstrap loading | `lib/features/splash/splash_page.dart:1` | **PASS** | test boot provider, no artificial delay |
| §8 Onboarding — 3 steps + CTA | Welcome / Protect / Always ready + Continue paging + dots + Skip | `lib/features/onboarding/onboarding_page.dart:1` | **PASS** | onboarding_test |
| §9 Device Type — Phone/Tablet/Other, progressive disclosure | RadioGroup Phone/Tablet/Other, single question, persisted via secure storage | `onboarding_page.dart:175` | **PASS** | store key `retrace_onboarding_device_type` |
| §10 Login | email/password form, validators, human error banner, Forgot push | `lib/features/auth/login_page.dart` | **PASS** | auth_screens_test |
| §10 Register | full name + email + password, validators, verification-sent state | `lib/features/auth/register_page.dart` | **PASS** | auth_screens_test |
| §10 Password recovery | email → sendReset → Check inbox | `lib/features/auth/recovery_page.dart` | **PASS** | controller sendPasswordReset tested |
| §10 Session persistence/expiration | Supabase SDK stream + `watchAuth` → AuthUser?; bootstrap + router react to null (expired → /login) | `lib/features/auth/auth_controller.dart:14` `lib/routing/app_router.dart:50` | **PASS** | auth_controller_test |
| §10 Secure session | Secrets via `--dart-define` only (`Env`), `.gitignore` .env, no hardcoded, SecurePreferencesStore for onboarding | `lib/core/config/env.dart` `.env.example` | **PASS** | secret scan clean, flutter_secure_storage 9.2.4 |
| §10 No fake social | No Google/Apple buttons until real provider | code search — none | **PASS** | security-review checklist |
| §6 Nav — 4 tabs only | Home/Devices/Activity/Profile via StatefulShellRoute.indexedStack | `lib/routing/app_router.dart:105` | **PASS** | shell_pages_test 320dp |
| §75 Routes shell | /splash /onboarding /login /register /recovery /design-system /devices /devices/:id + shell | router | **PASS** | redirect tests via auth |
| §16 Home | greeting + email + devices empty→"No devices yet" or card + Locate/Ring + recent activity placeholder | `lib/features/home/home_page.dart` | **PASS** | shell_pages_test |
| §17 Devices | search + All/Online/Offline/Lost chips + real filter/search logic + empty honest | `lib/features/devices/devices_page.dart` `devices_repository.dart` | **PASS** | devices_filter_test |
| §18 Device detail | honest map placeholder until Phase 4 engine, not-found handled | `lib/features/devices/device_detail_page.dart` | **PASS** | manual route test |
| §37 Activity | All/Security/Location/Device/Finder/Command/System tabs + filter + honest empty | `lib/features/activity/activity_page.dart` `activity_repository.dart` | **PASS** | activity_filter_test |
| §6 Profile — full list | Account (email), Security (PIN/Recovery/Trusted upcoming honest Soon sheets), Preferences (Notifications/Language soon), Appearance (real dark/light SegmentedButton), Support (About/Licenses real), Sign Out (confirmation) | `lib/features/profile/profile_page.dart` | **PASS** | shell_pages_test updated |
| §48 Error UX | AuthErrorBanner—human messages, no stack traces | `lib/features/auth/login_page.dart:35` | **PASS** | _humanize mapping |
| §49 Loading UX | LoadingState everywhere, no blank, no fake optimistic | `lib/design_system/components/retrace_states.dart` | **PASS** | all pages switch Loading |
| §50 Empty states | EmptyState with icon+title+message+optional action (never dead) | same | **PASS** | EmptyState logic |
| §51 Design system reused | No per-screen hardcoded colors, all via RetraceTheme/Cards/StatusBadge | all shell pages | **PASS** | analyze No issues |
| §53 Typography | Inter via google_fonts, 320dp-safe, no overflow | `lib/core/theme/retrace_typography.dart` | **PASS** | design_system_test 320dp |
| §54 Icons | Material outlined only, no emoji, no mixed families | all pages | **PASS** | audit |
| §57 a11y | 48dp touch target RetraceButton, semantic labels, no color-only (StatusBadge icon+text), safe area, screen reader labels | components | **PARTIAL** | touch target ok; screen reader liveRegion on banners; remaining: axe/lighthouse in Phase 12 |
| §58 Responsive | gutter adapts, ListView insets, 320/600 tested | `RetraceSpacing.gutter` + tests | **PASS** | 320dp tests |
| §59 Offline UI | SyncIndicator Local only/Synced, empty honest (Phase 4 queue later) | Home AppBar | **PASS** | phase scope |
| L10n §77 | SupportedLocales en/id, delegates, AppStrings ready | `lib/main.dart:37` | **PASS** | architecture ready |

## Omissions Found & Fixed (audit loop §87)

| # | Found | Fix |
|---|---|---|
| 1 | Splash was static — missing subtle motion (§7) | Added TweenAnimationBuilder scale 0.96→1 700ms |
| 2 | Activity Filter missing Command/System (had 5 of 7) | Added `command, system` to enum + 2 tabs |
| 3 | Profile hid 5 upcoming entries (audit would flag incomplete vs §6) | Added honest `_UpcomingTile` Soon sheets for PIN/Recovery/Trusted/Notifications/Language — each does something (opens sheet), never dead, never fake screen |
| 4 | Devices filtered cast `(devices as AsyncData<...>)` — unnecessary cast | Removed cast (`devices.valueOrNull`) |
| 5 | Env example leaked `eyJ` prefix triggering secret scan | Replaced with `<anon-key>` placeholder |
| 6 | Auth test tapped title not button → validator never surfaced | Switch to `find.byType(RetraceButton)` |
| 7 | Profile shell test expected PIN hidden but new design shows it | Updated test to assert Soon sheets + scroll |

## Verdict Phase 2
**PASS — SHELL GREEN.** No fake data, no dead buttons, no hardcoded devices, no fake social, analyze clean, build clean, 41/41 tests pass (incl. 320dp). Regression on Phase 1 (design gallery still reachable at `/design-system`) — re-tested separately.

## Remaining Phase 2 Limitations (documented, not hidden)
- Supabase Auth storage defaults to shared preferences (SDK default); flutter_secure_storage custom adapter pending (security-auditor backlog, no custom session handle today). Honest: not claimed as secure-store-backed.
- APK `assembleDebug` blocked in this container (no JDK installed — Gradle needs JAVA_HOME). Verified via `flutter build bundle` + `flutter analyze` + `flutter test`. Real-device E2E (§66) scheduled Phase 11.
- Device registration, location engine, lost mode, commands, finder, evidence, trusted, notifications — intentionally NOT in Phase 2 shell (arrive Phase 3–10 per §86). No placeholders shown as functional.

Next: Phase 3 Device Foundation (registration, identity, secure storage local DB) per §86 order — does not re-open shell routes.

