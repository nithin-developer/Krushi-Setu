"""
Farmer Context Models for Krushi Setu AI

Standardized Pydantic models representing the farmer's context that gets
injected into LLM prompts. This is the common interface between the
Digital Twin and the AI orchestrator.
"""

from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime


class FarmerInfo(BaseModel):
    """Basic farmer identity — always included in context."""
    id: str
    name: str = ""
    language: str = "kn"
    state: str = ""
    district: str = ""
    taluk: str = ""
    village: str = ""


class FarmInfo(BaseModel):
    """Farm details from the Digital Twin."""
    area_value: float = 0.0
    area_unit: str = "Acre"
    soil_type: str = ""
    water_sources: List[str] = Field(default_factory=list)
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class CropInfo(BaseModel):
    """Current crop information from the Digital Twin."""
    name: str = ""
    variety: str = ""
    sowing_date: Optional[str] = None
    growth_stage: str = ""
    additional_notes: str = ""


class CurrentWeather(BaseModel):
    """Current weather conditions from Open-Meteo."""
    temperature_c: Optional[float] = None
    feels_like_c: Optional[float] = None
    humidity_percent: Optional[int] = None
    wind_speed_kmh: Optional[float] = None
    precipitation_mm: Optional[float] = None
    weather_description: str = ""


class DayForecast(BaseModel):
    """Single day's weather forecast."""
    date: str
    temp_max_c: Optional[float] = None
    temp_min_c: Optional[float] = None
    precipitation_sum_mm: Optional[float] = None
    precipitation_probability: Optional[int] = None
    weather_description: str = ""


class WeatherInfo(BaseModel):
    """Combined current weather + forecast."""
    current: Optional[CurrentWeather] = None
    forecast: List[DayForecast] = Field(default_factory=list)
    location_name: str = ""


class ActivityInfo(BaseModel):
    """A recent farm activity record."""
    activity_type: str  # e.g. "fertilizer", "irrigation", "spraying"
    description: str = ""
    date: Optional[str] = None


class FarmerContext(BaseModel):
    """
    The complete, query-aware context object passed to the LLM.
    
    Not all fields are populated for every query — the ContextBuilder
    selectively fills only what's relevant to the detected intent.
    """
    farmer: FarmerInfo
    farm: Optional[FarmInfo] = None
    crop: Optional[CropInfo] = None
    weather: Optional[WeatherInfo] = None
    recent_activities: List[ActivityInfo] = Field(default_factory=list)
    conversation_summary: Optional[str] = None

    def to_prompt_string(self) -> str:
        """
        Render the context as a human-readable string for the LLM prompt.
        Only includes sections that have data.
        """
        parts = []

        # Farmer info
        farmer_parts = []
        if self.farmer.name:
            farmer_parts.append(f"Name: {self.farmer.name}")
        if self.farmer.district:
            farmer_parts.append(f"Location: {self.farmer.district}, {self.farmer.state}")
        elif self.farmer.state:
            farmer_parts.append(f"State: {self.farmer.state}")
        if self.farmer.language:
            lang_names = {"kn": "Kannada", "en": "English", "hi": "Hindi", "te": "Telugu", "ta": "Tamil", "mr": "Marathi"}
            farmer_parts.append(f"Language: {lang_names.get(self.farmer.language, self.farmer.language)}")
        if farmer_parts:
            parts.append("**Farmer:**\n" + "\n".join(f"- {p}" for p in farmer_parts))

        # Farm info
        if self.farm:
            farm_parts = []
            if self.farm.area_value > 0:
                farm_parts.append(f"Land: {self.farm.area_value} {self.farm.area_unit}")
            if self.farm.soil_type:
                farm_parts.append(f"Soil: {self.farm.soil_type}")
            if self.farm.water_sources:
                farm_parts.append(f"Water: {', '.join(self.farm.water_sources)}")
            if farm_parts:
                parts.append("**Farm:**\n" + "\n".join(f"- {p}" for p in farm_parts))

        # Crop info
        if self.crop and self.crop.name:
            crop_parts = [f"Crop: {self.crop.name}"]
            if self.crop.variety:
                crop_parts.append(f"Variety: {self.crop.variety}")
            if self.crop.growth_stage:
                crop_parts.append(f"Growth stage: {self.crop.growth_stage}")
            if self.crop.sowing_date:
                crop_parts.append(f"Sowing date: {self.crop.sowing_date}")
            if self.crop.additional_notes:
                crop_parts.append(f"Notes: {self.crop.additional_notes}")
            parts.append("**Crop:**\n" + "\n".join(f"- {p}" for p in crop_parts))

        # Weather info
        if self.weather:
            weather_parts = []
            if self.weather.location_name:
                weather_parts.append(f"Location: {self.weather.location_name}")
            if self.weather.current:
                c = self.weather.current
                if c.temperature_c is not None:
                    weather_parts.append(f"Temperature: {c.temperature_c}°C")
                if c.humidity_percent is not None:
                    weather_parts.append(f"Humidity: {c.humidity_percent}%")
                if c.wind_speed_kmh is not None:
                    weather_parts.append(f"Wind: {c.wind_speed_kmh} km/h")
                if c.precipitation_mm is not None and c.precipitation_mm > 0:
                    weather_parts.append(f"Current precipitation: {c.precipitation_mm} mm")
                if c.weather_description:
                    weather_parts.append(f"Conditions: {c.weather_description}")
            if self.weather.forecast:
                forecast_lines = []
                for day in self.weather.forecast[:5]:  # Max 5 days in prompt
                    line = f"  {day.date}: {day.temp_min_c}–{day.temp_max_c}°C"
                    if day.precipitation_probability is not None:
                        line += f", rain {day.precipitation_probability}%"
                    if day.precipitation_sum_mm and day.precipitation_sum_mm > 0:
                        line += f" ({day.precipitation_sum_mm}mm)"
                    if day.weather_description:
                        line += f" — {day.weather_description}"
                    forecast_lines.append(line)
                weather_parts.append("Forecast:\n" + "\n".join(forecast_lines))
            if weather_parts:
                parts.append("**Weather:**\n" + "\n".join(f"- {p}" for p in weather_parts))

        # Recent activities
        if self.recent_activities:
            act_lines = []
            for act in self.recent_activities[:5]:
                line = f"- [{act.activity_type}] {act.description}"
                if act.date:
                    line += f" ({act.date})"
                act_lines.append(line)
            parts.append("**Recent Activities:**\n" + "\n".join(act_lines))

        # Conversation summary
        if self.conversation_summary:
            parts.append(f"**Previous Conversation Summary:**\n{self.conversation_summary}")

        return "\n\n".join(parts) if parts else "No additional context available."
