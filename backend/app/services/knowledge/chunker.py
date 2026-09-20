"""
Document Chunker for Knowledge Base

Splits documents (plain text, markdown, PDF) into overlapping chunks
suitable for embedding and retrieval. Each chunk carries metadata
about its source, position, and section heading.
"""

import re
import logging
from dataclasses import dataclass, field
from typing import List, Optional
from pathlib import Path

logger = logging.getLogger(__name__)


@dataclass
class TextChunk:
    """A single chunk of text with metadata."""
    content: str
    chunk_index: int
    source_file: str = ""
    document_title: str = ""
    section_heading: str = ""
    char_start: int = 0
    char_end: int = 0

    @property
    def token_estimate(self) -> int:
        """Rough token estimate (4 chars ≈ 1 token for English, ~2 for Kannada)."""
        return len(self.content) // 3


class DocumentChunker:
    """
    Splits documents into overlapping chunks for embedding.
    
    Supports:
    - Plain text (.txt)
    - Markdown (.md) — splits by headings first, then by size
    - PDF (.pdf) — extracts text then chunks
    """

    def __init__(self, chunk_size: int = 500, chunk_overlap: int = 50):
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap

    def chunk_text(
        self,
        text: str,
        source_file: str = "",
        document_title: str = "",
    ) -> List[TextChunk]:
        """
        Split plain text into overlapping chunks.
        
        Args:
            text: The text content to chunk
            source_file: Original filename (for metadata)
            document_title: Human-readable document title
        
        Returns:
            List of TextChunk objects with metadata.
        """
        if not text or not text.strip():
            return []

        # Clean up whitespace
        text = re.sub(r'\n{3,}', '\n\n', text).strip()

        chunks = []
        start = 0
        chunk_index = 0

        while start < len(text):
            end = start + self.chunk_size

            # If not at the end, try to break at a sentence/paragraph boundary
            if end < len(text):
                # Try paragraph break first
                para_break = text.rfind('\n\n', start, end)
                if para_break > start + self.chunk_size // 3:
                    end = para_break + 2
                else:
                    # Try sentence break
                    sentence_break = max(
                        text.rfind('. ', start, end),
                        text.rfind('। ', start, end),  # Devanagari purna viram
                        text.rfind('? ', start, end),
                        text.rfind('! ', start, end),
                        text.rfind('\n', start, end),
                    )
                    if sentence_break > start + self.chunk_size // 3:
                        end = sentence_break + 1

            chunk_text = text[start:end].strip()
            if chunk_text:
                chunks.append(TextChunk(
                    content=chunk_text,
                    chunk_index=chunk_index,
                    source_file=source_file,
                    document_title=document_title,
                    char_start=start,
                    char_end=end,
                ))
                chunk_index += 1

            # Move start with overlap
            start = end - self.chunk_overlap
            if start >= len(text) - self.chunk_overlap:
                break

        logger.info(f"Chunked '{source_file or 'text'}' into {len(chunks)} chunks")
        return chunks

    def chunk_markdown(
        self,
        md_text: str,
        source_file: str = "",
        document_title: str = "",
    ) -> List[TextChunk]:
        """
        Split markdown by headers first, then by chunk size.
        
        Headings (##, ###) become section labels in chunk metadata,
        making retrieval results more informative.
        """
        if not md_text or not md_text.strip():
            return []

        # Split by headings (## and ### level)
        sections = re.split(r'\n(?=#{1,3}\s)', md_text)
        
        chunks = []
        chunk_index = 0

        for section in sections:
            section = section.strip()
            if not section:
                continue

            # Extract heading
            heading_match = re.match(r'^(#{1,3})\s+(.*?)(?:\n|$)', section)
            section_heading = heading_match.group(2).strip() if heading_match else ""
            
            # Remove heading from content
            if heading_match:
                section_body = section[heading_match.end():].strip()
            else:
                section_body = section

            if not section_body:
                continue

            # If section fits in one chunk, keep it whole
            if len(section_body) <= self.chunk_size:
                chunks.append(TextChunk(
                    content=section_body,
                    chunk_index=chunk_index,
                    source_file=source_file,
                    document_title=document_title,
                    section_heading=section_heading,
                ))
                chunk_index += 1
            else:
                # Section too large — sub-chunk it
                sub_chunks = self.chunk_text(
                    section_body,
                    source_file=source_file,
                    document_title=document_title,
                )
                for sc in sub_chunks:
                    sc.chunk_index = chunk_index
                    sc.section_heading = section_heading
                    chunks.append(sc)
                    chunk_index += 1

        logger.info(f"Chunked markdown '{source_file or 'text'}' into {len(chunks)} chunks")
        return chunks

    def extract_text_from_pdf(self, pdf_path: str) -> str:
        """
        Extract text from a PDF file using PyPDF2.
        
        Args:
            pdf_path: Path to the PDF file
        
        Returns:
            Extracted text content.
        """
        try:
            from PyPDF2 import PdfReader
        except ImportError:
            logger.error("PyPDF2 not installed. Run: pip install PyPDF2")
            raise

        reader = PdfReader(pdf_path)
        text_parts = []

        for page_num, page in enumerate(reader.pages):
            page_text = page.extract_text()
            if page_text:
                text_parts.append(page_text)

        full_text = "\n\n".join(text_parts)
        logger.info(f"Extracted {len(full_text)} chars from PDF: {pdf_path}")
        return full_text

    def chunk_file(
        self,
        file_path: str,
        document_title: str = "",
    ) -> List[TextChunk]:
        """
        Auto-detect file type and chunk accordingly.
        
        Supports: .txt, .md, .pdf
        """
        path = Path(file_path)
        
        if not path.exists():
            raise FileNotFoundError(f"File not found: {file_path}")

        source_file = path.name
        if not document_title:
            document_title = path.stem.replace('_', ' ').replace('-', ' ').title()

        ext = path.suffix.lower()

        if ext == '.pdf':
            text = self.extract_text_from_pdf(file_path)
            return self.chunk_text(text, source_file=source_file, document_title=document_title)
        elif ext == '.md':
            text = path.read_text(encoding='utf-8')
            return self.chunk_markdown(text, source_file=source_file, document_title=document_title)
        elif ext in ('.txt', '.text'):
            text = path.read_text(encoding='utf-8')
            return self.chunk_text(text, source_file=source_file, document_title=document_title)
        else:
            raise ValueError(f"Unsupported file type: {ext}. Supported: .txt, .md, .pdf")
