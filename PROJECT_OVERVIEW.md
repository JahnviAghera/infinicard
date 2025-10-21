# 📘 Infinicard - Project Overview (Full Documentation)

Last Updated: October 21, 2025

This document provides an end-to-end overview of the Infinicard project: product vision, implemented features, architecture, backend setup, APIs, environment, data model, build/run instructions, and the roadmap of upcoming features.

---

## 🧭 Vision & Positioning

Infinicard is a professional digital business card and networking platform focused on:
- Sustainable, paperless networking with measurable environmental impact
- Professional-grade privacy controls and enterprise readiness
- AI-powered discovery, analytics, and business outcomes
- Event-scale contact sharing and post-event engagement

Unique Selling Propositions (USPs):
- Sustainability-first with real-time environmental metrics
- Professional gamification (certifications, reports, benchmarking)
- Mass event directory + contact sharing
- Enterprise controls, analytics, and integrations

---

## 🧩 App Architecture

- Framework: Flutter 3.x (Dart 3.8)
- Platforms: Android, iOS (Web/Desktop planned)
- Design: Material Design 3, OLED-optimized dark theme
- State: Service-layer + Stateful widgets (lightweight)
- Routing: Named routes defined in `main.dart`
- Storage: Local (SharedPreferences) + planned backend sync
- Permissions: Camera, Storage, Internet

Directory highlights:
- `lib/main.dart` - App entry, routes, navigation
- `lib/theme.dart` - Colors and typography
- `lib/models/` - `card_model.dart`, `contact_model.dart`
- `lib/services/` - `sustainability_service.dart`, storage/sharing services
- `lib/screens/` - UI screens (21+ implemented)

---

## 🎯 Implemented Features (Mobile App)

- Card Management: Create, edit, preview (flip), share (QR/PNG/PDF)
- Contacts: List, detail, notes, reminders, actions (call/SMS/email)
- Discover: AI-style professional suggestions with filters
- Rewards: Points, badges, leaderboard (demo data)
- Sustainability: Impact dashboard (cards, paper, trees, CO2)
- Integrations: Google Contacts, Outlook toggles; CSV import/export
- Enterprise: Team stats, roles, analytics (demo)
- Notifications: Center with types, actions
- Activity Log: Timeline of actions with color-coded categories
- OCR Scanner: Camera capture + Tesseract OCR results edit/save
- Settings: Dark mode, privacy levels, 2FA toggle, backups
- Help & About: FAQs, support, terms, privacy

For full details: see `FEATURES.md` (screen-by-screen spec).

---

## 🛠️ Dependencies (pubspec.yaml)

Key packages:
- UI: `flutter`, `cupertino_icons`, `google_fonts`
- Sharing: `share_plus`, `qr_flutter`, `url_launcher`
- Device: `camera`, `permission_handler`, `nfc_manager`, `path_provider`
- OCR: `tesseract_ocr`
- Data: `shared_preferences`, `csv`, `http`, `uni_links`

Version: `1.0.0+1` | SDK: `^3.8.1`

---

## 🗄️ Backend Overview

- Location: `backend/`
- Stack: PostgreSQL 16 (Docker), Node.js/Express API (scaffold)
- Orchestration: Docker Compose
- Admin UI: Adminer (DB manager) on port 8080

Compose services:
- `postgres` → 5433 host port → 5432 container
- `adminer` → 8080

Init SQL: `backend/init-db/`
- 01-create-schema.sql
- 02-create-functions.sql
- 03-seed-data.sql
- 04-create-notifications.sql
- 05-create-professionals.sql

API project: `backend/`
- `package.json` with scripts: start/dev/test/lint
- `src/` with `server.js`, routes, controllers, middleware, config

---

## 🚀 Backend: Setup & Run

Prereqs: Docker Desktop, Node 18+

1) Start database and Adminer
- Open terminal in `backend/`
- Run: docker-compose up -d
- Verify: docker-compose ps (expect db on 5433, adminer on 8080)
- Adminer: http://localhost:8080
  - System: PostgreSQL | Server: postgres
  - DB: infinicard | User: infinicard_user | Pass: infinicard_pass_2024

2) Seeded database
- Init scripts auto-run on first boot
- Sample cards, contacts, professionals created

3) Run API (when implemented)
- Install: npm install
- Dev: npm run dev
- Base URL: http://localhost:3000/api

4) Useful DB commands
- Backup: docker exec infinicard_db pg_dump -U infinicard_user infinicard > backup.sql
- Restore: docker exec -i infinicard_db psql -U infinicard_user infinicard < backup.sql
- Reset: docker-compose down -v && docker-compose up -d

