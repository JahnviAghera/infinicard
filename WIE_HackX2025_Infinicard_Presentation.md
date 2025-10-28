# Congratulations — Final Round Selection!
**WIE HackX2025 — Stage 3: Proof-of-Concept & Demonstration**  
Project: Infinicard  
Team: [Your Team Name] | Contact: [Team Lead Email / Phone]  
Date & Venue: 2 Nov 2025 — 9:00 AM – 1:00 PM, Nirma University, Ahmedabad

**Speaker notes:**  
Quick thank-you and excitement. One-line elevator pitch: "Infinicard — a smart digital business card and contact management platform that uses OCR, NFC and seamless sharing to digitize and modernize networking."

**Visuals:** Project logo from `assets/icons/` or `assets/images/`. Background image of conference or campus.

---

## Team & Roles
- [Name] — Team Lead / Full-stack Flutter developer  
- [Name] — Backend / API & Database  
- [Name] — UX / Frontend & QA  
- [Name] — Business / Pitch & Market

**Speaker notes:** One sentence about each team member’s contribution. Mention any mentorship or prior recognition if applicable.

**Visuals:** Photos or avatars of team members (optional).

---

## Problem Statement
- Physical business cards are easy to lose and hard to update.  
- Manual contact entry is time-consuming and error-prone.  
- No single, privacy-aware standard for card sharing across mobile & desktop.  
- Organizers and professionals need a reliable digital solution for conferences.

**Speaker notes:** Tell a short story: missed follow-ups after conferences due to lost cards. Emphasize need for robust PoC handling scanning, sharing, and syncing.

---

## Our Solution: Infinicard
- Digital business cards with quick sharing (QR, NFC, link).  
- On-device OCR to capture printed cards (`assets/eng.traineddata` used with Tesseract).  
- Central backend for syncing, contact management, and online sharing.  
- Easy-to-use Flutter app, cross-platform (Android / iOS / Web / Desktop).

**Speaker notes:** Summarize key capabilities and value: speed, accuracy, privacy (local OCR + optional server sync). Highlight this is a working prototype in the repo.

**Visuals:** App screenshots (see "Screenshots to include" slide).

---

## Key Features (PoC)
- OCR-based card scanning and auto-parsing (name, phone, email, company).  
- Create & manage multiple cards (personal & business).  
- Share via QR, link, Bluetooth/NFC (where supported), and social sharing.  
- Cloud backup & offline-first behaviour.  
- Contact import/export and integration with phone contacts.

**Speaker notes:** For PoC, we focus on reliability of OCR + smooth sharing flow. Mention `lib/screens/my_cards_screen.dart` as the main UI for card management.

---

## Demo Flow (what we'll show live)
1. Launch the app (mobile or desktop).  
2. Open `My Cards` screen (`lib/screens/my_cards_screen.dart`).  
3. Tap "Scan Card" → use camera to capture printed card (Tesseract OCR).  
4. Show auto-filled fields (edit if needed) and save.  
5. Share saved card via QR/link and receive on another device.  
6. Show backend sync status and contact saved in server (`backend/`).

**Speaker notes:** Keep demo to 3–5 minutes: scan → save → share → verify.

**Local commands to run (Windows `cmd.exe`):**
```cmd
:: Open repo root
cd C:\Users\A\StudioProjects\infinicard

:: Run backend (from repo \backend) — typical steps:
cd backend
npm install
npm start

:: Run Flutter app (ensure device/emulator connected)
cd C:\Users\A\StudioProjects\infinicard
flutter pub get
flutter run
```
**Speaker notes:** Explain you’ll run the app on a mobile device or emulator; backend run is optional if using local data.

---

## Screenshots to include (assets & paths)
Checklist of screenshots to capture and include:
- App home screen: reference `lib/main.dart`.  
- `My Cards` screen: `lib/screens/my_cards_screen.dart` (primary PoC screen).  
- OCR scan flow: camera capture + filled form after parsing.  
- Sharing screen: QR / share sheet / link preview.  
- Backend dashboard or API response: sample from `backend/` (public folder or API route).  
- Icons/branding: `assets/icons/` and `assets/images/`.

**Speaker notes:** Recommend high-resolution screenshots (1080x1920). Save images with consistent names like `slide_03_mycards.png`.

---

## Tech Stack
- Frontend: Flutter (Dart) — cross-platform UI  
  - Key files: `lib/main.dart`, `lib/screens/`, `lib/widgets/`  
- OCR: Tesseract + `assets/eng.traineddata` (assets config in `assets/`)  
- Backend: Node.js / Express (see `backend/package.json` and `backend/src/`)  
- Database: (Check `backend/` for DB config; likely PostgreSQL or MongoDB)  
- Integrations: NFC, sharing (plugins under `android/`, `ios/`), `share_plus`, `mobile_scanner`, `tesseract_ocr`.

**Speaker notes:** Justify choices: Flutter for single codebase and rapid prototyping; Tesseract for offline OCR.

---

## Architecture & Data Flow
- User scans business card (camera) → OCR engine (`assets/eng.traineddata`) extracts text.  
- Parser maps text to fields (name, phone, email, company).  
- Card saved locally and optionally synced to backend (`backend/` APIs).  
- Sharing via generated QR / link — link resolves to hosted profile / vCard.  
- Optional: Contact export to phonebook.

**Speaker notes:** Show sequence diagram: Mobile app ↔ Backend API ↔ Database. Mention caching and offline-first approach.

---

