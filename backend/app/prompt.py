import json
from typing import Optional

from .schemas import Suggestion

_SYSTEM_TEMPLATE = """You are a Hong Kong pre-school special-needs service information assistant for parents.

You may ONLY use the "directory" of official entries provided below. Never use outside knowledge, memory, or common sense about Hong Kong services.

Rules:
1. Pick the 3-5 entries most relevant to the parent's situation. For each, write a single short sentence ("why") explaining why it may fit their situation.
2. Every suggestion MUST reference one entry id exactly as given. Do not invent ids, facts, phone numbers, or eligibility rules.
3. You do NOT diagnose, predict, or evaluate the child. Never use "autism", "diagnosis", "severity", or "disorder" as a judgement about the child.
4. If no entry fits, return an empty suggestions list.
5. Write a "reply": one short, warm sentence in the user's language. It must NOT contain any factual claims (facts belong only in suggestions, which cite the directory).
   - If the parent greets or is vague (e.g. "hello", "hi", no clear need), return empty suggestions and a reply that greets them and asks what they would like help with.
   - If you return suggestions, the reply should be a one-line lead-in like "Here are a few official resources that may fit your situation."
   - If nothing matches, return empty suggestions and a polite reply saying no official match was found and that they can call the Social Welfare Department hotline 2343 2255 (24 hours).
6. Output ONLY valid JSON in this exact shape, no markdown, no extra text:
{{"reply": "<one short sentence>", "suggestions": [{{"id": "<entry id>", "why": "<one sentence>"}}]}}

Respond in this language: {language}.

Directory:
{directory}
"""


def build_digest(language: str) -> list[dict]:
    from .store import store

    en = language == "en"
    entries: list[dict] = []
    for a in store.citable_assertions:
        entries.append({
            "id": a.assertion_id,
            "type": "assertion",
            "topic": a.topic,
            "title": (a.title_en or a.title_tc) if en else a.title_tc,
            "plain": (a.plain_en or a.plain_tc) if en else a.plain_tc,
            "url": a.url,
        })
    for s in store.service_types:
        alias = (s.alias_en or s.alias_tc or s.code) if en else (s.alias_tc or s.alias_en or s.code)
        name = (s.name_en or s.name_tc) if en else s.name_tc
        target = (s.target_en or s.target_tc or "") if en else (s.target_tc or s.target_en or "")
        entries.append({
            "id": s.code,
            "type": "service_type",
            "topic": "service",
            "title": f"{alias} — {name}",
            "plain": target,
            "url": None,
        })
    return entries


def build_messages(message: str, language: str) -> list[dict]:
    digest = build_digest(language)
    system = _SYSTEM_TEMPLATE.format(
        language=language, directory=json.dumps(digest, ensure_ascii=False)
    )
    return [
        {"role": "system", "content": system},
        {"role": "user", "content": message},
    ]


def parse_reply(raw: str) -> Optional[str]:
    try:
        data = json.loads(raw)
    except Exception:
        return None
    reply = data.get("reply") if isinstance(data, dict) else None
    if isinstance(reply, str) and reply.strip():
        return reply.strip()
    return None


def parse_suggestions(raw: str, language: str) -> list[Suggestion]:
    en = language == "en"
    try:
        data = json.loads(raw)
    except Exception:
        return []
    items = data.get("suggestions", []) if isinstance(data, dict) else []
    if not isinstance(items, list):
        return []
    result: list[Suggestion] = []
    for it in items[:5]:
        if not isinstance(it, dict):
            continue
        sid = str(it.get("id", "")).strip()
        why = str(it.get("why", "")).strip()
        entry = _lookup(sid, en)
        if entry is None or not why:
            continue
        result.append(Suggestion(
            type=entry["type"], id=sid, title=entry["title"], plain=entry["plain"],
            quote=entry.get("quote"), url=entry.get("url"), why=why,
        ))
    return result


def _lookup(sid: str, en: bool) -> Optional[dict]:
    from .store import store

    a = next((x for x in store.citable_assertions if x.assertion_id == sid), None)
    if a is not None:
        return {
            "type": "assertion",
            "title": (a.title_en or a.title_tc) if en else a.title_tc,
            "plain": (a.plain_en or a.plain_tc) if en else a.plain_tc,
            "quote": (a.quote_en or a.quote) if en else a.quote,
            "url": a.url,
        }
    s = next((x for x in store.service_types if x.code == sid), None)
    if s is not None:
        alias = (s.alias_en or s.alias_tc or s.code) if en else (s.alias_tc or s.alias_en or s.code)
        name = (s.name_en or s.name_tc) if en else s.name_tc
        target = (s.target_en or s.target_tc or "") if en else (s.target_tc or s.target_en or "")
        return {"type": "service_type", "title": f"{alias} — {name}", "plain": target, "quote": None, "url": None}
    return None
