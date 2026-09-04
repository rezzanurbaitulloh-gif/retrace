# RETRACE

**Device Recovery, Tracking & Security Platform**

A complete device recovery ecosystem for Android and Web platforms.

## Overview

RETRACE helps owners find and secure lost devices across various conditions:
- Online / Offline / No Mobile Data / Wi-Fi Only
- GPS Available / GPS Limited
- Device Moving / Stationary
- Finder Present / Absent
- Low Battery / Connection Restored

## Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile | Flutter + Dart (Android) |
| Web | Next.js + TypeScript |
| Backend | Supabase (PostgreSQL) |
| Realtime | Supabase Realtime |
| Local DB | SQLite / Drift |
| Push | Firebase Cloud Messaging |
| Maps | Provider-agnostic abstraction |
| Deployment | Vercel + Supabase |

## Project Structure

```
retrace/
├── mobile/                 # Flutter Android app
│   ├── lib/
│   │   ├── core/          # Core utilities & config
│   │   ├── features/      # Feature modules
│   │   └── main.dart
│   └── pubspec.yaml
├── web/                    # Next.js web app
│   ├── app/               # App Router pages
│   ├── components/        # React components
│   ├── lib/               # Utilities & config
│   └── package.json
├── supabase/               # Supabase backend
│   ├── config.toml
│   └── migrations/
├── scripts/                # Utility scripts
└── docs/                   # Documentation
```

## Getting Started

### Prerequisites
- Flutter SDK 3.19+
- Dart 3.3+
- Node.js 20+
- Supabase CLI
- Android Studio

### Web Setup
```bash
cd web
npm install
npm run dev
```

### Supabase Setup
```bash
supabase link --project-ref umxiqgauhfsbzlqiyelm
supabase db push
```

## Core Principles

1. **Recovery First** - Every feature contributes to device recovery
2. **Offline First** - Offline is a primary state, not an error
3. **Security First** - Location, device control, camera, identity require security foundation
4. **Platform Honest** - Never fake capabilities (GPS, commands, hotspot, camera, reset protection)
5. **Human Friendly** - Finders can help without creating accounts
6. **Anti-Stalking** - All tracking requires ownership, authorization, permission, auditability

## Documentation

- [PRD & Technical Blueprint](/home/reja/retraceprd.md) - Complete product specification
- [Architecture Docs](docs/architecture/ARCHITECTURE.md)
- [Requirements Mapping](docs/requirements/REQUIREMENTS_MAPPING.md)
- [Security Baseline](docs/security/SECURITY_BASELINE.md)

## License

Proprietary - All rights reserved.
