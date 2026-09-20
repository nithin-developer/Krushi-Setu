"""
Context Builder — Query-Aware Farmer Context Assembly

Selectively fetches farmer data from the Digital Twin, weather from
Open-Meteo, and conversation history from MongoDB — based on the
detected intent. Avoids sending the entire Digital Twin for simple queries.
"""

import logging
from typing import Optional

from app.models.user import UserModel
from app.services.context.farmer_context import (
    FarmerContext,
    FarmerInfo,
    FarmInfo,
    CropInfo,
    WeatherInfo,
    ActivityInfo,
)
from app.services.weather.weather_service import weather_service

logger = logging.getLogger(__name__)


# Which context components each intent needs
INTENT_CONTEXT_MAP = {
    "weather":           {"farmer": True, "farm_location": True, "weather": True, "crop": False, "activities": False},
    "pest_disease":      {"farmer": True, "farm_location": True, "weather": True, "crop": True,  "activities": False},
    "fertilizer":        {"farmer": True, "farm_location": True, "weather": False, "crop": True,  "activities": True},
    "irrigation":        {"farmer": True, "farm_location": True, "weather": True, "crop": True,  "activities": False},
    "crop_management":   {"farmer": True, "farm_location": True, "weather": False, "crop": True,  "activities": True},
    "government_scheme": {"farmer": True, "farm_location": True, "weather": False, "crop": True,  "activities": False},
    "market_price":      {"farmer": True, "farm_location": True, "weather": False, "crop": True,  "activities": False},
    "general":           {"farmer": True, "farm_location": False, "weather": False, "crop": False, "activities": False},
}


class ContextBuilder:
    """
    Builds a query-aware FarmerContext by selectively fetching data.
    
    For a weather query, we only need location + weather.
    For a pest query, we need crop + weather + location.
    For a greeting, we just need the farmer's name.
    
    This keeps LLM prompts focused and reduces token usage.
    """

    async def build(
        self,
        farmer_id: str,
        intent: str,
        conversation_summary: Optional[str] = None,
    ) -> FarmerContext:
        """
        Build the farmer context based on detected intent.
        
        Args:
            farmer_id: The farmer's user ID in MongoDB
            intent: Detected intent (e.g., "weather", "pest_disease")
            conversation_summary: Optional summary of recent conversation
        
        Returns:
            FarmerContext with only the relevant fields populated.
        """
        needs = INTENT_CONTEXT_MAP.get(intent, INTENT_CONTEXT_MAP["general"])

        # Always fetch the user document — it contains the Digital Twin
        user = await UserModel.get_by_id(farmer_id)
        if not user:
            logger.warning(f"No user found for farmer_id={farmer_id}")
            return FarmerContext(
                farmer=FarmerInfo(id=farmer_id or "anonymous", language="kn"),
                conversation_summary=conversation_summary,
            )

        digital_twin = user.get("digital_twin", {})
        has_twin = bool(digital_twin)

        # 1. Build farmer info (always included)
        farmer_info = self._build_farmer_info(user, digital_twin)

        # 2. Build farm info (if needed and available)
        farm_info = None
        if needs.get("farm_location") and has_twin:
            farm_info = self._build_farm_info(digital_twin)

        # 3. Build crop info (if needed and available)
        crop_info = None
        if needs.get("crop") and has_twin:
            crop_info = self._build_crop_info(digital_twin)

        # 4. Fetch weather (if needed and we have coordinates)
        weather_info = None
        if needs.get("weather") and has_twin:
            weather_info = await self._fetch_weather(digital_twin, farmer_info)

        # 5. Recent activities (placeholder — will be populated when activity tracking is added)
        activities = []

        context = FarmerContext(
            farmer=farmer_info,
            farm=farm_info,
            crop=crop_info,
            weather=weather_info,
            recent_activities=activities,
            conversation_summary=conversation_summary,
        )

        logger.info(
            f"Context built for farmer={farmer_id}, intent={intent}: "
            f"farm={'✓' if farm_info else '✗'}, "
            f"crop={'✓' if crop_info else '✗'}, "
            f"weather={'✓' if weather_info else '✗'}"
        )
        return context

    def _build_farmer_info(self, user: dict, digital_twin: dict) -> FarmerInfo:
        """Extract farmer identity from user document."""
        location = digital_twin.get("location", {})

        return FarmerInfo(
            id=user.get("_id", ""),
            name=user.get("full_name", ""),
            language=user.get("preferred_language", "kn"),
            state=location.get("state", ""),
            district=location.get("district", ""),
            taluk=location.get("taluk", ""),
            village=location.get("village", ""),
        )

    def _build_farm_info(self, digital_twin: dict) -> Optional[FarmInfo]:
        """Extract farm details from the Digital Twin."""
        location = digital_twin.get("location", {})
        land_size = digital_twin.get("land_size", {})
        water = digital_twin.get("water", {})

        return FarmInfo(
            area_value=land_size.get("size_value", 0.0),
            area_unit=land_size.get("unit", "Acre"),
            soil_type="",  # Not yet in Digital Twin — will be added later
            water_sources=water.get("sources", []),
            latitude=location.get("latitude"),
            longitude=location.get("longitude"),
        )

    def _build_crop_info(self, digital_twin: dict) -> Optional[CropInfo]:
        """Extract crop information from the Digital Twin."""
        crops_data = digital_twin.get("crops", {})
        crops_list = crops_data.get("crops", [])

        if not crops_list:
            return None

        # For now, use the first crop. In the future, intent detection
        # could identify which crop the farmer is asking about.
        primary_crop = crops_list[0] if crops_list else ""

        return CropInfo(
            name=primary_crop,
            variety="",  # Not yet in Digital Twin
            sowing_date=None,  # Not yet tracked
            growth_stage="",  # Not yet tracked
            additional_notes=crops_data.get("additional_notes", ""),
        )

    async def _fetch_weather(
        self, digital_twin: dict, farmer_info: FarmerInfo
    ) -> Optional[WeatherInfo]:
        """Fetch weather data from Open-Meteo using Digital Twin coordinates."""
        location = digital_twin.get("location", {})
        lat = location.get("latitude")
        lon = location.get("longitude")

        if lat is None or lon is None:
            logger.info("No coordinates in Digital Twin — skipping weather fetch")
            return None

        location_name = ""
        if farmer_info.district and farmer_info.state:
            location_name = f"{farmer_info.district}, {farmer_info.state}"
        elif farmer_info.state:
            location_name = farmer_info.state

        return await weather_service.get_weather(
            latitude=lat,
            longitude=lon,
            forecast_days=7,
            location_name=location_name,
        )
