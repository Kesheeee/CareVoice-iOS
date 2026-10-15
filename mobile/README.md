# CareVoice mobile web

A phone-first React + TypeScript version of CareVoice. English and Traditional Chinese, with the same 30 questions as the Swift app. The existing native iOS project remains alongside it.

## Run

```sh
npm ci
npm run dev
npm run build
npm test
```

The development server is available on your local network. Open the printed Network address on a phone connected to the same Wi-Fi. For a home-screen install, use HTTPS hosting. The current version does not cache the app offline.

## Implemented

Profile with six caregiver-selected journey stages; observation create/edit/delete, context and filters; questionnaire with autosave, skip, review and immediate loss-of-skills follow-up guidance; personal journey checklist; official resource links; family/appointment reports, text sharing/download and browser print-to-PDF; local backup/restore and delete-all. No diagnosis or scores. Voice entry uses the device keyboard's dictation rather than sending microphone recordings to a server.

## Android / iOS path

`capacitor.config.ts` already identifies the static `dist` bundle. React UI, typed domain models, bilingual JSON and storage/share adapters are separate. This web app does not depend on a remote web server or an SSR framework.

When native packaging is requested:

```sh
npm install @capacitor/android@^8 @capacitor/ios@^8
npx cap add android
npx cap add ios
npm run native:sync
npx cap open android
# On macOS with Xcode:
npx cap open ios
```

Build `dist` before syncing. Native projects are deliberately not generated yet. Android Studio/JDK and macOS/Xcode are required for the respective platform builds; review the current Capacitor environment requirements before packaging. The new bundle identifier is `com.carevoice.mobile` to avoid colliding with the existing Swift app during development.

Before a native release, replace `src/platform/storage.ts` with a native protected-file/encrypted-database implementation, implement native backup policy, and adapt sharing/permissions through Capacitor plugins as needed. Confirm external-link routing and Android back navigation, then validate safe areas, accessibility, dictation, sharing and lifecycle on physical devices. Packaging reuses the UI and domain code but does not replace release testing, signing or store requirements.

## Data

Data is local to this browser and origin, schema version 1, with no analytics, login or cloud sync. CareVoice does not encrypt browser storage. Clearing browser data can erase records. Download a JSON backup to transfer between devices or future native builds. Restore validates the schema before replacing current data. A failed/corrupt read blocks writes to preserve the saved copy. Reports are independent copies once exported.

The original Swift app's persisted JSON uses a different date/enum representation; automatic Swift-to-web data migration is not implemented.
