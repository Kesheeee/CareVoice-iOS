# CareVoice mobile web

Phone-first React 19 + TypeScript + Vite app, deployed at **https://carevoice-preview-zeta.vercel.app**. Use the `feature/mobile-web` branch for the current implementation. See the [project README](../README.md) for the product overview and team.

## Features

- Home shortcuts, daily tracker, calendar, and logging streak.
- Voice recording and audio upload with an editable transcript before saving.
- 33 observation questions across seven categories, with autosave, skip, and review.
- Ask CareVoice AI replies and curated service suggestions through FastAPI.
- Live anonymous parent questions and replies through Supabase.
- Caregiver-selected journey stage, personal checklists, profile editing, and settings.
- Appointment/family reports, text export, browser print-to-PDF, and JSON backup/restore.
- English, Traditional Chinese, and Simplified Chinese.

No questionnaire score or diagnosis is produced. The native SwiftUI app is a separate implementation; see [parity notes](../docs/SWIFT_PARITY.md).

## Local setup

Use Node.js 22.18+ or 24 and npm.

```sh
npm ci
```

Copy `.env.example` to `.env.local`:

```dotenv
VITE_BACKEND_URL=http://localhost:8000
```

Run the [FastAPI backend](../backend/README.md) separately, or use its deployed HTTPS URL for authorized testing.

```sh
npm run dev
npm run build
npm test
```

Vite prints the local and network addresses. Phone microphone capture requires HTTPS; a plain HTTP LAN URL is not sufficient. There is no offline app cache.

## Service connections

| Feature | Implementation |
| --- | --- |
| Accounts | Supabase email/password authentication in `src/platform/auth.ts` |
| AI | `src/platform/ask.ts` calls `VITE_BACKEND_URL/ask` |
| Voice | Supabase `transcribe` Edge Function calls Azure Speech |
| Parent Q&A | Supabase `anonymous-qna` Edge Function and Postgres |
| Personal notebook | Local storage scoped to account and browser origin |

The Supabase public URL and publishable key currently live in `src/platform/auth.ts`. Replace them for your own installation and deploy the matching functions/schema. Provider keys and Supabase service-role credentials belong only on servers.

The AI URL falls back to `http://localhost:8000` if unset. A production build must set the HTTPS backend address explicitly; otherwise visitors will attempt to contact their own device. Vite variables are baked into the bundle, so rebuild after changing them.

The alternative Supabase `ask-carevoice` function is retained in the repository but is not the current web chat route.

## Voice and uploaded audio

Open Quick Record, select **Voice record**, and record or upload an audio file. The normal voice path converts audio to mono 16 kHz WAV and sends it through the authenticated Supabase function to Azure Speech. Review and edit the returned text before saving.

Uploads support MP3, M4A, WAV, AAC, and FLAC, capped at 60 seconds and 20 MB. The client checks file signatures and decodes audio; an audio-looking filename alone is insufficient. Browser support for individual codecs can vary.

English, Cantonese, and Mandarin are supported recording-language options. Permission errors, cancellation, and transcription failures preserve the existing draft. Audio is not saved to the notebook or a Supabase bucket by this flow. See [transcription setup](../supabase/functions/transcribe/README.md). `VITE_VOICE_BACKEND=browser` selects the browser-speech fallback where supported.

## Accounts and data

Email/password sign-up, sign-in, and password recovery use Supabase Auth. Google and Apple options remain previews. Confirmation and email delivery depend on the project's actual Auth settings; configure SMTP and allowed redirect URLs for your deployment. The shared production origin is `https://carevoice-preview-zeta.vercel.app`.

Profiles, questionnaire answers, and observations remain local to this browser and account. There is no family-record cloud sync or CareVoice encryption of browser storage. Clearing browser data may erase the notebook. JSON backup/restore supports moving compatible web data; automatic Swift-to-web migration is not implemented. Exported PDFs remain independent copies.

Anonymous Q&A is shared remotely. Other members see an anonymous identity, while administrators can associate content with accounts. Publishing requires an explicit action. See [Q&A setup and moderation](../supabase/functions/anonymous-qna/README.md).

## Questionnaire compatibility

Current question IDs are 101–133. Earlier IDs 1–30 remain readable in backups and appear separately in reports. Do not renumber persisted answers. Optional timing and professional-report fields remain compatible with schema version 1.

Questions include prompts for loss of skills, seizures, and self-injury. Relevant responses show professional contact guidance without assigning a diagnosis. The caregiver chooses the journey stage.

## Tests

`npm test` runs the domain and speech tests. Additional checks:

```sh
node --experimental-strip-types --test tests/audio-upload.test.ts tests/streak.test.ts tests/transcribe.test.ts
npx playwright install chromium
```

Start `npm run dev` in another terminal, then run `npx playwright test`. The suite includes earlier preview-state fixtures; update affected expectations when changing integrations. Mocked tests do not validate live Azure/AI credentials. Test Safari permissions and actual uploads on a physical phone.

## Deploy

Set the production `VITE_BACKEND_URL` before `npm run build`. Upload the resulting `dist/` directory to Vercel; see [deployment steps](../README.md#deploy). AI backend deployment is separate.

The welcome video and illustrations are served from `public/media/`. They do not require a media-generation service at runtime. Reduced-motion/video-failure behavior uses the poster image.

## Native packaging

`capacitor.config.ts` points to `dist` and uses `com.carevoice.mobile`. Native Capacitor projects are not generated in this repository. Packaging requires platform tooling and additional validation for permissions, protected storage, sharing, safe areas, and lifecycle. The existing `CareVoice.xcodeproj` is the separate SwiftUI app.
