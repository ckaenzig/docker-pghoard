#!/bin/bash

set -e

echo "Fix permissions"
mkdir -p /home/postgres/restore
chown -R postgres /home/postgres

echo "Create physical_replication_slot on master ..."
export PGPASSWORD=$PG_PASSWORD
until psql -qAt -U replicator -h $PG_HOST -d postgres -c "select user;"; do 
  echo "sleep 1s and try again ..."
  sleep 1
done
psql -h $PG_HOST -c "WITH foo AS (SELECT COUNT(*) AS count FROM pg_replication_slots WHERE slot_name='pghoard') SELECT pg_create_physical_replication_slot('pghoard') FROM foo WHERE count=0;" -U replicator -d postgres

echo "Create pghoard configuration with confd ..."
if getent hosts rancher-metadata; then
  confd -onetime -backend rancher -prefix /2015-12-19
else
  confd -onetime -backend env
fi

echo "Dump configuration..."
cat /home/postgres/pghoard.json

echo "Run the pghoard daemon ..."
exec gosu postgres pghoard --short-log --config /home/postgres/pghoard.json
