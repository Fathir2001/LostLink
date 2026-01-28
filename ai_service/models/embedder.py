"""
Embedding Model for semantic similarity
Uses sentence-transformers for efficient embeddings
"""

import os
from typing import List, Union
import numpy as np
from sentence_transformers import SentenceTransformer


class EmbeddingModel:
    """
    Generates text embeddings for semantic similarity matching
    Uses all-MiniLM-L6-v2 by default (fast and good quality)
    """
    
    def __init__(self, device: str = "cuda"):
        model_name = os.getenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
        cache_dir = os.getenv("MODEL_CACHE_DIR", "./models")
        
        print(f"📥 Loading embedding model: {model_name}")
        
        self.model = SentenceTransformer(
            model_name,
            cache_folder=cache_dir,
            device=device,
        )
        
        self.dimension = self.model.get_sentence_embedding_dimension()
        print(f"✅ Embedding model loaded. Dimension: {self.dimension}")
    
    def encode(self, text: str) -> np.ndarray:
        """
        Generate embedding for a single text
        """
        # Normalize and clean text
        text = self._preprocess(text)
        
        embedding = self.model.encode(
            text,
            convert_to_numpy=True,
            normalize_embeddings=True,
        )
        
        return embedding
    
    def encode_batch(self, texts: List[str]) -> List[np.ndarray]:
        """
        Generate embeddings for multiple texts efficiently
        """
        texts = [self._preprocess(t) for t in texts]
        
        embeddings = self.model.encode(
            texts,
            convert_to_numpy=True,
            normalize_embeddings=True,
            batch_size=32,
            show_progress_bar=len(texts) > 10,
        )
        
        return list(embeddings)
    
    def similarity(self, text1: str, text2: str) -> float:
        """
        Calculate cosine similarity between two texts
        """
        emb1 = self.encode(text1)
        emb2 = self.encode(text2)
        
        # Since embeddings are normalized, dot product = cosine similarity
        return float(np.dot(emb1, emb2))
    
    def find_similar(
        self,
        query: str,
        candidates: List[str],
        top_k: int = 5
    ) -> List[tuple]:
        """
        Find most similar candidates to query
        Returns list of (index, score, text) tuples
        """
        query_emb = self.encode(query)
        candidate_embs = self.encode_batch(candidates)
        
        scores = [float(np.dot(query_emb, c)) for c in candidate_embs]
        
        # Sort by score descending
        ranked = sorted(
            enumerate(scores),
            key=lambda x: x[1],
            reverse=True
        )[:top_k]
        
        return [(idx, score, candidates[idx]) for idx, score in ranked]
    
    def _preprocess(self, text: str) -> str:
        """Preprocess text for embedding"""
        # Remove extra whitespace
        text = " ".join(text.split())
        
        # Truncate if too long
        if len(text) > 512:
            text = text[:512]
        
        return text
