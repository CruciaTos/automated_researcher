from typing import List

from sentence_transformers import SentenceTransformer

_MODEL_NAME = "bge-small-en-v1.5"
_model = SentenceTransformer(_MODEL_NAME)


def embed_texts(texts: List[str]) -> List[List[float]]:
    """Generate embeddings for a list of texts."""
    embeddings = _model.encode(texts, convert_to_numpy=True)
    return embeddings.tolist()