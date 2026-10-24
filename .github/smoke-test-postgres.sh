#!/usr/bin/env bash
# Smoke test: PostgreSQL starts and the Pagila sample database is there in the platform's security context. Run by the central pipeline
# (DHBW-AppStore-T3/app-registry) against the locally built image, before the Trivy scan and before any push.
# IMAGE and PLATFORM_RUN_FLAGS (--user 1000:1000 --read-only --cap-drop ALL --security-opt no-new-privileges
# --network host) come from the pipeline; the pipeline removes the container afterwards.
set -euo pipefail

# shellcheck disable=SC2086  # PLATFORM_RUN_FLAGS is meant to split into words
docker run -d --name pg $PLATFORM_RUN_FLAGS \
  --tmpfs /tmp --tmpfs /var/lib/pgadmin:uid=1000,gid=1000 \
  "$IMAGE"

ok=0
for _ in $(seq 1 30); do
  if docker exec -e PGPASSWORD=pagila pg psql -h localhost -U pagila_user -d pagila -tAc 'select count(*) from film'; then
    ok=1; break
  fi
  sleep 2
done
docker logs pg
[ "$ok" = 1 ]
