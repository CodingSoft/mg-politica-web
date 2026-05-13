#!/bin/bash
# Optimized startup script for MG-Firma Legal
# This script optimizes the database before starting the application

set -e

DB_PATH="/app/backend/data/webui.db"

echo "Starting MG-Firma Legal with optimizations..."

# Optimize database on startup if it exists
if [ -f "$DB_PATH" ]; then
    echo "Optimizing database..."
    python3 -c "
import sqlite3
conn = sqlite3.connect('$DB_PATH')
conn.execute('PRAGMA journal_mode=DELETE')
conn.execute('PRAGMA synchronous=NORMAL')
conn.execute('PRAGMA cache_size=-64000')
conn.execute('PRAGMA temp_store=MEMORY')
conn.execute('PRAGMA wal_checkpoint(TRUNCATE)')
conn.close()
print('Database optimized')
" || echo "Warning: Database optimization failed, continuing anyway..."
fi

# Start the application
exec bash start.sh
