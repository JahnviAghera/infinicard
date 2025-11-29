# Infinicard — User Flow

This document contains the user-flow diagram and explanation for the Infinicard mobile app. The visual flow is in `USER_FLOW.svg` (same folder).

![Infinicard User Flow](USER_FLOW.svg)

## Overview
The flow chart maps primary user actions and how they move through the app:

- Launch → Onboarding? → Auth check (Login/Register) → Home
- Home contains primary actions: My Cards, Create Card, Scan / Lens, Settings
- From Card Detail users can Share (Quick share or Export). Sharing includes:
  - Share as text (contains universal link `https://infinicard.app/c/{id}` + app-scheme fallback)
  - Export QR (app-scheme deep link or vCard payload)
  - Export vCard file (.vcf)
- Receivers tap the link or scan the QR which opens the app via App Links / Universal Links. The app navigates to `CardImportScreen` and fetches public card data from the API endpoint.

## Primary journeys (short)
- Create Card → Save → Card visible in My Cards
- Share Card → choose channel → recipient receives link or QR
- Receive link/scan → CardImportScreen → Save to contacts or Import to account
- Scan / OCR → parse text or vCard → prefill Create/Edit screen

## Where to find it
- File: `docs/USER_FLOW.svg` — open in any browser or image viewer to see the flow diagram.
- This Markdown file explains the steps and links to the SVG.

If you want a different format (PNG, PDF) or an expanded diagram showing more decision branches (error states, retries, permission prompts), tell me which areas to expand and I’ll add them.
696015137080
1956770036