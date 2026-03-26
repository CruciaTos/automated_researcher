"""
app/llm/llm_provider.py — LLM abstraction layer.

Pass a model_override string to get_default_provider() to use a specific
locally-available Ollama model for a single job without changing server config.
"""
import logging
from abc import ABC, abstractmethod
from typing import Optional

from backend.app.config import settings
from backend.app.llm.ollama_client import generate as _ollama_generate

logger = logging.getLogger(__name__)


class LLMProvider(ABC):
    """Interface contract for all LLM backends."""

    @abstractmethod
    def generate(self, prompt: str) -> str:
        """Send a prompt and return the response string."""

    @abstractmethod
    def model_name(self) -> str:
        """Return the model identifier being used."""


class OllamaProvider(LLMProvider):
    """Concrete provider backed by local Ollama server."""

    def __init__(self, model_override: Optional[str] = None):
        # Use the caller-supplied model; fall back to server default.
        self._model = (model_override or "").strip() or settings.ollama_model
        logger.info("OllamaProvider initialised — model=%s", self._model)

    def generate(self, prompt: str) -> str:
        return _ollama_generate(prompt, model=self._model)

    def model_name(self) -> str:
        return self._model


# ── Future providers ──────────────────────────────────────────────────────
# class LlamaCppProvider(LLMProvider): ...
# class OpenAIProvider(LLMProvider): ...


def get_default_provider(model_override: Optional[str] = None) -> LLMProvider:
    """
    Returns the active LLM provider.

    Args:
        model_override: If supplied, the provider will use this Ollama model
                        instead of the server default (OLLAMA_MODEL env var).
    """
    return OllamaProvider(model_override=model_override)
