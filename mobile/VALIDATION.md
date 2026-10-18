# Mobile web verification

## Direct microphone transcription — 18 October 2026

TypeScript/Vite production build and all 16 domain/speech unit tests passed. Seven speech tests cover cumulative/interim results, duplicate prevention, finalisation, permission errors, cancellation, stale events, the 60-second limit, unsupported browsers, silence and provider timeouts. Two isolated Chromium browser tests with a simulated speech engine verify tap-only capture, typed-note preservation, multiple recording segments, explicit Save persistence, Cancel cleanup and permission-denied fallback. No microphone or real speech service was used by these automated tests.

The live local UI was checked at 320, 375, 414 and 768px widths: no horizontal overflow, dialog fits, Start recording and footer controls remain visible. Real microphone permission, transcription quality, Cantonese/Mandarin availability and Safari/iPhone speech service behavior still need physical-device verification. Audio is processed by the browser's speech service; CareVoice saves reviewed text only. No API key, audio file or new record schema is introduced.

## Cleaner Records

15 October 2026: production build and browser checks passed for the new Records toolbar, add action, voice/report menu, search, category chips, collapsed same-category related records, editing and deletion. Bilingual screen layouts fit 320/375/414/768px. Empty and populated 375px Records screens were visually reviewed. An accessibility-role issue on the native menu summary was corrected and the Records flow rerun successfully. No record schema or clinical logic changed.

## Cleaner Home

15 October 2026: production build and all 5 browser suites checked after the Home-only simplification. Both languages fit at 320/375/414/768px. Home retains profile editing, observation capture, questionnaire access, next steps, reports and recent-record editing. Repeated statistics and progress displays were removed. Data and clinical logic are unchanged.

## General UI UX pass

15 October 2026: production build and all 5 existing browser suites passed after navigation, typography, recording-action and form layout changes. A 375×812px phone check verified the profile Save action stays on screen while fields scroll and that duplicate top navigation is hidden. Home, Profile and Records screenshots were visually reviewed. Bilingual layouts continue to fit 320/375/414/768px. No business logic, data schema or clinical rules changed.

## Blue reference update

15 October 2026: production TypeScript/Vite build, 7 domain tests and 5 Chromium browser suites passed. The new suites verify stage-gated onboarding across all six stages, optional manual questionnaire access, autosave/skip, immediate regression follow-up and source link, timing notes, English/Traditional Chinese reports, record methods and category-based related entries, persistence/edit/search/delete, older version-one data, and professional report copy fields. Phone layouts across Welcome, Home, Records, Community, Profile and the editor were checked in both languages at 320/375/414/768px. Descriptive subtitles stay absent. Physical-device keyboard dictation, native builds and Safari remain unverified.

The score/severity/inferred-stage results in the reference mockups were deliberately replaced by a response review, following Queenie's brief. Age is entered in years/months; real names, photographs and exact birth dates are not collected.

15 October 2026, Windows / Node 24 / Chromium automated browser checks.

- TypeScript check and Vite production build passed.
- Domain tests cover skipped answers, regression guidance independent of completion, report content, and invalid backup rejection.
- End-to-end flow passed: create profile, create observation, reload persistence, edit, search empty state, questionnaire save/next/review, question 29 immediate follow-up, Traditional Chinese switching, report content, observation deletion.
- Browser render checks passed at 320, 375, 414 and 768 pixels, in both languages; no page horizontal overflow, observation dialog fits.
- Home screen screenshot reviewed at 375px; corrected hidden file input styling and form accessible naming.

Not yet validated: physical devices, Safari/WebKit, OS share sheets, print-to-PDF output on each OS, native Android/iOS builds, keyboard dictation. App store delivery and encrypted native storage are future work. There is no service worker/offline shell in this first web build.
# Language chooser — 18 October 2026

- Settings opens a modal language chooser; selection applies only after Save. Cancel/Escape restore focus and keep the previous language.
- English, Traditional Chinese, and Simplified Chinese persist through reloads and backups. Simplified interface copy uses OpenCC with explicit wording for the chooser; caregiver notes and names are not converted.
- Browser tests cover all three selections, persistence, cancellation, and storage failure. Domain tests verify Simplified report labels while preserving original notes.
- Chromium and WebKit checks at 320, 375, and 414 × 667 confirm all three choices and actions fit without horizontal overflow. Physical iPhone testing remains outstanding.
# Email authentication — 18 October 2026

- Connected the Vercel email form to the existing CareVoice Supabase project using its public publishable key. Default email templates were not changed; email confirmation remains enabled.
- Changed Supabase Site URL from localhost:3000 to https://carevoice-preview-zeta.vercel.app/ through the authenticated dashboard. Custom SMTP is disabled; the default sender remains limited to project-team addresses.
- Live Vercel Continue action successfully requested one sign-in email for the user's supplied address. The UI showed Check your email. Inbox receipt and the real email-link round trip require user verification; no email account was read.
- Four isolated auth browser tests pass in Chromium and WebKit: request/failure states, expired verification code, password/session restoration/sign-out, and email callback with explicit preview-note import. Requests in these tests are mocked; no real emails or accounts are created by the tests.
- Seventeen domain/speech tests and thirteen focused Chromium browser tests pass. Production build passes. Account notebooks are stored separately on-device, with no record upload or cross-device sync.


18 October 2026 — password account flow:
- Continue with email now opens Create your account with repeated email and password confirmation; existing accounts use password login.
- Browser tests mock Supabase signup/login and verify mismatch blocking, confirmation-required gating, delivery errors, rejected/unconfirmed logins, account isolation, callback handling, and 320/375/414px layouts with accessible keyboard focus. No real emails or accounts are created by these tests.
- Email confirmation remains enabled. Public signup still requires SMTP configuration; this UI change does not remove that restriction. Set or reset password sends a recovery email; a verified recovery session opens the new-password form (including after refresh). Existing passwordless accounts can use this to establish a password.
- Production build and 17 unit tests pass. Seven auth browser tests pass in Chromium and WebKit; three-language phone form layout, reduced-motion video, and media-error handling are also checked. WebKit media-error testing dispatches the browser error event because media networking can bypass interception. Physical-phone inbox delivery remains unverified.
