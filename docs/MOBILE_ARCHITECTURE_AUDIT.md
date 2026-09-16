# RETRACE — MOBILE_ARCHITECTURE_AUDIT (PHASE 0)

Tanggal: 2026-09-16
PRD source: `/home/reja/RETRACE MOBILE FIRST MASTER.txt` (2364 baris)
Auditor: OpenCode (Muse Spark)
Skills dipakai (benar-benar di-load, bukan disebut saja):
- ui-ux-pro-max (design intelligence + checklist App UI; auto-suggestion DITOLAK, lihat §6)
- dart-flutter-patterns (null-safety, sealed state, Riverpod/BLoC, GoRouter, Dio, testing)
- flutter-dart-code-review (checklist review 15 area)
- elite-ui-engineer (art direction + anti-slop rules)
- ui-critic (audit visual independen, severity CRITICAL→LOW)
- accessibility-auditor (WCAG, touch target, contrast, screen reader)
- security-auditor + security-review (RLS, secrets, auth, rate limit, checklist pre-deploy)
- performance-engineer (LCP/CLS/bundle, low-end Android)
- ecc-guide (ECC navigation; repo ECC tidak di-copy, dipakai sebagai panduan)
- git-workflow (GitHub Flow, conventional commits)
- postgres-patterns (index, RLS teroptimasi, pagination, UPSERT)

## 1. REPOSITORY — HASIL INSPEKSI FAKTUAL

| Klaim PRD | Fakta di disk | Status |
|---|---|---|
| Current repository: /home/reja/retrace | Direktori ada, isi HANYA 2 file: retracedesktop.png (2.05 MB), retracemobile.png (1.79 MB) | ❌ TIDAK SESUAI |
| Commit tervalidasi 7b16cf7 | `git log` → fatal: not a git repository | ❌ TIDAK ADA |
| docs/VALIDATION_REPORT.md | Tidak ada (docs/ baru dibuat saat audit ini) | ❌ TIDAK ADA |
| Existing web / mobile / auth / RLS / services / migrations | Tidak ada kode, tidak ada supabase/, tidak ada migrations/ | ❌ TIDAK ADA |
| Existing Supabase schema | Tidak ada file lokal; tidak ada linked project terverifikasi di repo | ⚠️ BELUM TERVERIFIKASI |

**Kesimpulan: ini GREENFIELD, bukan lanjutan repo existing.**
Keputusan arsitektur: scaffold Flutter baru di `/home/reja/retrace/` (tanpa menimpa 2 PNG reference),
git init baru, Supabase schema dibuat dari nol sesuai §44 (16 entity minimal) dengan migration baru.
Tidak ada "reuse existing correct schema" karena tidak ada yang bisa di-reuse — ini dicatat jujur,
bukan diada-adakan.

## 2. TOOLCHAIN

- Flutter 3.47.2 stable, Dart 3.13.2, DevTools 2.60.0 — MEMENUHI syarat (§85: analyze/test/build).
- supabase CLI: tersedia (`/home/reja/.npm-global/bin/supabase`).
- vercel CLI: tersedia. CATATAN: fase ini Flutter Mobile — `deploy vercel` TIDAK relevan per-phase
  mobile (Vercel = web). Tidak akan diklaim sebagai "deployed" palsu. Vercel hanya dipakai nanti
  untuk finder-web/recovery-web jika PRD web dibuka.
- gh CLI: TIDAK ditemukan di PATH (`which gh` kosong). Push GitHub butuh remote + auth —
  akan di-setup di Phase 14 / saat remote tersedia, bukan di-fake sekarang.
- Android SDK: ada `~/android-sdk` + `~/.android` — build APK dimungkinkan, diuji di Phase 14.

## 3. SUPABASE / DATABASE

- Tidak ada `supabase/config.toml`, tidak ada `migrations/` lokal.
- 16 entity wajib §44 (users→audit_logs) BELUM ADA — akan dibuat sebagai migration
  `supabase/migrations/XXXXXX_retrace_mobile_foundation.sql` di Phase 3/4, dengan RLS per tabel.
- Prinsip: single source of truth tetap Supabase; mobile TIDAK membuat parallel DB server.
  Local DB (Drift/Isar + flutter_secure_storage) hanya cache + encrypted queue (§45).

## 3b. DEPENDENCIES / SERVICES / WEB / VALIDATION-REPORT (eksplisit, anti-terlewat)

