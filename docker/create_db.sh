#!/bin/bash
set -e

# Initiate new database.
gosu postgres createuser -s $USER
cp ./create_db.sql /tmp/
[ -v DB_PASSWORD ] && sed -i -E "s/database_password/$DB_PASSWORD/g" /tmp/create_db.sql
gosu $USER psql postgres -f /tmp/create_db.sql &>/dev/null
rm -f /tmp/create_db.sql
