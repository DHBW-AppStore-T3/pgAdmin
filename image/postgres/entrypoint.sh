#!/bin/sh
# No sudo, no root: runs as the UID the platform sets. PGDATA lives on the storage
# volume (shared with pgAdmin, which keeps its own files next to it).
set -eu

PGDATA="${PGDATA_DIR:-/var/lib/pgadmin/pgdata}"

if [ ! -s "$PGDATA/PG_VERSION" ]; then
  echo "[pg-entrypoint] first start: copying Pagila template cluster to $PGDATA"
  mkdir -p "$PGDATA"
  cp -a /opt/pagila-pgdata/. "$PGDATA"/
fi
chmod 700 "$PGDATA"

# Only the pgAdmin container of the same pod needs to reach it (shared network
# namespace), so listen on loopback; the socket directory must be writable.
exec postgres -D "$PGDATA" \
  -c listen_addresses=localhost \
  -c unix_socket_directories=/tmp
