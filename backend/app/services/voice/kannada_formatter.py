"""
Spoken Kannada Text Formatter — Normalizer for Sarvam Bulbul TTS

Converts raw text (containing digits, symbols, currencies, units, markdown, emojis)
into clean, natural spoken Kannada text for text-to-speech synthesis.

Examples:
    "₹6,000"       → "ಆರು ಸಾವಿರ ರೂಪಾಯಿ"
    "94%"          → "ತೊಂಬತ್ತನಾಲ್ಕು ಶೇಕಡಾ"
    "1.1mm"        → "ಒಂದು ಬಿಂದು ಒಂದು ಮಿಲಿಮೀಟರ್"
    "32.1°C"       → "ಮೂವತ್ತೆರಡು ಬಿಂದು ಒಂದು ಡಿಗ್ರಿ ಸೆಲ್ಸಿಯಸ್"
    "PM-KISAN"     → "ಪಿ.ಎಮ್ ಕಿಸಾನ್"
    "KVK"          → "ಕೆ.ವಿ.ಕೆ"
"""

import re
import logging
from typing import Dict

logger = logging.getLogger(__name__)

# Single digit and teens words in Kannada
UNITS_KN = [
    "ಸೊನ್ನೆ", "ಒಂದು", "ಎರಡು", "ಮೂರು", "ನಾಲ್ಕು",
    "ಐದು", "ಆರು", "ಏಳು", "ಎಂಟು", "ಒಂಬತ್ತು", "ಹತ್ತು",
    "ಹನ್ನೊಂದು", "ಹನ್ನೆರಡು", "ಹದಿಮೂರು", "ಹದಿನಾಲ್ಕು", "ಹದಿನೈದು",
    "ಹದಿನಾರು", "ಹದಿನೇಳು", "ಹದಿನೆಂಟು", "ಹತ್ತೊಂಬತ್ತು"
]

TENS_KN = [
    "", "", "ಇಪ್ಪತ್ತು", "ಮೂವತ್ತು", "ನಲವತ್ತು", "ಐವತ್ತು",
    "ಅರವತ್ತು", "ಎಪ್ಪತ್ತು", "ಎಂಬತ್ತು", "ತೊಂಬತ್ತು"
]

# Acronym mapping to spoken Kannada
ACRONYM_MAP: Dict[str, str] = {
    "PM-KISAN": "ಪಿ.ಎಮ್ ಕಿಸಾನ್",
    "PMKISAN": "ಪಿ.ಎಮ್ ಕಿಸಾನ್",
    "PMFBY": "ಪಿ.ಎಮ್.ಎಫ್.ಬಿ.ವೈ",
    "KCC": "ಕೆ.ಸಿ.ಸಿ",
    "KVK": "ಕೆ.ವಿ.ಕೆ",
    "FPO": "ಎಫ್.ಪಿ.ಒ",
    "APMC": "ಎ.ಪಿ.ಎಮ್.ಸಿ",
    "NPK": "ಎನ್.ಪಿ.ಕೆ",
    "GPS": "ಜಿ.ಪಿ.ಎಎಸ್",
}

def number_to_kannada_words(n: int) -> str:
    """Convert integer (0 to 99,99,99,999) into spoken Kannada text."""
    if n < 0:
        return "ಮೈನಸ್ " + number_to_kannada_words(-n)
    if n < 20:
        return UNITS_KN[n]
    if n < 100:
        ten = n // 10
        rem = n % 10
        if rem == 0:
            return TENS_KN[ten]
        return TENS_KN[ten] + " " + UNITS_KN[rem]
    if n < 1000:
        hundred = n // 100
        rem = n % 100
        prefix = "ನೂರು" if hundred == 1 else UNITS_KN[hundred] + " ನೂರು"
        if rem == 0:
            return prefix
        return prefix + " " + number_to_kannada_words(rem)
    if n < 100000:
        thousand = n // 1000
        rem = n % 1000
        prefix = "ಸಾವಿರ" if thousand == 1 else number_to_kannada_words(thousand) + " ಸಾವಿರ"
        if rem == 0:
            return prefix
        return prefix + " " + number_to_kannada_words(rem)
    if n < 10000000:
        lakh = n // 100000
        rem = n % 100000
        prefix = "ಒಂದು ಲಕ್ಷ" if lakh == 1 else number_to_kannada_words(lakh) + " ಲಕ್ಷ"
        if rem == 0:
            return prefix
        return prefix + " " + number_to_kannada_words(rem)
    if n < 1000000000:
        crore = n // 10000000
        rem = n % 10000000
        prefix = "ಒಂದು ಕೋಟಿ" if crore == 1 else number_to_kannada_words(crore) + " ಕೋಟಿ"
        if rem == 0:
            return prefix
        return prefix + " " + number_to_kannada_words(rem)
    return str(n)


