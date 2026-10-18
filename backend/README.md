# CareVoice content API (FastAPI)

Read-only REST API serving Harmon's curated content layer (service types, service
units, waiting times, glossary, citable assertions, pathway steps, checklist
items, red flags). No AI yet — that comes in a later phase.

## Setup

```sh
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python scripts/sync_data.py        # copy Harmon's export/*.json -> data/ (+ _en)
uvicorn app.main:app --reload --port 8000
```

`sync_data.py` defaults to the Desktop handoff folder; pass a source dir to
override: `python scripts/sync_data.py /path/to/phase1_db/export`.

## Endpoints

| Endpoint | Returns |
|---|---|
| `GET /health` | `{status, content_fingerprint}` |
| `GET /manifest` | fingerprint, built_on, counts |
| `GET /service-types` | 7 services (E/S/I/O/T/SR/CAS) |
| `GET /service-units?district=&service=` | 124 centres, each with `wait_months` |
| `GET /waiting-snapshots` | 124 snapshots |
| `GET /glossary` | 20 terms |
| `GET /citable-assertions?topic=` | 30 facts, topic filter |
| `GET /pathway-steps` | 7 steps |
| `GET /checklist-items` | 10 items |
| `GET /red-flags` | 5 routes |
| `GET /districts` · `GET /service-codes` | filter lists |
| `POST /transcribe` | speech-to-text via Azure Speech |

## Speech-to-text (`POST /transcribe`)

`multipart/form-data` with `audio` (webm/mp4/ogg/…, converted server-side to WAV
via `pydub` + `ffmpeg`) and `language` (`en-US` / `zh-HK` / `zh-CN`). Returns
`{ text, language, status }`. Audio is transient — never stored.

Requires `ffmpeg` on PATH (for `pydub`) and `AZURE_SPEECH_KEY` +
`AZURE_SPEECH_REGION` in `backend/.env` (see `.env.example`).

```sh
curl -F "audio=@clip.wav" -F "language=en-US" localhost:8000/transcribe
```

## Notes

- Content is read-only: the API only reads `backend/data/*.json` (the JSON
  exports, per the data-layer contract). It never touches `phase1.db`.
- All fields carry both `*_tc` and `*_en`; language selection is the client's job.
- `backend/data/` and `backend/.venv/` are gitignored.
