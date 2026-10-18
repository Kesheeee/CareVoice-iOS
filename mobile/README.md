# CareVoice mobile web

A phone-first React + TypeScript version of CareVoice. English and Traditional Chinese, with 33 questions: 31 verbatim Cantonese prompts from Queenie’s onboarding document and two additional safety prompts for seizures and self-injury. The existing native iOS project remains alongside it.

The current UI follows the blue Cici UI+UX_1013 v4 reference, with subtitles removed. Queenie's onboarding rules override the mockup's score/results screen: Welcome → child profile → caregiver-selected stage → questionnaire introduction only for the just-noticing stage → answer review → Home. All other stages go straight to Home; everyone can open the questionnaire voluntarily from Profile.

Home shows actual monthly record counts and questionnaire completion, not clinical scores. Records link earlier entries only by an explicitly chosen category. Community contains official resources, parent support links and information questions rather than a live forum. Loss-of-skills Yes/Not sure surfaces an official professional contact route immediately and offers an optional timing note. Existing professional report details are optional copies, never inferred. Quick Record can use the microphone directly through the browser's speech-recognition service; only reviewed text is saved.

The additional `regressionWhen` and professional-report fields are optional additions to schema version 1. Older saved data and backups load without migration or deletion. See `design.md` for the shared design system.

## Run

```sh
npm ci
npm run dev
npm run build
npm test
```

The development server is available on your local network. Open the printed Network address on a phone connected to the same Wi-Fi. For a home-screen install, use HTTPS hosting. The current version does not cache the app offline.

## Implemented

Profile with caregiver-selected journey stages; observation create/edit/delete, context and filters; questionnaire with autosave, skip, review and immediate loss-of-skills, seizure and self-injury routing; personal journey checklist; official resource links; family/appointment reports, text sharing/download and browser print-to-PDF; local backup/restore and delete-all. No diagnosis or scores. Voice entry includes a direct microphone action, live transcript, Stop control and a 60-second limit.

### Direct voice entry

Records → **+** → **Voice record** → **Start recording** calls the browser's `SpeechRecognition` / `webkitSpeechRecognition` API after an explicit tap. Select English, Cantonese or Mandarin; support depends on the browser's speech service. Microphone/speech permission and HTTPS are required. No OpenAI key or server endpoint is used. The browser provider may process audio remotely; the UI discloses this before recording. CareVoice retains no audio file and never saves a note automatically.

Final recognised phrases appear in the draft; interim text stays separate. Stop waits for a final result, then the user can edit and save. Record more appends to existing text. Cancel, closing the panel, navigation and unmount release capture; backgrounding stops recording. Permission, device, network, unsupported-language, silence and timeout errors preserve existing text and provide retry or Text record. Browser implementations may end earlier than 60 seconds after silence.

References: [SpeechRecognition and browser compatibility](https://developer.mozilla.org/en-US/docs/Web/API/SpeechRecognition), [stop and final results](https://developer.mozilla.org/en-US/docs/Web/API/SpeechRecognition/stop).

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

New visitors see a full-screen video welcome. Get started opens account provider
choices; the existing-account action opens the sign-in form. Email sign-in is
connected to the CareVoice Supabase project: email links, optional emailed codes,
and existing email/password accounts. Google and Apple remain previews.
The public publishable key is bundled; no service-role key is used. Supabase
persists and refreshes the browser session. Notes remain local, scoped by account
ID, with an explicit choice before copying an existing preview notebook.
Local survey setup
is available at `/#onboarding`: nickname, birthday, seven Phase 1 journey stages,
support goals, and optional notes. Returning local profiles open Home.
Settings contains profile editing, language, care tools, backups, and privacy.
Bottom navigation uses icons with accessible labels.

### Email delivery setup

The Supabase Site URL is `https://carevoice-preview-zeta.vercel.app/`.
Keep this URL in sync with the deployment domain. The client requests that origin
as its email redirect; additional preview/local origins must be explicitly allowed
in Supabase before real email links can return to them.

The project currently uses Supabase's default sender and unchanged templates.
That sender is restricted to project-team addresses and has a low email rate
limit. Configure custom SMTP in Supabase before offering email login to the
public. Do not disable email confirmation to work around delivery restrictions.
See [Supabase email delivery](https://supabase.com/docs/guides/auth/auth-smtp).

`tests/browser/auth.spec.ts` intercepts Auth requests with synthetic fixtures:
these tests never send real email or create production accounts. Real email
delivery and link opening must be checked separately.

The welcome and sign-in background uses an eight-second portrait Higgsfield-generated
parent-and-child video (`carevoice-family-hd.mp4`, original 720 × 1280 quality) and matching poster, served locally from
`public/media/`. It loops without playback controls and shows the poster instead
when reduced motion is requested or video playback fails. The login form does
not depend on video playback or a Higgsfield connection at runtime.

Data is local to this browser and origin, schema version 1, with no analytics, login or cloud sync. CareVoice does not encrypt browser storage. Clearing browser data can erase records. Download a JSON backup to transfer between devices or future native builds. Restore validates the schema before replacing current data. A failed/corrupt read blocks writes to preserve the saved copy. Reports are independent copies once exported.

The original Swift app's persisted JSON uses a different date/enum representation; automatic Swift-to-web data migration is not implemented.


## Questionnaire revision — 15 October 2026

Source: `Queenie_CareVoice Categorising Suspected ASD for Onboarding_.docx`. Frequency choices are Never / Sometimes / Often / Not sure; play variety has its own choices. Regression uses Yes / No / Not sure plus optional timing. Skip remains available for every question, resolving the document’s conflicting mandatory-regression instruction in favour of the user’s explicit requirement. No answer changes the caregiver-selected stage or produces a clinical score.

New question IDs 101–133 avoid assigning old answers to rewritten prompts. IDs 1–30 remain valid in storage and backups; reports include those responses under an earlier-questionnaire heading with original wording. Current completion counts exclude earlier responses. The optional timing note for the new regression item uses ID 131.

Safety Yes / Not sure on items 132–133 immediately displays conditional Hong Kong emergency routing and prompt medical follow-up, without interpreting the cause. It remains available on Home and Reports after reload. Emergency calls require the user to tap the phone link. The two safety prompts are implementation additions, not verbatim Queenie quotations. No unverified milestone ages or screening thresholds are used.

Official routes checked 15 October 2026:
- DH CAS concerns and referral: https://www.dhcas.gov.hk/en/faq.html
- FSD emergency ambulance: https://www.hkfsd.gov.hk/eng/source/safety/uambu.htm
- HA A&E directory: https://www.ha.org.hk/visitor/ha_visitor_index.asp?Content_ID=200246&Lang=ENG&Parent_ID=0
