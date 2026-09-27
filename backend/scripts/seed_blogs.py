import sys
import os
import io
import asyncio

# Fix Windows console encoding
if sys.stdout.encoding != 'utf-8':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

# Add backend directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.db.mongodb import connect_to_mongo, close_mongo_connection
from app.models.blog import BlogModel

INITIAL_BLOGS = [
    {
        "title": "Pradhan Mantri Kisan Samman Nidhi (PM-KISAN)",
        "category": "scheme",
        "category_label": "Govt Scheme",
        "summary": "Direct income support of ₹6,000 per year in three equal installments to all landholding farmer families.",
        "content": "Under PM-KISAN, financial assistance of ₹6,000/year is transferred directly into Aadhaar-seeded bank accounts of beneficiary farmers. Ensure farmers have completed e-KYC and updated land records in the Krushi Setu Digital Twin.",
        "cover_image": "https://images.unsplash.com/photo-1595974482597-4b8da8879bc5?auto=format&fit=crop&w=800&q=80",
        "tags": ["PM-KISAN", "Income Support", "Government Scheme", "Subsidy"],
        "target_crops": ["All Crops"],
        "author": "Ministry of Agriculture & Farmers Welfare",
        "status": "published"
    },
    {
        "title": "Pradhan Mantri Fasal Bima Yojana (PMFBY)",
        "category": "scheme",
        "category_label": "Crop Insurance",
        "summary": "Comprehensive crop insurance coverage against non-preventable natural risks from pre-sowing to post-harvest.",
        "content": "Covers financial loss suffered due to natural calamities like drought, flood, pests, and diseases. Farmers pay a nominal premium: 2% for Kharif crops, 1.5% for Rabi crops, and 5% for commercial/horticultural crops.",
        "cover_image": "https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=800&q=80",
        "tags": ["PMFBY", "Insurance", "Kharif", "Rabi"],
        "target_crops": ["Paddy", "Wheat", "Cotton", "Sugarcane"],
        "author": "Government of India",
        "status": "published"
    },
    {
        "title": "Kharif Paddy: Blast & Stem Borer Management",
        "category": "pest",
        "category_label": "Pest Alert",
        "summary": "High humidity and cloudy weather increase blast disease incidence in early-tillering paddy.",
        "content": "Monitor for spindle-shaped lesions on leaves with brown margins. Spray Tricyclazole 75% WP @ 0.6g/L or Isoprothiolane 40% EC @ 1.5ml/L of water. For stem borer, set up pheromone traps @ 5/acre.",
        "cover_image": "https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?auto=format&fit=crop&w=800&q=80",
        "tags": ["Paddy", "Blast Disease", "Stem Borer", "Pest Management"],
        "target_crops": ["Paddy (Rice)"],
        "author": "ICAR - Indian Agricultural Research Institute",
        "status": "published"
    },
    {
        "title": "Soil Health Card & Micronutrient Optimization",
        "category": "soil",
        "category_label": "Soil Health",
        "summary": "Soil testing guidelines for optimal NPK balance and correction of Zinc & Boron deficiencies.",
        "content": "Regular soil testing prevents fertilizer over-application and reduces input costs by up to 25%. Encourage farmers to follow customized fertilizer recommendations based on Digital Twin soil data.",
        "cover_image": "https://images.unsplash.com/photo-1464226184884-fa280b87c399?auto=format&fit=crop&w=800&q=80",
        "tags": ["Soil Testing", "NPK", "Micronutrients", "Fertilizer"],
        "target_crops": ["All Crops"],
        "author": "Department of Agriculture",
        "status": "published"
    },
    {
        "title": "Heavy Rainfall & Waterlogging Alert - Southern Deccan Region",
        "category": "weather",
        "category_label": "Weather Alert",
        "summary": "Moderate to heavy showers expected across Dharwad, Belagavi, and Shimoga districts.",
        "content": "Ensure adequate drainage channels in cotton, groundnut, and vegetable fields to prevent root rot. Delay top dressing of urea until rain subsides.",
        "cover_image": "https://images.unsplash.com/photo-1515694346937-94d85e41e6f0?auto=format&fit=crop&w=800&q=80",
        "tags": ["Rainfall", "Waterlogging", "IMD Alert", "Weather"],
        "target_crops": ["Cotton", "Groundnut", "Vegetables"],
        "author": "India Meteorological Department (IMD)",
        "status": "published"
    }
]

async def seed_blogs():
    print("🌱 Connecting to MongoDB...")
    await connect_to_mongo()
    
    count = await BlogModel.count_blogs()
    if count == 0:
        print("Empty blog collection found. Seeding initial blogs...")
        for blog_data in INITIAL_BLOGS:
            created = await BlogModel.create(blog_data)
            print(f"  ✅ Seeded: {created['title']} (id: {created['id']})")
        print("🎉 Seeding completed successfully!")
    else:
        print(f"ℹ️ Collection already contains {count} blogs. Skipping seed.")
        
    await close_mongo_connection()

if __name__ == "__main__":
    asyncio.run(seed_blogs())
