import asyncio
import csv
import os
import sys

# Add backend directory to sys.path
current_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.dirname(os.path.dirname(current_dir))
sys.path.append(backend_dir)

from app.db.mongodb import connect_to_mongo, close_mongo_connection, get_db

async def seed_locations():
    await connect_to_mongo()
    db = get_db()
    
    states_coll = db["states"]
    districts_coll = db["districts"]
    sub_districts_coll = db["sub_districts"]

    # Clear existing data
    await states_coll.delete_many({})
    await districts_coll.delete_many({})
    await sub_districts_coll.delete_many({})

    csv_path = os.path.join(backend_dir, "All_Sub_Districtof_India_2026-08-09_22-02-13.csv")
    
    states_cache = {}
    districts_cache = {}

    print(f"Reading CSV from {csv_path}...")
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        sub_districts_batch = []
        
        for row in reader:
            state_name = row["State Name"].strip()
            district_name = row["District Name"].strip()
            sub_district_name = row["Sub-district Name"].strip()
            
            # State
            if state_name not in states_cache:
                result = await states_coll.insert_one({"name": state_name})
                states_cache[state_name] = str(result.inserted_id)
            
            state_id = states_cache[state_name]
            
            # District
            district_key = f"{state_id}_{district_name}"
            if district_key not in districts_cache:
                result = await districts_coll.insert_one({
                    "name": district_name,
                    "state_id": state_id
                })
                districts_cache[district_key] = str(result.inserted_id)
                
            district_id = districts_cache[district_key]
            
            # Sub-district
            sub_districts_batch.append({
                "name": sub_district_name,
                "district_id": district_id
            })
            
            if len(sub_districts_batch) >= 1000:
                await sub_districts_coll.insert_many(sub_districts_batch)
                sub_districts_batch = []
                
        if sub_districts_batch:
            await sub_districts_coll.insert_many(sub_districts_batch)

    # Create indexes
    await districts_coll.create_index("state_id")
    await sub_districts_coll.create_index("district_id")
    
    print("Seeding completed successfully!")
    await close_mongo_connection()

if __name__ == "__main__":
    asyncio.run(seed_locations())