def float_to_kannada_words(f_str: str) -> str:
    """Convert decimal string (e.g., '32.1', '1.5') to spoken Kannada words."""
    if "." not in f_str:
        try:
            return number_to_kannada_words(int(f_str))
        except ValueError:
            return f_str
    parts = f_str.split(".")
    int_part = parts[0]
    dec_part = parts[1]
    
    int_words = number_to_kannada_words(int(int_part)) if int_part.isdigit() else int_part
    dec_words = " ".join([UNITS_KN[int(d)] if d.isdigit() else d for d in dec_part])
    return f"{int_words} ಬಿಂದು {dec_words}"


class KannadaSpokenFormatter:
    """Formats AI response text into natural, speakable Kannada text for Bulbul TTS."""

    @classmethod
    def format_for_speech(cls, text: str) -> str:
        if not text:
            return ""

        s = text

        # 1. Strip markdown syntax and emojis
        s = re.sub(r'[*_~`#]', '', s)
        s = re.sub(r'^\s*[-+]\s*', '', s, flags=re.MULTILINE)
        s = re.sub(r'[\U00010000-\U0010ffff\u2600-\u26FF\u2700-\u27BF]', '', s)

        # 2. Expand known acronyms
        for acronym, expanded in ACRONYM_MAP.items():
            s = re.sub(r'\b' + re.escape(acronym) + r'\b', expanded, s, flags=re.IGNORECASE)

        # 3. Currency formatting: ₹6,000 or Rs 6000 → 6000 ರೂಪಾಯಿ
        s = re.sub(r'[₹]\s*([\d,]+(?:\.\d+)?)', r'\1 ರೂಪಾಯಿ', s)
        s = re.sub(r'\bRs\.?\s*([\d,]+(?:\.\d+)?)', r'\1 ರೂಪಾಯಿ', s, flags=re.IGNORECASE)

        # 4. Temperature and unit formatting (run BEFORE converting digits to words)
        s = re.sub(r'([\d.]+)\s*°?C\b', r'\1 ಡಿಗ್ರಿ ಸೆಲ್ಸಿಯಸ್', s)
        s = re.sub(r'([\d.]+)\s*mm\b', r'\1 ಮಿಲಿಮೀಟರ್', s)
        s = re.sub(r'([\d.]+)\s*%', r'\1 ಶೇಕಡಾ', s)
        s = re.sub(r'([\d.]+)\s*kg\b', r'\1 ಕೆಜಿ', s)

        # 5. Convert numbers with commas: 6,000 → 6000
        s = re.sub(r'(\d+),(\d+)', r'\1\2', s)

        # 6. Convert decimal numbers to Kannada words: 1.1 → ಒಂದು ಬಿಂದು ಒಂದು
        def replace_decimal(match):
            val = match.group(0)
            return float_to_kannada_words(val)

        s = re.sub(r'\b\d+\.\d+\b', replace_decimal, s)

        # 7. Convert integer numbers to Kannada words: 6000 → ಆರು ಸಾವಿರ
        def replace_integer(match):
            val = int(match.group(0))
            return number_to_kannada_words(val)

        s = re.sub(r'\b\d+\b', replace_integer, s)

        # 8. Clean up extra whitespaces and trailing markers
        s = re.sub(r'\s+', ' ', s).strip()

        return s
