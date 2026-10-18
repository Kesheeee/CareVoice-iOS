# TypeScript → native iPhone parity

The native app follows the phone experience in `mobile/src/`, using the TypeScript state at commit `3e05a59` as the comparison baseline. SwiftUI and TypeScript are separate implementations; changing one does not automatically translate its screens into the other.

| Phone preview source | Native source | Shared behavior |
| --- | --- | --- |
| SignInVideo, SignIn, password policy | Features/Account.swift, CommunityStore.swift, Core/PasswordPolicy.swift | Same parent/child movie, silent replay, email/password signup, one email field, password confirmation, five strength rules, real server sign-in and errors |
| GuidedOnboarding | Features/Survey.swift, Features/Onboarding.swift | One question per screen, birthday, seven pastel stage choices, optional goals/notes, bottom Continue, optional questionnaire for just-noticing stage |
| Dashboard | Features/Home.swift | Child summary, edit, add observation, journey/report shortcuts, questionnaire and recent records |
| RecordsScreen, RecordDetails, VoiceRecorder | Features/Records.swift, SpeechRecorder.swift | Tap to read details; explicit Edit, Add details and Reports actions; category-based earlier records; saving opens details; floating +, Voice/Text Quick Record sheet, 60-second transcription, collapsible details, pinned Cancel/Save |
| questions.json, SafetyRouting | Resources/questions.json, Features/Home.swift, Features/SafetyGuidance.swift | Exact same 33 prompts/IDs, special play answers, loss-of-skills and safety routing; old answers stay in reports/backups |
| Community | Features/Resources.swift | Official resources, parent support links and common questions; no fabricated AI or peer recommendations |
| Settings, LanguageSettings | Features/Settings.swift | Icon-only navigation, Profile, three-language chooser, current language at trailing edge, account sign-out, care tools, backup/restore and local deletion |
| ReportPreview, reportText | Features/ReportsAndProfile.swift, Core/Models.swift | Family/appointment formats, preserved notes, response summary, text export and PDF/print |
| storage | AppStore.swift, Core/BackupCodec.swift | Per-account local notebooks, explicit import of earlier guest notes, compatible portable JSON backups |

## One-file code review

`review/CareVoiceComplete.swift` is generated from **all actual native app Swift files**. It embeds the same JSON content. It is not a separate hand-maintained app. Regenerate with:

```sh
python scripts/generate_project.py
python scripts/sync_swift_review.py
python scripts/sync_swift_review.py --check
```

For the full app, open `CareVoice.xcodeproj` on a Mac. For an isolated one-file review, add only `review/CareVoiceComplete.swift` to a new iOS 17+ SwiftUI target, remove its starter app/view files, and copy `CareVoice/Resources/Media` into the target. Add the microphone/speech usage descriptions from the project generator. The movie and Google logo remain media assets rather than Swift source. Do not compile the review file alongside the normal app sources.

`review/CareVoiceSurveyReview.swift` is generated separately for survey-only previews.

## Native platform differences and external dependencies

- Sessions use Keychain; observations use protected per-account JSON files. Signing into another device does not sync family data. Backup/restore is the explicit transfer path. Previously saved native backups remain readable.
- Password-reset and confirmation emails open the existing HTTPS page, then users return to the iPhone app and sign in. Native universal-link/password-recovery routing has not been added. This avoids inventing an unconfigured app redirect.
- Testing configuration, 18 October 2026: Supabase **Confirm email is OFF**, with the owner's approval. Email/password signup can return a session immediately, which both clients use to enter the app. No confirmation email is required for new signup; email ownership is not verified in this mode. The setting lives in the shared backend, not in Swift or TypeScript. Both clients retain the confirmation screen for a user-only response if confirmation is enabled again. Password recovery still requires email delivery and remains subject to sender limits. No real account was created or password reset by this port.
- Google/Apple remain unconnected choices, matching the preview. Native speech uses Apple on-device recognition; availability depends on device and selected language. PDF/printing uses iOS’s share sheet.
- Native sheet heights, menus and system font metrics differ from Safari. Large accessibility text can scroll; the Continue/Save controls remain outside the scrolling content. Pixel-perfect parity and microphone permissions require physical-device review.
- Native Community now exposes Parent conversations above the official resources. Conversations reuse the existing CareVoice session: first-time members choose a nickname and accept the community guidelines; returning members open the feed. The standalone email-code flow has been removed. TypeScript still shows resources only; this native discussion entry is an intentional addition.
- Community account deletion removes the shared CareVoice authentication account, not just a nickname. The confirmation explains this and asks users to export local notes first.

## Verification

The GitHub `iPhone build` workflow compiles both the normal Xcode project and the isolated one-file app, runs Swift core tests, and exercises settings/languages, records, questionnaire navigation and signup validation on an iPhone simulator. It checks that the generated review is current and that question/video resources match TypeScript.

No web code is changed by this native port. Vercel continues to serve the TypeScript phone preview; Swift needs Xcode/TestFlight or an installed iPhone app.
