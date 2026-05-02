# GasGoJo

GasGoJo is a Flutter app for finding nearby gas stations and comparing prices quickly.

The current production deployment is web-first, backed by Firebase Hosting and Cloud Functions, with Firestore used for price storage and enrichment.

## Current Product State

### Implemented
- Nearby station discovery using Google Places (New) via a Firebase callable proxy.
- Station cards with brand logos, sorting, and filtering UI.
- Responsive layout:
  - Desktop: map + side panel.
  - Mobile/small screens: map fixed at the top section with a separate list section below (no draggable overlay conflict).
- Price blending model in Cloud Functions that combines baseline/API prices with community updates.
- Hosting deploy pipeline for Flutter web.

### In Progress / Partial
- Favorites and price alerts screens are present in routing/UI but are still being expanded.
- Authentication and deeper account workflows are scaffolded by dependencies but not finished end-to-end.

## Tech Stack

### Client
- Flutter, Dart
- flutter_bloc + go_router
- google_maps_flutter
- dio (HTTP)
- firebase_core, cloud_firestore, firebase_auth, firebase_messaging, firebase_remote_config, firebase_crashlytics

### Backend
- Firebase Cloud Functions v2 (Node.js 22 runtime)
- Firestore
- Firebase Hosting

## Project Structure

```text
lib/
  main.dart
  app/
  core/
  features/
  shared/
functions/
  index.js
web/
firebase.json
firestore.rules
```

## Local Setup

### 1. Prerequisites
- Flutter SDK (stable, Dart >= 3.3)
- Node.js 22+
- Firebase CLI
- FlutterFire CLI

### 2. Install Dependencies

```bash
flutter pub get
cd functions
npm install
cd ..
```

### 3. Configure Firebase

```bash
flutterfire configure --project=gasgojo-app-c4d11
```

This generates `lib/firebase_options.dart` for your local environment.

### 4. Configure Local Secrets

Create local keys from templates:

- Copy `lib/core/constants/api_keys.dart.example` to `lib/core/constants/api_keys.dart`
- Copy `functions/.env.example` to `functions/.env`

Then provide valid values for your environment.

## Google API Key Model (Important)

GasGoJo currently uses separated Google keys by execution context:

- Browser Maps JS key:
  - Used by `web/index.html` and web map initialization.
  - Restriction: HTTP referrers (your hosting domains).
  - API restriction: Maps JavaScript API.

- Server Places key:
  - Used by Cloud Functions (`functions/.env` as `GOOGLE_MAPS_API_KEY`).
  - Restriction: no referrer restriction (server-side), but API-restricted.
  - API restriction: Places API (New).

- Firebase auto-generated browser/android keys:
  - Keep these in place for Firebase SDK behavior.
  - Do not repurpose them for Maps/Places app traffic.

## Environment Variables

### functions/.env

```env
GOOGLE_MAPS_API_KEY=YOUR_SERVER_SIDE_PLACES_KEY
EIA_API_KEY=YOUR_EIA_API_KEY
```

## Run Locally

```bash
flutter run
```

## Seed Data (Optional)

You can seed sample Firestore data with:

```bash
node seed.js
```

And seed EIA baseline state prices with:

```bash
EIA_API_KEY=YOUR_EIA_API_KEY node seed_eia_prices.js
```

PowerShell equivalent:

```powershell
$env:EIA_API_KEY="YOUR_EIA_API_KEY" ; node seed_eia_prices.js
```

## Build and Deploy

### Web Build

```bash
flutter build web --release --no-wasm-dry-run
```

### Deploy Hosting

```bash
firebase deploy --only hosting --project gasgojo-app-c4d11
```

### Deploy Functions

```bash
firebase deploy --only functions --project gasgojo-app-c4d11
```

### Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules --project gasgojo-app-c4d11
```

## Architecture Notes

- The app uses a repository pattern for station data, with Firebase-backed and offline-fallback behavior.
- Places requests are routed through Cloud Functions to avoid browser CORS/key leakage risks.
- Community reports are stored in Firestore and can be blended into station pricing.

## Coming Soon

GasGoJo is moving toward a stronger community-driven pricing loop.

Users will be able to submit on-site fuel prices directly from station pages, and those reports will feed into the station data model so nearby drivers can see fresher, more representative local prices.

The objective is to improve real-world price accuracy through active user participation while preserving data quality through backend validation and rate controls.

## Open Source

GasGoJo is open source and welcomes contributions from the developer community.

### How to Contribute
- Open an issue for bugs or feature requests.
- Start a discussion for product or architecture proposals.
- Submit a pull request for code improvements.

If you want to collaborate closely on roadmap items, start by opening an issue or discussion in this repository.

## Brand Logos and Trademarks

GasGoJo may display third-party station names, logos, and other brand identifiers for identification and informational purposes.

- Third-party trademarks, logos, and brand names remain the property of their respective owners.
- Inclusion in this project does not imply endorsement, sponsorship, or partnership.
- Project contributors must not modify third-party marks in a way that suggests ownership or affiliation.
- If a rights holder requests an update or removal, please open an issue in this repository and the request will be reviewed promptly.

## License

This project is licensed under the MIT License.

- Author: Joanne Liszewski
- Effective Date: May 2, 2026

See the [LICENSE](LICENSE) file for full terms.
