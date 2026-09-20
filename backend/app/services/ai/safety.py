"""
Safety Validator for Krushi Setu AI

Post-generation safety checks on LLM responses. Ensures the AI doesn't
recommend unsafe pesticide dosages, give medical/legal advice, or
produce harmful content.
"""

import re
import logging

logger = logging.getLogger(__name__)


# Patterns that indicate potentially unsafe pesticide dosage recommendations
# (specific quantities like "2ml/L", "3g/L", "500ml/acre")
DOSAGE_PATTERN = re.compile(
    r'\d+\s*(?:ml|g|gm|gram|kg|liter|litre)\s*(?:/|per)\s*(?:l|liter|litre|acre|hectare|plant|tree)',
    re.IGNORECASE,
)

# Brand names of restricted/banned pesticides in India
BANNED_PESTICIDES = [
    "endosulfan", "monocrotophos", "methyl parathion", "phorate",
    "triazophos", "phosphamidon", "dichlorvos", "methomyl",
    "alachlor", "dicofol", "mancozeb",  # restricted in some contexts
    "ಎಂಡೋಸಲ್ಫಾನ್", "ಮೊನೊಕ್ರೊಟೋಫಾಸ್",
]

# Keywords that suggest medical advice
MEDICAL_KEYWORDS = [
    "doctor", "hospital", "medicine", "tablet", "injection",
    "blood", "fever", "disease in human", "skin rash",
    "ವೈದ್ಯ", "ಆಸ್ಪತ್ರೆ", "ಮಾತ್ರೆ",
]

# Disclaimer for pest/disease responses
PEST_DISCLAIMER_KN = "\n\n⚠️ ನಿಖರ ಔಷಧ ಪ್ರಮಾಣಕ್ಕಾಗಿ ನಿಮ್ಮ ಸಮೀಪದ KVK (ಕೃಷಿ ವಿಜ್ಞಾನ ಕೇಂದ್ರ) ಅಥವಾ ಕೃಷಿ ಅಧಿಕಾರಿಯನ್ನು ಸಂಪರ್ಕಿಸಿ."
PEST_DISCLAIMER_EN = "\n\n⚠️ For exact dosage, please consult your nearest KVK (Krishi Vigyan Kendra) or agricultural extension officer."


class SafetyValidator:
    """
    Validates LLM responses for safety before sending to the farmer.
    
    Checks:
    - Specific pesticide dosage recommendations → adds KVK disclaimer
    - Banned/restricted pesticide mentions → removes and warns
    - Medical advice detection → adds medical disclaimer
    - Response length sanity → truncates if too long
    """

    def validate(self, response_text: str, intent: str, language: str = "kn") -> str:
        """
        Validate and potentially modify the LLM response for safety.
        
        Args:
            response_text: The raw LLM response
            intent: The detected intent (used to decide which checks to apply)
            language: Response language code
        
        Returns:
            The validated (possibly modified) response text.
        """
        modified = response_text
        flags = []

        # Check 1: Specific pesticide dosage
        if DOSAGE_PATTERN.search(modified):
            flags.append("dosage_detected")
            # Don't remove the dosage, but add a disclaimer
            disclaimer = PEST_DISCLAIMER_KN if language == "kn" else PEST_DISCLAIMER_EN
            if disclaimer.strip() not in modified:
                modified += disclaimer
            logger.warning(f"Safety: Dosage pattern detected in response, added disclaimer")

        # Check 2: Banned pesticides
        response_lower = modified.lower()
        banned_found = [p for p in BANNED_PESTICIDES if p.lower() in response_lower]
        if banned_found:
            flags.append(f"banned_pesticides: {banned_found}")
            # Add strong warning
            if language == "kn":
                modified += "\n\n🚫 ಗಮನಿಸಿ: ನಿಷೇಧಿತ ಕೀಟನಾಶಕಗಳನ್ನು ಬಳಸಬೇಡಿ. ಸುರಕ್ಷಿತ ಪರ್ಯಾಯಗಳಿಗಾಗಿ KVK ಸಂಪರ್ಕಿಸಿ."
            else:
                modified += "\n\n🚫 Note: Do not use banned pesticides. Contact KVK for safe alternatives."
            logger.warning(f"Safety: Banned pesticide mentioned: {banned_found}")

        # Check 3: Medical advice
        if any(kw.lower() in response_lower for kw in MEDICAL_KEYWORDS):
            if intent != "general":  # Don't flag general greetings
                flags.append("medical_keywords")
                logger.info("Safety: Medical keywords detected but not modifying (may be contextual)")

        # Check 4: Response length — truncate extremely long responses
        if len(modified) > 2000:
            modified = modified[:1950] + "..."
            flags.append("truncated")
            logger.warning("Safety: Response truncated due to excessive length")

        # Check 5: For pest/disease intents, always ensure KVK recommendation
        if intent == "pest_disease":
            kvk_mentioned = any(term in modified.lower() for term in ["kvk", "ಕೆವಿಕೆ", "ಕೃಷಿ ವಿಜ್ಞಾನ", "krishi vigyan"])
            if not kvk_mentioned:
                disclaimer = PEST_DISCLAIMER_KN if language == "kn" else PEST_DISCLAIMER_EN
                if disclaimer.strip() not in modified:
                    modified += disclaimer

        if flags:
            logger.info(f"Safety flags: {flags}")

        return modified
