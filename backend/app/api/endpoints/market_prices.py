from fastapi import APIRouter, Query
from typing import Optional, List
from datetime import datetime, timezone

router = APIRouter()

# Seed dataset of Mandi Commodity Prices across Karnataka & Indian Districts
MARKET_DATA = [
    {
        "id": "mp-1",
        "commodity": "Paddy (Dhan) - Common",
        "category": "Cereals",
        "state": "Karnataka",
        "district": "Dharwad",
        "mandi": "Dharwad APMC",
        "min_price": 2200,
        "max_price": 2480,
        "modal_price": 2350,
        "unit": "Quintal (100 kg)",
        "trend": "up", # up, down, stable
        "last_updated": "2026-09-20T10:00:00Z"
    },
    {
        "id": "mp-2",
        "commodity": "Paddy (Dhan) - Grade A",
        "category": "Cereals",
        "state": "Karnataka",
        "district": "Belagavi",
        "mandi": "Belagavi Market",
        "min_price": 2350,
        "max_price": 2600,
        "modal_price": 2500,
        "unit": "Quintal (100 kg)",
        "trend": "stable",
        "last_updated": "2026-09-20T10:00:00Z"
    },
    {
        "id": "mp-3",
        "commodity": "Cotton (Medium Staple)",
        "category": "Commercial Crops",
        "state": "Karnataka",
        "district": "Dharwad",
        "mandi": "Hubballi APMC",
        "min_price": 6800,
        "max_price": 7450,
        "modal_price": 7200,
        "unit": "Quintal (100 kg)",
        "trend": "up",
        "last_updated": "2026-09-20T09:30:00Z"
    },
    {
        "id": "mp-4",
        "commodity": "Maize (Corn)",
        "category": "Cereals",
        "state": "Karnataka",
        "district": "Shimoga",
        "mandi": "Shimoga Mandi",
        "min_price": 2050,
        "max_price": 2250,
        "modal_price": 2180,
        "unit": "Quintal (100 kg)",
        "trend": "down",
        "last_updated": "2026-09-20T11:15:00Z"
    },
    {
        "id": "mp-5",
        "commodity": "Groundnut (Pods)",
        "category": "Oilseeds",
        "state": "Karnataka",
        "district": "Belagavi",
        "mandi": "Chikodi APMC",
        "min_price": 5800,
        "max_price": 6500,
        "modal_price": 6250,
        "unit": "Quintal (100 kg)",
        "trend": "up",
        "last_updated": "2026-09-20T08:45:00Z"
    },
    {
        "id": "mp-6",
        "commodity": "Chilli (Red Dryer)",
        "category": "Spices",
        "state": "Karnataka",
        "district": "Dharwad",
        "mandi": "Byadgi APMC",
        "min_price": 14500,
        "max_price": 18200,
        "modal_price": 16500,
        "unit": "Quintal (100 kg)",
        "trend": "up",
        "last_updated": "2026-09-20T10:30:00Z"
    },
    {
        "id": "mp-7",
        "commodity": "Sugarcane",
        "category": "Commercial Crops",
        "state": "Karnataka",
        "district": "Belagavi",
        "mandi": "Belagavi Sugarcane APMC",
        "min_price": 3150,
        "max_price": 3400,
        "modal_price": 3300,
        "unit": "Tonne (1000 kg)",
        "trend": "stable",
        "last_updated": "2026-09-20T09:00:00Z"
    },
    {
        "id": "mp-8",
        "commodity": "Turmeric (Raw)",
        "category": "Spices",
        "state": "Karnataka",
        "district": "Shimoga",
        "mandi": "Sagar Mandi",
        "min_price": 11200,
        "max_price": 13400,
        "modal_price": 12500,
        "unit": "Quintal (100 kg)",
        "trend": "stable",
        "last_updated": "2026-09-20T10:00:00Z"
    }
]

@router.get("")
async def get_market_prices(
    state: Optional[str] = Query(None),
    district: Optional[str] = Query(None),
    commodity: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
):
    """
    Get Mandi Market Prices with optional state, district, commodity, and search query filters.
    """
    results = MARKET_DATA

    if state and state.lower() != "all":
        results = [m for m in results if m["state"].lower() == state.lower()]

    if district and district.lower() != "all":
        results = [m for m in results if m["district"].lower() == district.lower()]

    if commodity and commodity.lower() != "all":
        results = [m for m in results if m["category"].lower() == commodity.lower() or commodity.lower() in m["commodity"].lower()]

    if search:
        s = search.lower()
        results = [
            m for m in results
            if s in m["commodity"].lower() or s in m["district"].lower() or s in m["mandi"].lower()
        ]

    # Available filter dropdown options
    districts = sorted(list(set(m["district"] for m in MARKET_DATA)))
    states = sorted(list(set(m["state"] for m in MARKET_DATA)))
    categories = sorted(list(set(m["category"] for m in MARKET_DATA)))

    return {
        "total": len(results),
        "prices": results,
        "available_districts": districts,
        "available_states": states,
        "available_categories": categories,
        "last_sync": datetime.now(timezone.utc).isoformat()
    }
