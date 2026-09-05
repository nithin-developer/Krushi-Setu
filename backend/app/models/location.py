from bson import ObjectId
from app.db.mongodb import get_db

class LocationModel:
    @classmethod
    def get_states_collection(cls):
        db = get_db()
        return db["states"]

    @classmethod
    def get_districts_collection(cls):
        db = get_db()
        return db["districts"]

    @classmethod
    def get_sub_districts_collection(cls):
        db = get_db()
        return db["sub_districts"]

    @classmethod
    async def get_all_states(cls):
        collection = cls.get_states_collection()
        states = await collection.find({}).sort("name", 1).to_list(length=None)
        for state in states:
            state["_id"] = str(state["_id"])
        return states

    @classmethod
    async def get_districts_by_state(cls, state_id: str):
        collection = cls.get_districts_collection()
        districts = await collection.find({"state_id": state_id}).sort("name", 1).to_list(length=None)
        for dist in districts:
            dist["_id"] = str(dist["_id"])
            dist["state_id"] = str(dist["state_id"])
        return districts

    @classmethod
    async def get_sub_districts_by_district(cls, district_id: str):
        collection = cls.get_sub_districts_collection()
        sub_districts = await collection.find({"district_id": district_id}).sort("name", 1).to_list(length=None)
        for sd in sub_districts:
            sd["_id"] = str(sd["_id"])
            sd["district_id"] = str(sd["district_id"])
        return sub_districts
