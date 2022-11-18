#!/bin/bash
set -e

echo
echo "--------------------------------------------------"
echo "                    boltcard                      "
echo "--------------------------------------------------"

# Load config.
echo "Loading config..."
source ./validate_config_files.sh
source ./config.sh

# Start database.
echo "Starting database..."
./start_db.sh

echo "Done!"

exec gosu $USER "$@"
