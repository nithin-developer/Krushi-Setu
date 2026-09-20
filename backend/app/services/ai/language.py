"""
Language Detection for Krushi Setu AI

Detects the input language from Unicode script ranges. Used to ensure
responses match the farmer's actual speaking language, not just the
profile setting.

Supports: Kannada, Hindi, Telugu, Tamil, Marathi, English (default)
"""

import re
import logging
from collections import Counter

logger = logging.getLogger(__name__)

# Unicode script ranges for Indian languages
SCRIPT_RANGES = {
    "kn": (0x0C80, 0x0CFF),   # Kannada
    "hi": (0x0900, 0x097F),   # Devanagari (Hindi, Marathi, Sanskrit)
    "te": (0x0C00, 0x0C7F),   # Telugu
    "ta": (0x0B80, 0x0BFF),   # Tamil
    "ml": (0x0D00, 0x0D7F),   # Malayalam
    "bn": (0x0980, 0x09FF),   # Bengali
    "gu": (0x0A80, 0x0AFF),   # Gujarati
    "pa": (0x0A00, 0x0A7F),   # Gurmukhi (Punjabi)
    "or": (0x0B00, 0x0B7F),   # Odia
}

# Marathi also uses Devanagari — disambiguated by specific keywords
MARATHI_MARKERS = ["आहे", "नाही", "मला", "तुम्ही", "काय", "शेती", "पीक"]


def detect_language(text: str) -> str:
    """
    Detect the language of input text using Unicode script analysis.
    
    Args:
        text: The farmer's input text
    
    Returns:
        ISO 639-1 language code: "kn", "hi", "te", "ta", "en", etc.
        Returns "en" if no Indic script is detected.
    """
    if not text or not text.strip():
        return "en"

    # Count characters in each script range
    script_counts: Counter = Counter()
    total_alpha = 0

    for char in text:
        code_point = ord(char)

        # Skip spaces, digits, punctuation
        if not char.isalpha():
            continue

        total_alpha += 1

        # Check each Indic script
        matched = False
        for lang_code, (start, end) in SCRIPT_RANGES.items():
            if start <= code_point <= end:
                script_counts[lang_code] += 1
                matched = True
                break

        # If no Indic match, it's Latin (English or transliterated)
        if not matched and char.isascii():
            script_counts["en"] += 1

    if total_alpha == 0:
        return "en"

    # Find the dominant script
    if not script_counts:
        return "en"

    dominant_lang, dominant_count = script_counts.most_common(1)[0]

    # If Indic characters are present at all, prefer them over English
    # (common case: "ನನ್ನ tomato leaves ಮುದುರುತ್ತಿವೆ" → Kannada)
    indic_total = sum(count for lang, count in script_counts.items() if lang != "en")
    if indic_total > 0:
        # Use the Indic language with the most characters
        indic_langs = [(lang, count) for lang, count in script_counts.items() if lang != "en"]
        if indic_langs:
            dominant_lang = max(indic_langs, key=lambda x: x[1])[0]

    # Special case: Devanagari could be Hindi or Marathi
    if dominant_lang == "hi":
        if any(marker in text for marker in MARATHI_MARKERS):
            dominant_lang = "mr"

    logger.debug(f"Language detected: {dominant_lang} from script counts: {dict(script_counts)}")
    return dominant_lang
