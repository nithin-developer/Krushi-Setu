"""
Hybrid Reranker for Krushi Setu Knowledge Base

Implements a second-pass reranking layer over vector retrieval results.
Combines vector cosine similarity with:
- Query keyword match density in chunk content
- Heading / title match boosts
- Category exact match boost
- Document freshness and length normalization
"""

import re
import logging
from typing import List, Optional

from app.services.knowledge.retriever import RetrievedChunk

logger = logging.getLogger(__name__)


class Reranker:
    """
    Reranks candidate retrieved chunks to optimize relevance for the LLM prompt.
    """

    def __init__(
        self,
        vector_weight: float = 0.6,
        keyword_weight: float = 0.25,
        heading_weight: float = 0.15,
    ):
        self.vector_weight = vector_weight
        self.keyword_weight = keyword_weight
        self.heading_weight = heading_weight

    def rerank(
        self,
        query: str,
        chunks: List[RetrievedChunk],
        top_n: int = 4,
        category_filter: Optional[str] = None,
    ) -> List[RetrievedChunk]:
        """
        Reranks a list of candidate chunks based on hybrid scoring.

        Args:
            query: The user query string
            chunks: Candidate retrieved chunks from vector search
            top_n: Target number of reranked chunks to return
            category_filter: Optional category constraint

        Returns:
            Sorted list of top_n RetrievedChunk instances with adjusted scores.
        """
        if not chunks:
            return []

        # Tokenize query keywords (alphanumeric terms, min 2 chars)
        query_terms = [
            term.lower()
            for term in re.findall(r'\w+', query)
            if len(term) >= 2
        ]

        scored_chunks = []
        for chunk in chunks:
            # 1. Base vector score (0 - 1)
            vector_score = max(0.0, min(1.0, chunk.score))

            # 2. Keyword density score
            content_lower = chunk.content.lower()
            if query_terms:
                term_matches = sum(1 for t in query_terms if t in content_lower)
                keyword_score = term_matches / len(query_terms)
            else:
                keyword_score = 0.0

            # 3. Heading & title relevance score
            heading_lower = (chunk.section_heading or "").lower()
            title_lower = (chunk.document_title or "").lower()
            heading_matches = sum(
                1 for t in query_terms if t in heading_lower or t in title_lower
            )
            heading_score = min(1.0, heading_matches / max(1, len(query_terms))) if query_terms else 0.0

            # 4. Category bonus
            category_bonus = 0.1 if (category_filter and chunk.category == category_filter) else 0.0

            # Compute weighted final score
            final_score = (
                (self.vector_weight * vector_score) +
                (self.keyword_weight * keyword_score) +
                (self.heading_weight * heading_score) +
                category_bonus
            )

            # Cap final score between 0.0 and 1.0
            final_score = round(max(0.0, min(1.0, final_score)), 4)

            # Return updated copy of chunk
            new_chunk = RetrievedChunk(
                content=chunk.content,
                score=final_score,
                document_title=chunk.document_title,
                section_heading=chunk.section_heading,
                category=chunk.category,
                source_file=chunk.source_file,
                document_id=chunk.document_id,
                chunk_index=chunk.chunk_index,
            )
            scored_chunks.append(new_chunk)

        # Sort by reranked score descending
        scored_chunks.sort(key=lambda c: c.score, reverse=True)

        # Deduplicate chunks based on normalized content text
        deduped_chunks = []
        seen_contents = set()

        for chunk in scored_chunks:
            # Normalize whitespace and lowercase for content comparison
            normalized = " ".join(chunk.content.strip().split())
            if normalized not in seen_contents:
                seen_contents.add(normalized)
                deduped_chunks.append(chunk)

        logger.info(
            f"Reranked {len(chunks)} candidates -> deduped {len(deduped_chunks)} -> returning top {min(top_n, len(deduped_chunks))}"
        )
        return deduped_chunks[:top_n]
