from typing import Optional

from pydantic import BaseModel


class Suggestion(BaseModel):
    type: str  # "assertion" | "service_type"
    id: str
    title: str
    plain: str
    quote: Optional[str] = None
    url: Optional[str] = None
    why: str


class Safety(BaseModel):
    signal: str
    route: str
    contact: Optional[str] = None


class HistoryMessage(BaseModel):
    role: str  # "user" | "assistant"
    content: str


class AskRequest(BaseModel):
    language: str = "en"  # "en" | "zh" | "zh-Hans"
    message: str
    history: list[HistoryMessage] = []


class AskResponse(BaseModel):
    safety: Optional[Safety] = None
    reply: Optional[str] = None
    suggestions: list[Suggestion] = []
    content_fingerprint: Optional[str] = None
