"""
app/llm/llm_provider.py — LLM abstraction layer.

Swap get_default_provider() to change the backend globally.
Local model support (llama.cpp, vLLM, etc.) plugs in here later
without touching pipeline logic.
"""
from abc import ABC, abstractmethod
import logging

from backend.app.config import settings
from backend.app.llm.ollama_client import generate as _ollama_generate

logger = logging.getLogger(__name__)


class LLMProvider(ABC):
    """
    Interface contract for all LLM backends.
    Implement this class to add a new model provider.
    """

    @abstractmethod
    def generate(self, prompt: str) -> str:
        """Send a prompt and return the response string."""
        pass

    @abstractmethod
    def model_name(self) -> str:
        """Return a human-readable model identifier."""
        pass


class OllamaProvider(LLMProvider):
    """Concrete provider backed by local Ollama server."""

    def generate(self, prompt: str) -> str:
        return _ollama_generate(prompt)

    def model_name(self) -> str:
        return settings.ollama_model


# ── Future providers (not implemented yet) ────────────────────────────────
# class LlamaCppProvider(LLMProvider): ...
# class VLLMProvider(LLMProvider): ...
# class OpenAIProvider(LLMProvider): ...  # for cloud fallback


def get_default_provider() -> LLMProvider:
    """
    Returns the active LLM provider.
    Change this single line to swap backends across all pipelines.
    """
    return OllamaProvider()