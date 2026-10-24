#!/usr/bin/env bash
# Smoke test: the pgAdmin login page answers in the platform's security context. Run by the central pipeline
# (DHBW-AppStore-T3/app-registry) against the locally built image, before the Trivy scan and before any push.
# IMAGE and PLATFORM_RUN_FLAGS (--user 1000:1000 --read-only --cap-drop ALL --security-opt no-new-privileges
# --network host) come from the pipeline; the pipeline removes the container afterwards.
set -euo pipefail

# shellcheck disable=SC2086  # PLATFORM_RUN_FLAGS is meant to split into words
docker run -d --name pga $PLATFORM_RUN_FLAGS \
  --tmpfs /tmp --tmpfs /var/lib/pgadmin:uid=1000,gid=1000 \
  -e HOME=/tmp -e PGADMIN_LISTEN_PORT=8080 -e PGADMIN_DISABLE_POSTFIX=1 \
  -e PGADMIN_DEFAULT_EMAIL=pgadmin@dhbw.de -e PGADMIN_DEFAULT_PASSWORD=ci-smoke-test \
  "$IMAGE"

ok=0
for _ in $(seq 1 40); do
  if curl -fsS -o /dev/null "http://[::1]:8080/login"; then ok=1; break; fi
  sleep 3
done
docker logs pga
[ "$ok" = 1 ]
