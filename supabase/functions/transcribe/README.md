# Voice transcription deployment

Flow: signed-in browser → Supabase `transcribe` function → Azure Speech → editable text.
The browser converts Safari MP4 / Chrome WebM into 16 kHz mono PCM WAV, capped at 60 seconds.
No audio or transcript is written to a Supabase table or bucket. Saving reviewed tracker text continues to use the existing app store.

The endpoint checks the Supabase user token, rejects anonymous users, validates WAV format and size, and times out the provider request after 45 seconds. Secrets and provider error bodies are never returned or logged.

## Activate

1. Authenticate locally with `npx supabase login`.
2. In the project's Edge Function secrets page, set `AZURE_SPEECH_KEY` and `AZURE_SPEECH_REGION` for your Azure Speech resource. Do not put these in Vite variables or Git.
3. From the repository root deploy:

   `npx supabase functions deploy transcribe --project-ref lbbpuwtwhiectsmhhuej --use-api`

4. Build the web app with `VITE_VOICE_BACKEND=supabase` and deploy that build to Vercel. Until then, the existing browser speech path remains active.
5. Sign in with a test user. Record a short phrase in English, Cantonese and Mandarin, stop, review the transcript and save. Verify permission rejection, cancellation, and offline errors on a real iPhone Safari. Confirm an unauthenticated endpoint request returns 401.

Tests: `node --experimental-strip-types --test mobile/tests/transcribe.test.ts`.
These test the endpoint with a fake speech provider; they do not confirm live Azure credentials or iPhone microphone access.

References: https://supabase.com/docs/guides/functions/auth and https://learn.microsoft.com/en-us/azure/ai-services/speech-service/rest-speech-to-text-short
