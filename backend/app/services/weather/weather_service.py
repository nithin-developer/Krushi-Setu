"""
Weather Service — Open-Meteo Integration

Fetches current weather and forecasts using the free Open-Meteo API.
No API key required. Includes in-memory caching to avoid redundant
calls for the same location within a configurable TTL.
"""

import logging
import time
from typing import Optional, Tuple

import httpx

from app.services.context.farmer_context import (
    CurrentWeather,
    DayForecast,
    WeatherInfo,
)

logger = logging.getLogger(__name__)

OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"

# WMO Weather Code to human-readable descriptions
WMO_WEATHER_CODES = {
    0: "Clear sky",
    1: "Mainly clear",
    2: "Partly cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Depositing rime fog",
    51: "Light drizzle",
    53: "Moderate drizzle",
    55: "Dense drizzle",
    56: "Light freezing drizzle",
    57: "Dense freezing drizzle",
    61: "Slight rain",
    63: "Moderate rain",
    65: "Heavy rain",
    66: "Light freezing rain",
    67: "Heavy freezing rain",
    71: "Slight snowfall",
    73: "Moderate snowfall",
    75: "Heavy snowfall",
    77: "Snow grains",
    80: "Slight rain showers",
    81: "Moderate rain showers",
    82: "Violent rain showers",
    85: "Slight snow showers",
    86: "Heavy snow showers",
    95: "Thunderstorm",
    96: "Thunderstorm with slight hail",
    99: "Thunderstorm with heavy hail",
}


class WeatherService:
    """
    Weather data provider using the Open-Meteo API.
    
    Features:
    - Current conditions: temperature, humidity, wind, precipitation
    - 7-day forecast: daily min/max temp, precipitation probability
    - In-memory cache with configurable TTL (default 1 hour)
    - Graceful error handling — returns None on failure
    """

    def __init__(self, cache_ttl_seconds: int = 3600):
        self._http_client = httpx.AsyncClient(timeout=15.0)
        self._cache: dict[str, Tuple[float, WeatherInfo]] = {}
        self._cache_ttl = cache_ttl_seconds

    def _cache_key(self, lat: float, lon: float) -> str:
        """Round coordinates to 2 decimal places for cache grouping."""
        return f"{round(lat, 2)}:{round(lon, 2)}"

    def _get_cached(self, lat: float, lon: float) -> Optional[WeatherInfo]:
        """Return cached weather if still fresh, None otherwise."""
        key = self._cache_key(lat, lon)
        if key in self._cache:
            timestamp, data = self._cache[key]
            if time.time() - timestamp < self._cache_ttl:
                logger.debug(f"Weather cache hit for {key}")
                return data
            else:
                del self._cache[key]
        return None

    def _set_cache(self, lat: float, lon: float, data: WeatherInfo):
        """Store weather data in cache."""
        key = self._cache_key(lat, lon)
        self._cache[key] = (time.time(), data)

    async def get_weather(
        self,
        latitude: float,
        longitude: float,
        forecast_days: int = 7,
        location_name: str = "",
    ) -> Optional[WeatherInfo]:
        """
        Fetch current weather and forecast for a location.
        
        Args:
            latitude: Farm latitude
            longitude: Farm longitude
            forecast_days: Number of forecast days (1-16)
            location_name: Human-readable location name (e.g. "Mysuru, Karnataka")
        
        Returns:
            WeatherInfo with current conditions and daily forecast, or None on error.
        """
        # Check cache first
        cached = self._get_cached(latitude, longitude)
        if cached is not None:
            return cached

        params = {
            "latitude": latitude,
            "longitude": longitude,
            "current": "temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m",
            "daily": "weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max",
            "timezone": "Asia/Kolkata",
            "forecast_days": min(forecast_days, 16),
        }

        try:
            response = await self._http_client.get(OPEN_METEO_URL, params=params)

            if response.status_code != 200:
                logger.error(f"Open-Meteo error {response.status_code}: {response.text[:200]}")
                return None

            data = response.json()

            # Parse current weather
            current_data = data.get("current", {})
            current = CurrentWeather(
                temperature_c=current_data.get("temperature_2m"),
                feels_like_c=current_data.get("apparent_temperature"),
                humidity_percent=current_data.get("relative_humidity_2m"),
                wind_speed_kmh=current_data.get("wind_speed_10m"),
                precipitation_mm=current_data.get("precipitation"),
                weather_description=WMO_WEATHER_CODES.get(
                    current_data.get("weather_code", -1), "Unknown"
                ),
            )

            # Parse daily forecast
            daily = data.get("daily", {})
            dates = daily.get("time", [])
            forecast_list = []

            for i, date in enumerate(dates):
                day = DayForecast(
                    date=date,
                    temp_max_c=_safe_index(daily.get("temperature_2m_max"), i),
                    temp_min_c=_safe_index(daily.get("temperature_2m_min"), i),
                    precipitation_sum_mm=_safe_index(daily.get("precipitation_sum"), i),
                    precipitation_probability=_safe_index(daily.get("precipitation_probability_max"), i),
                    weather_description=WMO_WEATHER_CODES.get(
                        _safe_index(daily.get("weather_code"), i, -1), "Unknown"
                    ),
                )
                forecast_list.append(day)

            weather_info = WeatherInfo(
                current=current,
                forecast=forecast_list,
                location_name=location_name,
            )

            # Cache the result
            self._set_cache(latitude, longitude, weather_info)

            logger.info(
                f"Weather fetched for {location_name or f'{latitude},{longitude}'}: "
                f"{current.temperature_c}°C, {current.weather_description}"
            )
            return weather_info

        except httpx.HTTPError as e:
            logger.error(f"Weather HTTP error: {e}")
            return None
        except Exception as e:
            logger.error(f"Weather unexpected error: {e}")
            return None

    async def close(self):
        """Close the HTTP client."""
        await self._http_client.aclose()


def _safe_index(lst, idx, default=None):
    """Safely index into a list, returning default if out of bounds."""
    if lst is None or idx >= len(lst):
        return default
    return lst[idx]


# Singleton instance — shared across the application
weather_service = WeatherService()
