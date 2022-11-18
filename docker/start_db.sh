#!/bin/bash
set -e

# Initialize postgres if data missing.
if [ ! -d "$PGDATA" ]; then
    echo "Initializing Postgres..."
    chown -R postgres:postgres /var/lib/postgresql
    gosu postgres initdb &>/dev/null
fi

# Start postgres.
service postgresql start

# Create database if not created.
if ! gosu postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
    [ ! "$DB_NAME" ] && { echo "DB_NAME not set!"; exit 1; }
    echo "Creating database $DB_NAME..."
    ./create_db.sh
fi