- pubspec.yaml: TIDAK ADA (greenfield) → dependency dipilih di P1 (flutter_riverpod,
  go_router, drift, flutter_secure_storage, geolocator, flutter_map, supabase_flutter,
  firebase_messaging, flutter_local_notifications, mobile_scanner, qr_flutter,
  image_picker, connectivity_plus, workmanager, intl, logger) dengan cek pub points/likes/
  publisher/lisensi sebelum dipakai (flutter-dart-code-review §10).
- services/ (location/sync/command/finder/evidence/notif): TIDAK ADA → dibuat per-phase P4–P10.
- existing web: TIDAK ADA di repo ini → §81 dipatuhi (tidak ada yang bisa dirusak;
  contract Supabase yang akan dibuat mobile-first dipakai web nanti).
- docs/VALIDATION_REPORT.md + commit 7b16cf7: TIDAK DITEMUKAN → tidak diklaim, matrix §83
  dimulai dari MOBILE_VALIDATION_REPORT di P11.

## 4. AUTH / RLS / SECURITY — STATUS

- Belum ada implementasi → semua item §42/§80 berstatus NOT-IMPLEMENTED (jujur, bukan PASS).
- BLOKIR KERAS: master file berisi 4 token plaintext (2×ghp, 1×vcp, 1×sbp).
  Ini risiko keamanan (secret scanning GitHub akan revoke + membocorkan akses).
  ATURAN: token TIDAK PERNAH di-commit, TIDAK di-hardcode di Dart, hanya via
  `--dart-define` / env / `flutter_dotenv` + `.gitignore`. Audit ini tidak menyimpan token.
  Rekomendasi: revoke/rotate 4 token tersebut setelah audit ini.

## 5. DESIGN REFERENCE — ANALISIS FAKTUAL (dibuka & dibaca, bukan asumsi)

### retracemobile.png (referensi UTAMA mobile)
- 13 grup layar gelap: Splash&Onboarding, Auth, Home, Devices List, Device Detail,
  Lost Mode, Remote Commands, Finder/QR, Activity Timeline, Permission Center,
  Trusted Contacts, Profile/Settings + strip Light Mode + Design System + Components + Screen States.
- Bahasa visual faktual: bg near-black kehijauan (~#0B1512), surface elevated (~#15211D),
  aksen teal/mint (~#00E5A0, CTA solid, bukan gradient), teks primary off-white,
  secondary muted gray-green. Status: Protected=green, Lost=red, Offline=gray, Limited=amber.
- Tipografi: Inter (Aa, Bold/SemiBold/Medium/Regular — headings 20, body 16, small 12).
- Komponen: Primary Button (solid mint, radius ~12), Secondary (outline gelap),
  Input Field (dark, hairline border), Status Badge (pill kecil), DeviceCard,
  MapCard (map gelap + accuracy circle), ActivityItem (timeline icon-dot + timestamp),
  PermissionItem (icon + Granted/Limited badge + Protection Score bar 80%),
  Bottom nav 4 item (Home/Devices/Activity/Profile) + CTA "+ Add Device".
- Screen states yang HARUS diimplementasikan: Loading (spinner), Empty (No devices yet),
  Error (Something went wrong + Retry), Offline (You're offline + Retry).
- Light Mode = same experience different feel (bg off-white, kartu putih, CTA tetap mint).

### retracedesktop.png (referensi BRAND, bukan layout)
- Dipakai untuk: brand voice (Find. Protect. Recover.), map treatment gelap,
  status language, information architecture (Devices/Live Map/Recovery/Activity/
  Finder/Evidence/Trusted Contacts/Admin), BUKAN untuk memaksa layout dashboard ke mobile.

## 6. SKILL DECISION — PENOLAKAN TERVERIFIKASI

`ui-ux-pro-max --design-system` untuk query "security device tracking recovery dark premium"
mengembalikan: Pattern Scroll-Storytelling, Style Liquid Glass, warna Primary #1C1917 +
Accent gold #A16207, font Cormorant/Montserrat.
DITOLAK dengan alasan tercatat (§71 NO GENERIC REDESIGN):
1) Bertentangan dengan reference (teal/mint + Inter, bukan gold + serif).
2) Melanggar §3 (excessive glassmorphism) dan §52 (primary = RETRACE teal/mint).
3) Pattern storytelling tidak cocok untuk security app yang calm/precise.
Yang dipakai dari skill tersebut: workflow, App-UI checklist (touch target 48dp Android,
contrast 4.5:1, safe-area, reduced motion, no-emoji-icons), BUKAN saran gayanya.

## 7. GAP MATRIX vs PRD (ringkas, jujur)

