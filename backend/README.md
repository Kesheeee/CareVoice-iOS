# CareVoice API

FastAPI backend for curated Hong Kong service information and **Ask CareVoice AI**. The deployed web app sends AI questions here; authentication, parent Q&A, and its normal voice path use Supabase separately.

Current shared API: **https://backend-silent-pebble-1702.fly.dev**

## Setup

Python 3.12 matches the Docker image.

```sh
cd backend
python -m venv .venv
# macOS/Linux:
source .venv/bin/activate
# Windows PowerShell instead:
# .venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Copy `.env.example` to `.env` and set server-side variables:

| Variable | Purpose |
| --- | --- |
| `LLM_API_KEY` | Model-provider key required for AI replies |
| `LLM_BASE_URL` | Defaults to `https://api.deepseek.com` |
| `LLM_MODEL` | Defaults to `deepseek-chat` |
| `CAREVOICE_DATA_DIR` | Optional directory override; defaults to `backend/data` |
| `AZURE_SPEECH_KEY` | Required only for this API's separate transcription endpoint |
| `AZURE_SPEECH_REGION` | Speech region, defaults to `eastasia` |

```sh
uvicorn app.main:app --reload --port 8000
```

Open `/docs` for interactive request schemas and `/health` for status and the content fingerprint. Never commit `.env` or provider keys.

## Ask CareVoice

`POST /ask` accepts a message and language. For example:

```json
{"message":"How can I find preschool support services?","language":"en"}
```

The route applies a deterministic safety screen first. Otherwise, it sends the question and directory context to DeepSeek through an OpenAI-compatible SDK. Returned suggestion IDs are resolved against local content. Responses include a conversational `reply`, `suggestions`, an optional `safety` route, and the content fingerprint. Refer to `app/schemas.py` for the current schema.

Provider calls have a 45-second timeout and no automatic retries. A missing provider key returns 503; provider failures return 502. A successful `/health` response alone does not prove that AI credentials work.

The current route does not enforce a Supabase session or per-user quotas. Add server-side access controls and usage limits before a broader rollout. Browser CORS is not authentication.

## Content endpoints

| Endpoint | Data |
| --- | --- |
| `GET /health` | Status and content fingerprint |
| `GET /manifest` | Dataset metadata and counts |
| `GET /service-types` | Service categories |
| `GET /service-units?district=&service=` | Service units and available waiting-time fields |
| `GET /waiting-snapshots` | Imported waiting-time snapshots |
| `GET /glossary` | Terms and explanations |
| `GET /citable-assertions?topic=` | Source-backed directory assertions |
| `GET /pathway-steps` | Care pathway steps |
| `GET /checklist-items` | Suggested checklist items |
| `GET /red-flags` | Safety contact routes |
| `GET /districts` | District filter values |
| `GET /service-codes` | Service filter values |
| `POST /ask` | AI reply and directory suggestions |
| `POST /transcribe` | Separate Azure Speech transcription route |

The API reads checked-in `data/*.json` exports, not the source database. Missing files load as empty lists, so check `/manifest` and the relevant endpoints after replacing data. Snapshot waiting times are not live availability guarantees.

To import an updated authorized content export:

```sh
python scripts/sync_data.py /path/to/phase1_db/export
```

Review changed JSON files before committing. The script's default path points to the original local handoff location; supply an explicit path on another machine.

## Optional FastAPI transcription endpoint

`POST /transcribe` accepts multipart fields `audio` and `language` (`en-US`, `zh-HK`, or `zh-CN`). It uses `pydub` and `ffmpeg` to convert audio, then calls Azure Speech. Install `ffmpeg` locally if testing this endpoint; the Docker image includes it.

```sh
curl -F "audio=@clip.wav" -F "language=en-US" http://localhost:8000/transcribe
```

The current web recorder uses the [Supabase transcription function](../supabase/functions/transcribe/README.md) instead. Setting Azure variables here does not configure that function's secrets.

## Frontend connection and CORS

Set `VITE_BACKEND_URL` in the web app's build environment and rebuild. Local development uses `http://localhost:8000`; production uses the deployed HTTPS address. Keep credentials out of frontend variables.

Allowed origins are explicitly listed in `app/config.py`: the local Vite origins and the CareVoice production frontend. Update this list when adding your own frontend domain.

## Fly.io deployment

`fly.toml` names the existing CareVoice app, and `Dockerfile` starts Uvicorn on port 8000. Authorized maintainers configure provider keys as Fly secrets, then run from this directory:

```sh
fly deploy
```

Forks must create their own Fly app and update `fly.toml`. The configuration enables machine auto-start/stop with zero minimum running machines, so requests after inactivity may experience startup latency.

After deployment, verify `/health`, `/manifest`, browser CORS from the frontend origin, and a synthetic `/ask` request. Deploying FastAPI does not rebuild or publish the web app.
