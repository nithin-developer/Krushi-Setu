from pydantic import BaseModel, Field
from typing import List, Optional, Any

class LocationData(BaseModel):
    state: str
    district: str
    taluk: str
    village: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    polygon_geojson: Optional[Any] = None

class LandSizeData(BaseModel):
    size_value: float
    unit: str

class WaterData(BaseModel):
    sources: List[str] = Field(min_length=1)

class CropData(BaseModel):
    crops: List[str] = Field(min_length=1)
    additional_notes: Optional[str] = None

class DigitalTwinProfile(BaseModel):
    location: LocationData
    land_size: LandSizeData
    water: WaterData
    crops: CropData