## Code Highlights (PoC)
- UI: `lib/screens/my_cards_screen.dart` — card list & actions.  
- App entry: `lib/main.dart` — routing & initialization.  
- OCR integration: search for Tesseract usage in `lib/` (e.g., `tesseract_ocr` plugin code).  
- Backend API routes: `backend/src/` — endpoints for saving/fetching cards.  
- Asset: `assets/eng.traineddata` & `tessdata_config.json` — OCR config.

**Speaker notes:** Point judges to these files for technical review and offer to show a short snippet during Q&A.

---

## Security & Privacy Considerations
- OCR performed locally by default — personal data stays on device.  
- Optional encrypted sync to backend — transport via HTTPS (TLS).  
- User controls sharing (single card vs. multiple cards).  
- Minimal permissions: camera (for OCR), optional contacts (only if user consents).

**Speaker notes:** Stress privacy-first defaults and minimal data exposure.

---

## Market & Use Cases
- Events & conferences — fast digital exchange of contacts.  
- Retail & sales teams — quick client data capture.  
- Educational institutions — networking for students & alumni.  
- Service providers — sharing digital profiles, reducing card printing costs.

**Speaker notes:** Provide high-level TAM rationale if requested.

---

## Business Model & Monetization
- Freemium: basic card creation & sharing free; premium features (analytics, custom branding, team management).  
- Enterprise licensing for conferences and corporate accounts.  
- Partnerships with event platforms and organizers.

**Speaker notes:** Outline short pricing tiers (Free, Pro, Enterprise) and example numbers if available.

---

## Roadmap (Next 6 months)
- Short-term (1–2 months): improve OCR parsing accuracy, UI polish.  
- Medium (3–4 months): enterprise features: team management, analytics.  
- Long-term (5–6 months): CRM integrations, calendar & SSO.

**Speaker notes:** Explain priorities for production-readiness.

---

## Evaluation Criteria Mapping
- Functionality — Demo shows working OCR scan → save → share flow.  
- Innovation — Offline-first OCR + multiple share channels + privacy defaults.  
- Practicality — Usable in event scenarios; quick scan → share flow.  
- Presentation Quality — Concise demo, clear architecture, business viability.

**Speaker notes:** Tell judges what to look for during demo.

---

## Risks & Mitigations
- OCR accuracy with poor-quality cards — allow user edit before saving + update training data.  
- Platform-specific sharing limitations (e.g., NFC) — fallback to QR/link.  
- Backend availability — offline-first with local cache and sync when available.

**Speaker notes:** Describe how each risk is addressed.

---

## What We Need / Ask
- Mentorship on scaling OCR and product-market fit.  
- Access to event integrations and pilot customers.  
- Feedback on UX and enterprise pricing strategies.  
- Potential seed support to reach next milestone.

**Speaker notes:** Be specific — e.g., "We'd appreciate 1–2 hours/week mentorship for 6 weeks."

---

## Backup Slides (Q&A & Technical Deep Dive)
- Code snippet: show parsing logic from `lib/` where OCR results are mapped to fields.  
- API sample: example POST /cards response from `backend/src/`.  
- Steps to reproduce locally (commands and prerequisites).  
- Edge-case handling notes: duplicate cards, merge flow.

**Speaker notes:** Keep these for judges asked for technical depth.

---

## One-Page Summary (Handout)
- Problem → Solution (1 line)  
- Key features (3 bullets)  
- Demo steps (2–3 bullets)  
- Tech stack (one-line)  
- Ask & Contact

**Speaker notes:** This slide serves as a printable handout.

---

## Thank You / Contact
- Thank you for the opportunity — looking forward to feedback.  
- Team Contact: [Team Lead Email / Phone]  
- Repo: https://github.com/JahnviAghera/infinicard  
- Live demo: "We’re ready to demo now — please ask for a walkthrough."

**Speaker notes:** Invite questions and offer a follow-up demo.

---

## Appendix — Suggested Backup Code Snippets & Commands

### Example: Show where `My Cards` list is implemented
- File: `lib/screens/my_cards_screen.dart`  
**Speaker notes:** "This screen lists cards and exposes scan/share actions."

### OCR config and assets
- File: `assets/eng.traineddata`  
- File: `tessdata_config.json`  
**Speaker notes:** "We ship trained data for offline OCR."

### Backend run & API snippet
- Path: `backend/src/` — show one route, e.g., POST /cards -> store card.  
**Speaker notes:** "This endpoint stores card metadata and returns an ID."

### Repro steps (Windows `cmd.exe`)
```cmd
:: 1) Start backend
cd C:\Users\A\StudioProjects\infinicard\backend
npm install
npm start

:: 2) Start Flutter app
cd C:\Users\A\StudioProjects\infinicard
flutter pub get
flutter run

:: 3) If you only want to demo the app without backend:
::    run the Flutter app and use local mode / offline features
flutter run -d <device_id>
```

---

## Demo Day Checklist
- [ ] Capture high-quality screenshots listed above.  
- [ ] Verify `flutter run` works on demo device.  
- [ ] Ensure backend is reachable (or run app in offline demo mode).  
- [ ] Prepare backup slide with step-by-step commands and code snippet.  
- [ ] Rehearse demo: 3 minutes live + 2 minutes Q&A.

---

## Next steps I can do for you
- Create the actual `WIE_HackX2025_Infinicard_Presentation.md` file in the repo right now.  
- Generate a `.pptx` from this Markdown (with speaker notes).  
- Extract exact code snippets from `lib/screens/my_cards_screen.dart`, `lib/main.dart`, or backend files and add them to the backup slides.  
- Capture or mock sample API JSON responses for backup slides.

Tell me which next step you'd like me to perform (I can create the MD file in your project now if you want).
