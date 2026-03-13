import requests

OLLAMA_GENERATE_URL = "http://localhost:11434/api/generate"
MODEL_NAME = "qwen2.5:7b"


def generate(prompt: str) -> str:
    """Generate text from the local Ollama model."""
    response = requests.post(
        OLLAMA_GENERATE_URL,
        json={
            "model": MODEL_NAME,
            "prompt": prompt,
        },
        timeout=60,
    )
    response.raise_for_status()
    data = response.json()
    return data.get("response", "")