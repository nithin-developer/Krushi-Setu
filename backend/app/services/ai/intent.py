"""
Intent Detection for Krushi Setu AI

Classifies farmer queries into agricultural intents using keyword matching
for both Kannada and English. Fast, deterministic first pass — no LLM call
needed for common patterns.
"""

import re
import logging
from dataclasses import dataclass
from typing import Tuple

logger = logging.getLogger(__name__)


@dataclass
class IntentResult:
    """Result of intent classification."""
    intent: str
    confidence: float
    sub_intent: str = ""


# Intent categories with Kannada + English keywords
# Each tuple: (intent_name, confidence_boost, [keyword_patterns])
INTENT_PATTERNS = {
    "weather": {
        "keywords": [
            # Kannada
            "ಮಳೆ", "ಹವಾಮಾನ", "ಬಿಸಿಲು", "ಚಳಿ", "ಗಾಳಿ", "ಮೋಡ",
            "ತಂಪು", "ಉಷ್ಣಾಂಶ", "ಮುಂಗಾರು", "ಹಿಂಗಾರು",
            # English
            "rain", "weather", "forecast", "temperature", "humidity",
            "wind", "cloud", "monsoon", "hot", "cold", "storm",
        ],
        "phrases": [
            "ಮಳೆ ಬರತ್ತಾ", "ಮಳೆ ಆಗತ್ತಾ", "ಹವಾಮಾನ ಹೇಗಿದೆ",
            "ನಾಳೆ ಮಳೆ", "ಈ ವಾರ ಮಳೆ", "will it rain", "weather today",
        ],
    },
    "pest_disease": {
        "keywords": [
            # Kannada
            "ರೋಗ", "ಕೀಟ", "ಹುಳ", "ಮುದುರು", "ಹಳದಿ", "ಕೊಳೆ",
            "ಚುಕ್ಕೆ", "ಬಾಡು", "ಒಣಗು", "ಸೊರಗು", "ಹೇನು",
            "ಬಿಳಿ ನೊಣ", "ಕಂಬಳಿ ಹುಳು", "ಸ್ಪ್ರೇ", "ಔಷಧ",
            # English
            "disease", "pest", "insect", "worm", "fungus", "blight",
            "wilt", "rot", "yellow", "curl", "spray", "pesticide",
            "whitefly", "borer", "mite", "aphid", "caterpillar",
            "leaf spot", "leaf curl", "powdery mildew",
        ],
        "phrases": [
            "ಎಲೆ ಮುದುರು", "ಎಲೆ ಹಳದಿ", "ಗಿಡ ಒಣಗು", "ಗಿಡ ಸಾಯ",
            "ಯಾವ ಔಷಧ", "ಸ್ಪ್ರೇ ಮಾಡ", "leaves curling", "plant dying",
        ],
    },
    "fertilizer": {
        "keywords": [
            # Kannada
            "ಗೊಬ್ಬರ", "ಯೂರಿಯಾ", "ಡಿಎಪಿ", "ಪೊಟಾಷ್", "ಸಾವಯವ",
            "ಕಾಂಪೋಸ್ಟ್", "ಎರೆಹುಳು", "ಸಗಣಿ", "ಬೇವಿನ ಹಿಂಡಿ",
            "ಪೋಷಕಾಂಶ", "ಸಾರಜನಕ", "ರಂಜಕ",
            # English
            "fertilizer", "urea", "dap", "potash", "npk", "manure",
            "compost", "vermicompost", "nutrient", "nitrogen",
            "phosphorus", "micronutrient", "zinc", "boron",
        ],
        "phrases": [
            "ಗೊಬ್ಬರ ಹಾಕ", "ಯೂರಿಯಾ ಹಾಕ", "ಎಷ್ಟು ಗೊಬ್ಬರ",
            "when to fertilize", "how much urea",
        ],
    },
    "irrigation": {
        "keywords": [
            # Kannada
            "ನೀರು", "ಹನಿ ನೀರಾವರಿ", "ತುಂತುರು", "ನೀರಾವರಿ",
            "ಬೋರ್‌ವೆಲ್", "ಕೆರೆ", "ಕಾಲುವೆ", "ಮಲ್ಚಿಂಗ್",
            # English
            "water", "irrigation", "drip", "sprinkler", "borewell",
            "mulching", "watering", "moisture",
        ],
        "phrases": [
            "ನೀರು ಹಾಕ", "ಎಷ್ಟು ನೀರು", "ನೀರು ಕೊಡ",
            "when to water", "how much water",
        ],
    },
    "crop_management": {
        "keywords": [
            # Kannada
            "ಬಿತ್ತನೆ", "ನಾಟಿ", "ಕೊಯ್ಲು", "ಬೆಳೆ", "ಗಿಡ",
            "ಬೀಜ", "ತಳಿ", "ಹೂ ಬಿಡು", "ಕಾಯಿ", "ಹಣ್ಣು",
            "ಕಳೆ", "ಕತ್ತರಿಸು", "ಅಂತರ ಬೇಸಾಯ",
            # English
            "sowing", "planting", "harvest", "crop", "seed",
            "variety", "flowering", "fruiting", "weeding",
            "pruning", "intercropping", "growth stage",
        ],
        "phrases": [
            "ಯಾವಾಗ ಬಿತ್ತನೆ", "ಯಾವ ತಳಿ", "ಕೊಯ್ಲು ಯಾವಾಗ",
            "when to sow", "best variety", "when to harvest",
        ],
    },
    "government_scheme": {
        "keywords": [
            # Kannada
            "ಯೋಜನೆ", "ಸಬ್ಸಿಡಿ", "ಅನುದಾನ", "ವಿಮೆ", "ಸಾಲ",
            "ಕಿಸಾನ್", "ಕೆಸಿಸಿ",
            # English
            "scheme", "subsidy", "grant", "insurance", "loan",
            "pm-kisan", "pmfby", "kcc", "kisan", "government",
            "benefit", "registration", "apply",
        ],
        "phrases": [
            "ಸರ್ಕಾರ ಯೋಜನೆ", "ಸಬ್ಸಿಡಿ ಸಿಗತ್ತಾ", "ಹೇಗೆ ಅರ್ಜಿ",
            "government scheme", "how to apply", "crop insurance",
        ],
    },
    "market_price": {
        "keywords": [
            # Kannada
            "ಬೆಲೆ", "ಮಾರುಕಟ್ಟೆ", "ಮಂಡಿ", "ಮಾರಾಟ",
            "ಎಂಎಸ್‌ಪಿ", "ದರ",
            # English
            "price", "market", "mandi", "sell", "msp",
            "rate", "apmc",
        ],
        "phrases": [
            "ಇವತ್ತಿನ ಬೆಲೆ", "ಎಲ್ಲಿ ಮಾರಾಟ", "ದರ ಎಷ್ಟು",
            "today price", "where to sell", "market rate",
        ],
    },
}

