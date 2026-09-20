"""
Seed Knowledge Base Script

Ingests initial agricultural documents into the Qdrant knowledge base.
Run this once to populate the KB with seed data.

Usage:
    cd backend
    python scripts/seed_knowledge.py

Options:
    python scripts/seed_knowledge.py --file docs/schemes/pm_kisan.md --category government_scheme
    python scripts/seed_knowledge.py --dir docs/schemes/ --category government_scheme
    python scripts/seed_knowledge.py --all   (ingest all seed documents)
"""

import sys
import os
import io
import argparse
import time

# Fix Windows console encoding for emojis/Unicode
if sys.stdout.encoding != 'utf-8':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

# Add the backend directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.services.knowledge.ingestion import DocumentIngestionPipeline


# Seed data configuration: (directory, category, tags, language, crops)
SEED_CONFIG = [
    {
        "dir": "docs/schemes",
        "category": "government_scheme",
        "tags": ["scheme", "subsidy", "government"],
        "language": "en",
        "region": "all_india",
        "crops": [],
    },
    {
        "dir": "docs/pest_guides",
        "category": "pest_disease",
        "tags": ["pest", "disease", "management", "ipm"],
        "language": "en",
        "region": "south_india",
        "crops": [],
    },
    {
        "dir": "docs/crop_guides",
        "category": "crop_guide",
        "tags": ["cultivation", "farming", "crop"],
        "language": "en",
        "region": "karnataka",
        "crops": [],
    },
]


def seed_all(pipeline: DocumentIngestionPipeline):
    """Ingest all seed data directories."""
    total_docs = 0
    total_chunks = 0
    
    for config in SEED_CONFIG:
        dir_path = config["dir"]
        if not os.path.isdir(dir_path):
            print(f"  ⚠ Directory not found: {dir_path}, skipping")
            continue

        print(f"\n📁 Ingesting: {dir_path} (category={config['category']})")
        
        results = pipeline.ingest_directory(
            dir_path=dir_path,
            category=config["category"],
            tags=config["tags"],
            language=config["language"],
            region=config["region"],
            crops=config["crops"],
        )

        for result in results:
            status = result.get("status", "unknown")
            chunks = result.get("chunks_count", 0)
            title = result.get("document_title", result.get("source_file", "?"))
            
            if status == "success":
                print(f"  ✅ {title}: {chunks} chunks")
                total_chunks += chunks
                total_docs += 1
            else:
                print(f"  ❌ {title}: {result.get('error', 'failed')}")

    print(f"\n{'='*50}")
    print(f"Seed complete: {total_docs} documents, {total_chunks} chunks")
    print(f"{'='*50}")


def seed_file(pipeline: DocumentIngestionPipeline, file_path: str, category: str, tags: str):
    """Ingest a single file."""
    tag_list = [t.strip() for t in tags.split(",") if t.strip()] if tags else []
    
    print(f"📄 Ingesting: {file_path} (category={category})")
    result = pipeline.ingest_file(
        file_path=file_path,
        category=category,
        tags=tag_list,
    )
    
    status = result.get("status", "unknown")
    chunks = result.get("chunks_count", 0)
    print(f"  Result: {status}, {chunks} chunks")
    return result


def seed_directory(pipeline: DocumentIngestionPipeline, dir_path: str, category: str, tags: str):
    """Ingest all files from a directory."""
    tag_list = [t.strip() for t in tags.split(",") if t.strip()] if tags else []
    
    print(f"📁 Ingesting directory: {dir_path} (category={category})")
    results = pipeline.ingest_directory(
        dir_path=dir_path,
        category=category,
        tags=tag_list,
    )
    
    for result in results:
        status = result.get("status", "unknown")
        chunks = result.get("chunks_count", 0)
        title = result.get("document_title", result.get("source_file", "?"))
        if status == "success":
            print(f"  ✅ {title}: {chunks} chunks")
        else:
            print(f"  ❌ {title}: {result.get('error', 'failed')}")


def main():
    parser = argparse.ArgumentParser(description="Seed the Krushi Setu Knowledge Base")
    parser.add_argument("--all", action="store_true", help="Ingest all seed data")
    parser.add_argument("--file", type=str, help="Path to a single file to ingest")
    parser.add_argument("--dir", type=str, help="Path to a directory to ingest")
    parser.add_argument("--category", type=str, default="general", help="Document category")
    parser.add_argument("--tags", type=str, default="", help="Comma-separated tags")

    args = parser.parse_args()

    print("🌾 Krushi Setu Knowledge Base Seeder")
    print("=" * 50)
    print("Loading BGE-M3 embedding model (first run downloads ~2GB)...")
    
    start = time.time()
    pipeline = DocumentIngestionPipeline()
    load_time = time.time() - start
    print(f"Model loaded in {load_time:.1f}s")

    if args.all:
        seed_all(pipeline)
    elif args.file:
        seed_file(pipeline, args.file, args.category, args.tags)
    elif args.dir:
        seed_directory(pipeline, args.dir, args.category, args.tags)
    else:
        # Default: seed all
        print("\nNo arguments provided. Ingesting all seed data...\n")
        seed_all(pipeline)


if __name__ == "__main__":
    main()