Windows note: Use PowerShell redirection or WSL for backup/restore commands if needed.

---

## 🔌 API Summary (Planned/Documented)

Base: `http://localhost:3000/api`
Auth: JWT (7-day access, 30-day refresh)

Auth:
- POST /auth/register
- POST /auth/login
- GET /auth/profile
- PUT /auth/profile
- POST /auth/change-password

Cards:
- GET /cards (search, pagination)
- GET /cards/:id
- POST /cards
- PUT /cards/:id
- DELETE /cards/:id
- POST /cards/:id/share (link/qr/pdf)

Contacts:
- GET /contacts (search, tags)
- GET /contacts/:id
- POST /contacts
- PUT /contacts/:id
- DELETE /contacts/:id
- POST /contacts/import (CSV)
- GET /contacts/export (CSV/vCard)

Discover:
- GET /discover/professionals?location=&field=&limit=
- GET /discover/locations
- GET /discover/fields

Activity/Notifications:
- GET /activity
- GET /notifications
- POST /notifications/read

Integrations:
- POST /sync/google-contacts
- POST /sync/outlook
- GET /sync/status

Admin/Teams:
- GET /team
- POST /team
- PUT /team/:memberId
- DELETE /team/:memberId

(See `backend/API_DOCUMENTATION.md` for full schemas and examples.)

---

## 🧬 Data Model (High-Level)

Core entities:
- User (id, email, name, auth)
- BusinessCard (id, ownerId, fields, theme, visibility)
- Contact (id, name, company, email, phone, notes, reminder)
- Professional (name, location, field, tags)
- Activity (type, timestamp, metadata)
- Notification (type, message, status)
- SyncLog (entity, action, status)

Relationships:
- User 1—N Cards, Contacts
- Cards/Contacts N—N Tags
- Cards 1—N Social Links

Indexes & features:
- UUID keys, soft deletes, timestamps
- Full-text search helpers
- Trigger-based logging

---

## 🧪 Testing & Quality

- Flutter: `flutter_test` configured
- Backend: `jest`, `eslint` in `backend/package.json`
- Lints: `flutter_lints` with `analysis_options.yaml`
- CI/CD: not configured (suggest GitHub Actions)

---

## ▶️ Run the App

1) Install Flutter dependencies: flutter pub get
2) Connect a device or emulator
3) Run: flutter run
4) Permissions: allow camera for OCR

Build:
- Android: flutter build apk --release
- iOS: flutter build ios --release

---

## 📚 End-User Guides (available in repo)

- STARTUP_GUIDE.md, WALKTHROUGH_GUIDE.md
- QUICK_FIX_404.md, FIX_404_QUICK_START.md
- ONLINE_SHARING_SETUP.md, WEB_LINK_SHARING_GUIDE.md
- CARD_REORDERING_AND_SHARING.md, CARD_REORDERING_FIX.md
- AUTHENTICATION_SETUP.md

---

## 🧭 Roadmap (Highlights)

See `NEW_FEATURES_ROADMAP.md` for full roadmap. Key additions:

- Mass Event Features: directory, bulk sharing, group sessions, follow-ups
- Privacy Levels & Sharing-Type Control (granular field visibility)
- Professional Impact Portfolio & Reports
- ROI Dashboard & Cost Savings
- Certifications, Benchmarking, LinkedIn integration
- Meeting Scheduler, CRM Lite, Smart Follow-ups
- AI-Based Discovery & Smart Reminders

---

## 🔐 Privacy & Security Plan

- Multi-tier privacy per card and per sharing method
- 2FA, secure storage, encrypted transport
- GDPR tooling (export/delete, audit logs)
- Optional blockchain verification of cards

---

## 💼 Enterprise Plan

- Team management, roles, analytics
- White-label customization
- API access + SSO (planned)
- ESG/CSR reporting integration

---

## 🧭 Implementation Phases

Phase 1 (Foundation):
- Privacy levels, event sharing, impact portfolio, analytics

Phase 2 (Growth):
- Scheduler, CRM lite, certifications, benchmarking

Phase 3 (Scale):
- AI recommendations, virtual events, forums, API

Phase 4 (Premium):
- Marketplace, multilingual, wearables, desktop

---

## ❓ Support

- In-app Help & Support screen
- Backend Adminer at http://localhost:8080
- For development issues, open GitHub issues

---

If you want, I can tailor this doc into a multi-page docs site (mkdocs/docusaurus) and wire it to CI for automatic deployments.