from openai import OpenAI

from .config import LLM_API_KEY, LLM_BASE_URL, LLM_MODEL


def complete(messages: list[dict], json_mode: bool = True) -> str:
    """Call the LLM (DeepSeek, OpenAI-compatible) and return the text content."""
    client = OpenAI(api_key=LLM_API_KEY, base_url=LLM_BASE_URL)
    kwargs: dict = {"model": LLM_MODEL, "messages": messages}
    if json_mode:
        kwargs["response_format"] = {"type": "json_object"}
    resp = client.chat.completions.create(**kwargs)
    return resp.choices[0].message.content or ""
