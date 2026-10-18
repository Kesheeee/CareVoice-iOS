"""Deterministic red-flag screen — runs before any LLM call.

Matches crisis/diagnostic signals against curated bilingual keywords and maps
them to the corresponding entry in red_flags.json. If a signal hits, the caller
must return the route (hotline) and never call the model.
"""
from typing import Optional

from .schemas import Safety

# flag_id -> (bilingual trigger keywords). Order matters: most urgent first.
_TRIGGERS: list[tuple[str, list[str]]] = [
    ("RF-002", ["seizure", "convulsion", "fits", "抽搐", "抽筋", "抽风", "抽風", "unconscious", "cannot wake", "can't wake", "無法喚醒", "叫不醒"]),
    ("RF-001", ["self harm", "self-harm", "head banging", "head-bang", "bites himself", "bites herself", "bite himself", "bite herself", "hurt himself", "hurt herself", "hurting himself", "hurting herself", "scratch himself", "自殘", "自残", "撞頭", "撞头", "咬自己", "打自己", "傷害自己", "伤害自己"]),
    ("RF-004", ["suicid", "kill myself", "end my life", "can't go on", "cant go on", "cannot go on", "can't carry on", "cannot carry on", "自殺", "自杀", "結束自己", "结束自己", "撐不下去", "撑不下去", "想死", "不想活"]),
    ("RF-003", ["regression", "lost words", "lost skills", "stopped speaking", "used to say", "能力倒退", "退步", "原本會", "本来会", "不會講", "不会讲", "失去了技能", "失去咗"]),
    ("RF-005", ["is my child autistic", "是不是自閉症", "是不是自闭症", "does my child have autism", "有冇自閉症", "有自闭症吗"]),
]


def screen(message: str) -> Optional[Safety]:
    """Return a Safety route if a crisis/diagnostic signal is present, else None."""
    text = (message or "").lower()
    for flag_id, keywords in _TRIGGERS:
        if any(kw in text for kw in keywords):
            return _build(flag_id)
    return None


def _build(flag_id: str) -> Optional[Safety]:
    from .store import store  # local import to avoid circulars at module load

    flag = next((f for f in store.red_flags if f.flag_id == flag_id), None)
    if flag is None:
        return None
    return Safety(
        signal=flag.signal_en or flag.signal_tc,
        route=flag.route_en or flag.route_tc,
        contact=flag.route_contact_en or flag.route_contact,
    )
