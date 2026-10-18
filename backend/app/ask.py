import logging

from fastapi import APIRouter, HTTPException

from . import llm, prompt, safety
from .config import LLM_API_KEY
from .schemas import AskRequest, AskResponse
from .store import store

router = APIRouter()
logger = logging.getLogger("carevoice.ask")


@router.post("/ask", response_model=AskResponse)
def ask(req: AskRequest) -> AskResponse:
    message = (req.message or "").strip()
    if not message:
        raise HTTPException(status_code=400, detail="Message is required")

    # 1. Safety screen — deterministic, before any model call.
    hit = safety.screen(message)
    if hit is not None:
        return AskResponse(safety=hit, suggestions=[], content_fingerprint=store.fingerprint)

    if not LLM_API_KEY:
        raise HTTPException(status_code=503, detail="LLM is not configured")

    # 2. Prompt (system + directory digest) + 3. LLM call.
    messages = prompt.build_messages(message, req.language)
    try:
        raw = llm.complete(messages)
    except Exception as exc:  # noqa: BLE001 - surface provider errors to the client
        logger.exception("LLM call failed")
        raise HTTPException(status_code=502, detail="AI service temporarily unavailable") from exc

    # 4. Validate returned ids against the directory; build cited suggestions.
    suggestions = prompt.parse_suggestions(raw, req.language)

    # "No match" -> empty suggestions (the client shows a "can't find" note + hotline).
    return AskResponse(suggestions=suggestions, content_fingerprint=store.fingerprint)
