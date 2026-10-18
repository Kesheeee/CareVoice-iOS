# Ask CareVoice on Supabase

The web app invokes ask-carevoice with its signed-in Supabase session.
Render and VITE_BACKEND_URL are no longer needed for chat.
Set LLM_API_KEY (or DEEPSEEK_API_KEY) in Supabase Edge Function Secrets.
The key is used only server-side with api.deepseek.com, model deepseek-chat.
This endpoint sends the submitted question and bundled official-source directory
 to DeepSeek; it does not send child records or persist chat messages.
The directory and safety triggers are ported from backend/app and backend/data.
When updating curated data, sync the three bundled JSON files and triggers.
Unauthenticated and anonymous users are rejected. Inputs are bounded to 2000
characters, upstream requests time out at 45 seconds, and returned IDs are
resolved against the curated directory. Keyword screening is not comprehensive
clinical triage. Add durable per-user quotas before broader rollout.
