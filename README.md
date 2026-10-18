# CareVoice for iOS

## Native iPhone and mobile preview

The iPhone app in `CareVoice/` follows the current `mobile/src/` TypeScript experience. Open `CareVoice.xcodeproj` for the app, or review [`review/CareVoiceComplete.swift`](review/CareVoiceComplete.swift) for all native code in one file. That file is generated from the app sources. See [the parity map](docs/SWIFT_PARITY.md) for screen mapping and platform differences.

### Phone browser preview

The cross-platform phone version is in [`mobile/`](mobile/README.md). It runs in a phone browser now and uses React, TypeScript and a Capacitor configuration for later Android/iOS packaging. From `mobile/`, run `npm ci` then `npm run dev`, or `npm run build` for the static bundle. See its README for features, local data handling and native packaging steps.

A native SwiftUI MVP for Hong Kong caregivers of children aged 0–6. English, Traditional Chinese and Simplified Chinese. The latest phone UI follows the TypeScript preview, while using native SwiftUI controls.



## Run it

1. Clone this **private** repository after accepting your collaborator invitation:
   ```sh
   git clone https://github.com/Kesheeee/CareVoice-iOS.git
   cd CareVoice-iOS
   ```
2. Open `CareVoice.xcodeproj` in Xcode 16 or newer.
3. Select the **CareVoice** scheme and an iPhone simulator, then press **Run**.
4. For a physical iPhone, choose your Apple development team under **Signing & Capabilities**. Change the bundle identifier if your team needs a unique identifier. An Apple developer account is not needed for the simulator.

Minimum deployment target: **iOS 17**. Email/password sign-in uses the same Supabase project as the phone preview. After sign-in, observation data is stored locally per account. The optional shared parent community requires the configuration described in [Community setup](docs/COMMUNITY_SETUP.md). The checked-in Xcode project is ready to open.

For the current testing setup (18 October 2026), email confirmation is disabled on the shared backend. New accounts use email and password and enter the app when the server issues a session. Email ownership is not verified in this mode; password recovery still depends on email delivery. See [authentication setup](docs/COMMUNITY_SETUP.md) before a public pilot.

## What works

- Five-page survey: optional nickname, birthday, seven parent-selected journey stages, support goals and optional notes.
- English, Traditional Chinese and Simplified Chinese across home, profile, resources and navigation.
- The same 33 observation questions as TypeScript, autosave, skip, “Not sure”, review and immediate professional-follow-up guidance for reported/uncertain loss of skills.
- Create/edit/delete timestamped observations; categories, place, duration, context and what helped; search and filters.
- On-device speech transcription where Apple's recognizer supports the selected locale. Permission and availability failures offer text input. Voice capture stops after 60 seconds or on backgrounding. Audio is not saved.
- Stage-specific personal checklists linked to official DH/SWD information.
- Family and appointment reports, text sharing/download and multipage PDF printing/sharing through the iOS share sheet.
- Per-account local persistence with iOS complete file protection; portable JSON backup/restore; no family-data cloud sync; delete-all control.

## Work together

The repository must remain **Private**. The owner can invite your partner at:
https://github.com/Kesheeee/CareVoice-iOS/settings/access

Invite their GitHub username as a collaborator with write access. They must accept the invitation before cloning. A repository link alone does not grant access.

Use a branch for each change:

```sh
git switch -c feature/your-feature
# Edit and test in Xcode
git add .
git commit -m "Describe the change"
git push -u origin feature/your-feature
```

Open a pull request into `main` and ask your partner to review. See [CONTRIBUTING.md](CONTRIBUTING.md) for the source map and test commands.

## Product boundaries

This is a working development MVP, not a clinically validated screening tool or an App Store release. It produces no risk score, severity level, diagnosis or automated clinical interpretation. A journey stage comes only from the caregiver's selection. Related records are grouped by the chosen category, not AI inference.

The app stores records on one device. Data is excluded from device backups, so uninstalling the app or losing the device may lose it. Exported PDFs are copies and cannot be revoked by deleting app data. The parent community has an optional Supabase backend for accounts, posts, replies, reports, blocking and moderation; see [Community setup](docs/COMMUNITY_SETUP.md). The native Community screen includes Parent conversations using the existing CareVoice login alongside the official-resource directory. TypeScript currently shows resources only. Family sync, AI tagging/follow-up, and live waiting-list integrations are not implemented. See [the handoff notes](docs/HANDOFF.md).

## Verification

```sh
swift test
xcodebuild -project CareVoice.xcodeproj -scheme CareVoice \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

For UI tests, choose an available iPhone simulator and run **Product → Test** in Xcode. The UI tests use a separate local file and synthetic observations. Test results include screenshots. See [docs/VALIDATION.md](docs/VALIDATION.md) for the actual checks run on the initial version.

## Source materials and official links

The questionnaire content is adapted from the supplied UI+UX_1013 English/Traditional Chinese question lists. The original DOCX, HTML and image pack are not included; the implementation and reconciliation notes are included.

- [DH CAS FAQ](https://www.dhcas.gov.hk/en/faq.html)
- [DH registration and appointments](https://www.dhcas.gov.hk/en/registration_appointment.html)
- [DH follow-up and referrals](https://www.dhcas.gov.hk/en/management_referral.html)
- [SWD central referral system](https://www.swd.gov.hk/en/pubsvc/rehab/cat_crsrehab/centralref/)
- [SWD on-site pre-school services](https://www.swd.gov.hk/oprs/index_en.htm)

Links reviewed 15 October 2026. Service eligibility and arrangements must be confirmed with the relevant professional or provider.