| Area PRD | Status |
|---|---|
| §7–§18 Screens (splash→device detail) | 0% — belum ada |
| §19–§22 Map/location/offline/network | 0% — belum ada |
| §23–§33 Lost/Command/QR/Finder/Relay | 0% — belum ada |
| §34–§41 Evidence/Battery/Activity/Realtime/Notif/Trusted/Recovery | 0% |
| §42–§50 Security/Admin/DB/Local/Sync/Consistency/Error/Loading/Empty | 0% |
| §51–§60 Design system/colors/type/icons/components/motion/a11y/responsive/offline/security-ux | 0% |
| §61–§65 Power-off/Reset/Lifecycle/Background/Battery-opt | 0% |
| §66–§72 Real-device/E2E/Chaos/UI-test/Design-QA/Perf | NOT-TESTED |
| §73–§79 Architecture/State/Routing/Deep-link/L10n/Logging/Observability | 0% |
| §80–§85 Supabase-security/Web/Migration/Test-matrix/Limitation/DoD | 0% |

Tidak ada satu pun yang diklaim PASS/PARTIAL. Semua NOT-IMPLEMENTED / NOT-TESTED.

## 8. RISIKO & KEPUTUSAN ARSITEKTUR (dicatat sebelum coding)

1. Greenfield → pakai GitHub Flow + conventional commits, Flutter + Riverpod
   (alasan: async state eksplisit via AsyncValue + testable via ProviderContainer;
   BLoC alternatif valid tapi Riverpod lebih ringkas untuk offline queue + realtime streams).
2. Router: GoRouter + ShellRoute 4-tab (Home/Devices/Activity/Profile) + guarded redirect (§75).
3. Local: Drift (SQLite) untuk queue/locations/commands + flutter_secure_storage untuk secrets.
   SharedPreferences DILARANG untuk data kompleks (§45).
4. Map: flutter_map + OSM tiles default (nol API key, offline-capable via cached tiles);
   Google Maps opsional via --dart-define, tidak hardcode key (§19, §609).
5. Background location: geolocator + workmanager/foreground service + notifikasi persisten
   sesuai aturan OS; tidak ada hidden behavior (§64).
6. Command: Supabase `lost_commands` + realtime + polling fallback + ACK eksplisit;
   UI tidak menampilkan Success sebelum ACK (§25).
7. QR: signed JWT/expiring token + replay prevention + rate limit server-side (§42).
8. Push: FCM + flutter_local_notifications + deep link per kategori (§39, §76).
9. L10n: flutter_localizations ARB (id + en) sejak Phase 1, tidak hardcode string (§77).
10. Vercel deploy: DITUNDA hingga ada surface web (finder/recovery web). Tidak di-fake.

## 9. RENCANA PHASE (sesuai §86, tanpa lompat)

- P0 audit — SELESAI dengan dokumen ini.
- P1 design system (theme/colors/type/spacing/components/light-dark + audit ProMax+ECC).
- P2 app shell (splash/onboarding/auth/nav/home/devices/activity/profile).
- P3 device foundation (registrasi, identitas, permission, secure storage, local DB).
- P4 location engine (foreground/background, queue, sync, realtime, history, map).
- P5 lost mode, P6 command engine, P7 finder, P8 evidence, P9 trusted+recovery,
  P10 notification, P11 real-device E2E, P12 design audit, P13 security audit, P14 build.
- Setiap phase: IMPLEMENT→TEST→AUDIT→FIX→RETEST→REGRESSION→DESIGN→SECURITY→BUILD→COMMIT→PUSH.

## 10. AUDIT LOOP PHASE 0 (wajib §87)

- [x] Repository di-inspect (isi, git, docs) — fakta di §1.
- [x] Flutter/Supabase/Vercel toolchain diverifikasi — §2.
- [x] Migrations/RLS/schema di-inspect (tidak ada → greenfield jujur) — §3/§4.
- [x] Kedua PNG dibuka & dianalisis — §5.
- [x] Skills di-discover (390) + yang relevan di-load (11) + keputusan tolak dicatat — §6.
- [x] Gap matrix jujur, nol klaim palsu — §7.
- [ ] Perbaikan: rotate 4 token plaintext (TINDAKAN USER/OWNER, di luar kode).
- [ ] Perbaikan: `git init` + remote GitHub + branch main (dilakukan saat mulai P1, bukan sebelum audit).
- Verdict Phase 0: AUDIT LENGKAP, BLOKIR CODING SEBELUM INI TELAH DIPATUHI. Lanjut P1.
