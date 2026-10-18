# CareVoice

**Everyday moments. A clearer care story.**

CareVoice helps parents and caregivers of young children with special educational needs record daily observations, prepare for appointments, find Hong Kong service information, and connect with other parents.

**[Open CareVoice](https://carevoice-preview-zeta.vercel.app)** · **[Latest web app source](https://github.com/Kesheeee/CareVoice-iOS/tree/feature/mobile-web)**

Track: **Smart Living, Culture & Belonging**

## Try the demo

Open [CareVoice](https://carevoice-preview-zeta.vercel.app) and sign in with:

- **Email:** `demo@carevoice.example`
- **Password:** `!Democare1`

This is a shared public demo account. Use sample information only; do not enter real family or child details.

## What you can do

| Feature | What it does |
| --- | --- |
| Daily tracker | Add, edit, and search observations; view recorded days and a logging streak. |
| Voice and audio upload | Record a short note or upload audio, review the transcript, then save it. Supported uploads include MP3, M4A, WAV, AAC, and FLAC, up to 60 seconds and 20 MB. |
| Observation questionnaire | Answer 33 questions across seven categories, skip questions, and review saved responses without a clinical score. |
| Ask CareVoice AI | Ask a question and receive a conversational reply with relevant suggestions resolved against the curated Hong Kong service directory. |
| Anonymous parent Q&A | Publish questions, reply to other parents, report content, and remove your own posts. Your name is hidden from other members. |
| Appointment reports | Bring observations, questionnaire responses, and questions together for a professional conversation; share text or print to PDF. |
| Profile and next steps | Update your child profile, choose your care journey stage, and explore relevant checklists and official resources. |
| Language and backups | Use English, Traditional Chinese, or Simplified Chinese; export and restore local notebook backups. |

CareVoice is a development MVP. It does not diagnose conditions, calculate clinical risk scores, or replace professional advice. Questionnaire responses do not automatically change a caregiver's selected journey stage.

## Repository and branches

This repository is **public**. Anyone can view or clone it; pushing changes requires collaborator access.

- **`feature/mobile-web`** contains the current React web app, FastAPI AI backend, Supabase functions, and native iOS sources. Use this branch to work on the deployed web experience.
- **`main`** contains the earlier native iOS baseline. It does not yet contain the full web/backend implementation.

```sh
git clone --branch feature/mobile-web https://github.com/Kesheeee/CareVoice-iOS.git
cd CareVoice-iOS
```

## How it works

```text
React web app on Vercel
  ├─ Supabase Auth                       Account sign-in
  ├─ Local browser storage               Profile, observations, questionnaire
  ├─ FastAPI on Fly.io → DeepSeek         AI replies and directory suggestions
  ├─ Supabase transcribe → Azure Speech   Audio-to-text
  └─ Supabase anonymous-qna → Postgres    Shared questions and replies
```

The current web chat uses **FastAPI**, not the alternative `ask-carevoice` Supabase function retained in this repository. Voice transcription and parent Q&A use Supabase Edge Functions.

| Path | Purpose |
| --- | --- |
| `mobile/` | React, TypeScript, Vite, and Capacitor configuration |
| `backend/` | FastAPI routes, curated JSON directory, and AI integration |
| `supabase/functions/` | Transcription, anonymous Q&A, and alternative AI function |
| `supabase/migrations/` | Community database schema and access controls |
| `CareVoice/` | Native SwiftUI app |
| `CareVoice.xcodeproj` | Xcode project |
| `Tests/` and `CareVoiceUITests/` | Native domain and UI tests |
| `docs/` | Setup, validation, and implementation notes |
| `scripts/` | Native project and review-file generators |

## Run the web app

Use Node.js 22.18+ or Node.js 24 and npm. The current development build uses Node.js 24.

```sh
cd mobile
npm ci
```

Copy `mobile/.env.example` to `mobile/.env.local` and set the public backend address:

```dotenv
# Local FastAPI server:
VITE_BACKEND_URL=http://localhost:8000
```

For an authorized test against the shared deployed backend, use `https://backend-silent-pebble-1702.fly.dev` instead. Never put provider API keys in a `VITE_` variable: these values are included in the browser bundle.

```sh
npm run dev
```

Open the URL printed by Vite, normally `http://localhost:5173`. Microphone capture needs localhost or HTTPS; a plain HTTP LAN address on a phone is insufficient.

The web client currently points to the shared CareVoice Supabase project in `mobile/src/platform/auth.ts`. To run an independent installation, replace that public URL and publishable key with your own project configuration, deploy its functions and migrations, and configure Auth redirect URLs. Do not use a service-role key in the client.

See the [web development guide](https://github.com/Kesheeee/CareVoice-iOS/blob/feature/mobile-web/mobile/README.md).

## Run the AI backend

Python 3.12 matches the container configuration.

```sh
cd backend
python -m venv .venv
# macOS/Linux:
source .venv/bin/activate
# Windows PowerShell instead:
# .venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Copy `backend/.env.example` to `backend/.env` and configure `LLM_API_KEY` on the server. The default provider is DeepSeek, with `LLM_BASE_URL=https://api.deepseek.com` and `LLM_MODEL=deepseek-chat`.

```sh
uvicorn app.main:app --reload --port 8000
```

- Health: `http://localhost:8000/health`
- Interactive API docs: `http://localhost:8000/docs`
- AI endpoint: `POST /ask` with `message` and `language`

The checked-in `backend/data/` JSON files supply the directory and citations. These are snapshots, not a live waiting-list feed. See the [backend guide](https://github.com/Kesheeee/CareVoice-iOS/blob/feature/mobile-web/backend/README.md) for endpoints, data updates, and deployment.

## Supabase services

The web app uses Supabase for accounts, shared Q&A, and the voice transcription gateway. Personal tracker records are still local; signing in on another device does not sync them.

- [Voice transcription setup](https://github.com/Kesheeee/CareVoice-iOS/blob/feature/mobile-web/supabase/functions/transcribe/README.md): keep `AZURE_SPEECH_KEY` and `AZURE_SPEECH_REGION` in Edge Function secrets. Audio goes to Azure Speech through the authenticated function; the function does not save audio or transcripts to a table or bucket.
- [Anonymous Q&A setup](https://github.com/Kesheeee/CareVoice-iOS/blob/feature/mobile-web/supabase/functions/anonymous-qna/README.md): apply the Q&A migration and deploy the authenticated function. Anonymity is relative to other parents, not administrators. Moderation is manual.
- [Account and native community notes](https://github.com/Kesheeee/CareVoice-iOS/blob/feature/mobile-web/docs/COMMUNITY_SETUP.md): check the actual project's email confirmation, SMTP, and redirect configuration when setting up an installation.

## Deploy

### Web app → Vercel

Set `VITE_BACKEND_URL` to the deployed HTTPS API address **before building**. Vite embeds it at build time; changing a hosting variable after uploading an existing bundle does not update that bundle.

From `mobile/`:

```sh
npm run build
cd dist
npx vercel link --project carevoice-preview --scope kesheeees-projects
npx vercel deploy --prod --scope kesheeees-projects
```

Those project/team names are for authorized CareVoice maintainers. Forks should link their own project. The build output is `mobile/dist`. Keep `.env` files, tokens, and `.vercel` files out of commits.

### AI backend → Fly.io

`backend/fly.toml` targets the existing CareVoice API app. Configure provider secrets in Fly.io, then run `fly deploy` from `backend/` with an authorized account. For your own installation, create your own Fly app and update the app name first. Check `/health` and a synthetic `/ask` request after deployment.

The backend's allowed browser origins are in `backend/app/config.py`. Add a new frontend origin there when changing domains. Frontend and backend are separate deployments; publishing one does not publish the other.

## Native iOS

On macOS, open `CareVoice.xcodeproj` in Xcode 16 or newer, select the **CareVoice** scheme and an iPhone simulator, and run. Minimum target: **iOS 17**. A physical iPhone requires signing with your Apple development team.

The native app uses SwiftUI and Apple's speech recognition. Web and native feature parity is not complete; do not assume the web AI and audio-upload integrations are available in SwiftUI. See the [parity notes](https://github.com/Kesheeee/CareVoice-iOS/blob/feature/mobile-web/docs/SWIFT_PARITY.md).

## Checks

From the repository root:

```sh
npm --prefix mobile run build
npm --prefix mobile test
node --experimental-strip-types --test mobile/tests/audio-upload.test.ts mobile/tests/streak.test.ts mobile/tests/transcribe.test.ts
```

Browser tests live in `mobile/tests/browser/`. Start the web development server separately, then run `npx playwright test` from `mobile/` after installing Playwright's Chromium browser. Some tests target earlier preview behavior and may need updating as integrations change. Mocked browser tests do not establish that production provider credentials work.

For native changes on macOS:

```sh
swift test
xcodebuild -project CareVoice.xcodeproj -scheme CareVoice \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

Test microphone capture, permissions, uploads, and PDF sharing on real devices before a release.

## Data and current limitations

- Personal web notebooks are stored per account in the current browser and origin. Browser storage is not encrypted by CareVoice; clearing it can remove records. Export a JSON backup before moving devices.
- AI questions are sent to the FastAPI backend and its model provider. Tracker history is not automatically attached to a question.
- Shared Q&A content is stored remotely. Publishing is explicit; remove identifying details before posting.
- Exported reports and backups are independent copies; deleting app data does not revoke them.
- The current FastAPI `/ask` route does not enforce Supabase authentication or per-user quotas. Add server-side access and usage controls before a broader rollout.
- Google/Apple sign-in, automatic family-record sync, clinical diagnosis, and live service availability are not implemented.

## Contributing

Create a feature branch from the branch you intend to change, keep commits focused, and open a pull request against that same development line. Current web/backend changes target `feature/mobile-web`; coordinate any merge into `main` with the team.

The owner can grant write access through **Settings → Collaborators**. Public visibility allows viewing and cloning, not direct write access. Never commit API keys, `.env` files, or real family records. See [CONTRIBUTING.md](https://github.com/Kesheeee/CareVoice-iOS/blob/feature/mobile-web/CONTRIBUTING.md) for native code conventions.

## Team

| Member | University |
| --- | --- |
| Rosario Justin Ram Baluyos | Hong Kong University of Science and Technology |
| Lo Hei Yiu Queenie | The Chinese University of Hong Kong |
| Tsai Chiu Yu | Hong Kong University of Science and Technology |
| Xie Siying | The University of Hong Kong |
| Ng Hon Kit | The University of Hong Kong |
| Cao Yuecheng | The University of Hong Kong |
