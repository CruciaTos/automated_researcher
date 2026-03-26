"""
app/llm/ollama_client.py — HTTP client for the local Ollama inference server.

Critical fix applied:
  `"stream": False` is REQUIRED in the request body. Without it, Ollama
  returns a streaming NDJSON response and `response.json()` raises a
  JSONDecodeError on every call.
"""

import logging

import requests

from backend.app.config import settings

logger = logging.getLogger(__name__)

_GENERATE_URL = f"{settings.ollama_host}/api/generate"
_CHAT_URL = f"{settings.ollama_host}/api/chat"


def generate(prompt: str, model: str | None = None) -> str:
    """
    Send a prompt to the Ollama `/api/generate` endpoint and return the
    complete response text.

    Args:
        prompt: The input prompt string.
        model:  Optional model name override. Defaults to
                ``settings.ollama_model``.

    Returns:
        The generated text as a plain string.

    Raises:
        requests.HTTPError: If Ollama returns a non-2xx HTTP status.
        ValueError:         If the JSON response is missing the ``response``
                            key (indicates an unexpected API change).
    """
    resolved_model = model or settings.ollama_model
    logger.debug(
        "ollama generate — model=%s prompt_chars=%d", resolved_model, len(prompt)
    )

    response = requests.post(
        _GENERATE_URL,
        json={
            "model": resolved_model,
            "prompt": prompt,
            "stream": False,  # ← MUST be False; streaming returns NDJSON
        },
        timeout=settings.ollama_timeout,
    )
    response.raise_for_status()

    data = response.json()

    if "response" not in data:
        raise ValueError(
            f"Ollama response missing 'response' key. Keys present: {list(data.keys())}"
        )

    result: str = data["response"]

    if not result.strip():
        logger.warning(
            "Ollama returned an empty response (model=%s prompt_chars=%d)",
            resolved_model,
            len(prompt),
        )

    logger.debug(
        "ollama generate — response_chars=%d model=%s", len(result), resolved_model
    )
    return result
