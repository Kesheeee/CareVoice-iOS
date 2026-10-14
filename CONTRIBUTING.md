# Working on CareVoice

## Source map

| Path | Responsibility |
| --- | --- |
| `CareVoice/Core/Models.swift` | Codable domain models, questionnaire answers, related records and report text; Foundation only |
| `CareVoice/AppStore.swift` | Main-actor state, atomic persistence and file protection |
| `CareVoice/CareVoiceApp.swift` | App entry, navigation, reusable card/button styling |
| `CareVoice/Features/Onboarding.swift` | Welcome and profile editing |
| `CareVoice/Features/Home.swift` | Home, questionnaire, response summary and follow-up message |
| `CareVoice/Features/Records.swift` | Record list, search, editor and detail |
| `CareVoice/SpeechRecorder.swift` | Apple on-device speech recognition lifecycle |
| `CareVoice/Features/Resources.swift` | Official sources and stage-specific checklists |
| `CareVoice/Features/ReportsAndProfile.swift` | PDF generation, share sheet and settings |
| `CareVoice/Resources/questions.json` | 30 bilingual observation prompts |
| `Tests/CareVoiceCoreTests` | Domain tests run by `swift test` |
| `CareVoiceUITests` | Simulator flows run by Xcode Test |

The app compiles the domain files directly. `Package.swift` exposes the same files as a separate package so core tests run without a simulator. The app has no external packages.

## Adding files

Add your Swift file to the appropriate folder, then run:

```sh
python3 scripts/generate_project.py
```

The generator is deterministic. Commit both the new file and project change. If you alter build settings, update the generator too. Do not commit signing identities, personal team IDs, Xcode user data, build outputs, or real family records.

## Development checks

- Run `swift test` for domain changes.
- Build the app for a simulator after SwiftUI or resource changes.
- Run `CareVoiceUITests` for user-flow changes. Find device names with `xcrun simctl list devices available`.
- Check both languages, Dynamic Type, light/dark appearance, VoiceOver labels, empty states and cancel/error flows.
- Voice recognition needs a real-device test for each supported locale. Never silently fall back to server recognition.
- Every new observation question needs a stable ID; do not renumber stored answers without a migration.
- Any change to persisted data needs a version/migration strategy and round-trip tests.
- Keep the distinction between parent-selected stage, observations and clinician-provided information. Never derive clinical scores from this questionnaire.

## Git workflow

One feature branch per change; pull requests into `main`; review each other's changes. Pull the latest main before branching. Resolve project changes by updating the generator and regenerating, rather than hand-merging generated IDs.

## Privacy

The checked-in app contains no credentials. Never add a live API key to an iOS client. A future server-backed integration needs explicit data consent, access controls and server-held credentials. The current MVP has no server dependency.

## Optional GitHub Actions

`docs/ios-ci.yml` is a ready-to-use build/core-test workflow template. To activate it, an owner can copy it to `.github/workflows/ios.yml` using GitHub's file editor or push it with a credential that has workflow permission. It is supplied as a template because the uploader's existing Git credential does not have that scope.
