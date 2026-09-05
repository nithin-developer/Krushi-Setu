from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any
from app.models.location import LocationModel

router = APIRouter()

@router.get("/states")
async def get_states():
    try:
        states = await LocationModel.get_all_states()
        return {"states": states}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/states/{state_id}/districts")
async def get_districts(state_id: str):
    try:
        districts = await LocationModel.get_districts_by_state(state_id)
        return {"districts": districts}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/districts/{district_id}/sub-districts")
async def get_sub_districts(district_id: str):
    try:
        sub_districts = await LocationModel.get_sub_districts_by_district(district_id)
        return {"sub_districts": sub_districts}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