# Greeting patterns — handled separately for quick responses
GREETING_PATTERNS = [
    "ನಮಸ್ಕಾರ", "ಹಲೋ", "ಹೇಗಿದ್ದೀರಿ", "ಶುಭ", "ಧನ್ಯವಾದ",
    "hello", "hi", "hey", "good morning", "good evening",
    "thanks", "thank you", "namaste", "namaskara",
]


class IntentDetector:
    """
    Lightweight intent classifier using keyword matching.
    
    Supports Kannada and English queries. Uses phrase matching for higher
    confidence, falls back to keyword matching, and defaults to 'general'
    for greetings or unrecognized queries.
    """

    def detect(self, query: str) -> IntentResult:
        """
        Classify the farmer's query into an agricultural intent.
        
        Returns IntentResult with intent name and confidence score (0-1).
        """
        query_lower = query.lower().strip()

        # Check greetings first
        if self._is_greeting(query_lower):
            return IntentResult(intent="general", confidence=0.95, sub_intent="greeting")

        # Score each intent
        best_intent = "general"
        best_score = 0.0
        best_sub = ""

        for intent_name, patterns in INTENT_PATTERNS.items():
            score, sub = self._score_intent(query_lower, patterns)
            if score > best_score:
                best_score = score
                best_intent = intent_name
                best_sub = sub

        # Minimum threshold — below this, classify as general
        if best_score < 0.3:
            return IntentResult(intent="general", confidence=0.5)

        # Normalize confidence to 0-1 range
        confidence = min(best_score, 1.0)

        logger.info(f"Intent detected: {best_intent} (confidence={confidence:.2f}) for query: {query[:60]}...")
        return IntentResult(intent=best_intent, confidence=confidence, sub_intent=best_sub)

    def _is_greeting(self, query: str) -> bool:
        """Check if the query is a simple greeting."""
        # Short queries that match greeting patterns
        if len(query.split()) <= 4:
            for pattern in GREETING_PATTERNS:
                if pattern.lower() in query:
                    return True
        return False

    def _score_intent(self, query: str, patterns: dict) -> Tuple[float, str]:
        """
        Score how well a query matches an intent's patterns.
        
        Phrase matches score higher than individual keyword matches.
        Multiple keyword matches boost the score.
        """
        score = 0.0
        sub_intent = ""

        # Phase 1: Phrase matching (higher confidence)
        phrases = patterns.get("phrases", [])
        for phrase in phrases:
            if phrase.lower() in query:
                score += 0.6
                sub_intent = phrase
                break  # One phrase match is enough

        # Phase 2: Keyword matching
        keywords = patterns.get("keywords", [])
        keyword_hits = 0
        for keyword in keywords:
            if keyword.lower() in query:
                keyword_hits += 1

        if keyword_hits > 0:
            # First keyword: 0.4, each additional: 0.15 (diminishing)
            score += 0.4 + min(keyword_hits - 1, 3) * 0.15

        return score, sub_intent
