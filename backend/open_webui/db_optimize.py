"""
Database optimization script for MG-Firma Legal
Run this periodically to maintain SQLite performance
"""
import sqlite3
import os
from pathlib import Path

def optimize_database(db_path: str = "/app/backend/data/webui.db"):
    """Optimize SQLite database for better performance"""
    if not os.path.exists(db_path):
        print(f"Database not found: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Set optimal pragmas for read-heavy workloads
        cursor.execute("PRAGMA journal_mode=DELETE")
        cursor.execute("PRAGMA synchronous=NORMAL")
        cursor.execute("PRAGMA cache_size=-64000")  # 64MB cache
        cursor.execute("PRAGMA temp_store=MEMORY")
        cursor.execute("PRAGMA mmap_size=268435456")  # 256MB mmap
        cursor.execute("PRAGMA foreign_keys=ON")
        
        # Checkpoint and truncate WAL if exists
        cursor.execute("PRAGMA wal_checkpoint(TRUNCATE)")
        
        # Vacuum to reclaim space
        cursor.execute("VACUUM")
        
        # Analyze tables for query optimization
        cursor.execute("ANALYZE")
        
        conn.commit()
        
        # Get stats
        cursor.execute("SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()")
        db_size = cursor.fetchone()[0]
        
        print(f"Database optimized: {db_path}")
        print(f"Size: {db_size / 1024 / 1024:.2f} MB")
        
        return True
    except Exception as e:
        print(f"Error optimizing database: {e}")
        return False
    finally:
        conn.close()

if __name__ == "__main__":
    optimize_database()
