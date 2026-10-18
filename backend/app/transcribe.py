import os
import tempfile

import httpx
from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from pydub import AudioSegment

from .config import AZURE_SPEECH_KEY, AZURE_SPEECH_REGION

router = APIRouter()

SUPPORTED_LANGUAGES = {"en-US", "zh-HK", "zh-CN"}


def _to_wav(data: bytes, filename: str) -> bytes:
    """Convert an uploaded audio blob (webm/mp4/ogg/…) to 16 kHz mono WAV PCM."""
    ext = os.path.splitext(filename or "audio.webm")[1] or ".webm"
    with tempfile.TemporaryDirectory() as tmp:
        in_path = os.path.join(tmp, "input" + ext)
        with open(in_path, "wb") as f:
            f.write(data)
        seg = AudioSegment.from_file(in_path).set_frame_rate(16000).set_channels(1)
        wav_path = os.path.join(tmp, "audio.wav")
        seg.export(wav_path, format="wav")
        with open(wav_path, "rb") as f:
            return f.read()


@router.post("/transcribe")
def transcribe(audio: UploadFile = File(...), language: str = Form("en-US")) -> dict:
    if language not in SUPPORTED_LANGUAGES:
        raise HTTPException(status_code=400, detail=f"Unsupported language: {language}")
    if not AZURE_SPEECH_KEY:
        raise HTTPException(status_code=503, detail="Speech service is not configured")

    data = audio.file.read()
    if not data:
        raise HTTPException(status_code=400, detail="Empty audio")

    try:
        wav = _to_wav(data, audio.filename or "")
    except Exception as exc:  # noqa: BLE001 - surface conversion failures to the client
        raise HTTPException(status_code=400, detail=f"Could not decode audio: {exc}") from exc

    url = (
        f"https://{AZURE_SPEECH_REGION}.stt.speech.microsoft.com/"
        "speech/recognition/conversation/cognitiveservices/v1"
    )
    headers = {
        "Ocp-Apim-Subscription-Key": AZURE_SPEECH_KEY,
        "Content-Type": "audio/wav; codecs=audio/pcm; samplerate=16000",
        "Accept": "application/json",
    }
    try:
        resp = httpx.post(url, params={"language": language}, headers=headers, content=wav, timeout=60.0)
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=502, detail=f"Speech service unreachable: {exc}") from exc

    if resp.status_code == 401 or resp.status_code == 403:
        raise HTTPException(status_code=502, detail="Speech service rejected the key (auth failed)")
    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"Speech service error {resp.status_code}")

    payload = resp.json()
    text = (payload.get("DisplayText") or "").strip()
    return {"text": text, "language": language, "status": payload.get("RecognitionStatus", "")}
