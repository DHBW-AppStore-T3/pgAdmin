# PostgreSQL with the Pagila sample database for the pod runtime (appstore.yaml).
# Second container of the pgAdmin pod. The platform runs it as UID 1000 on a
# read-only root filesystem, with the storage volume mounted at /var/lib/pgadmin.
# Pagila is pinned below to a commit that needs neither uuidv7() (PostgreSQL 18) nor pgvector.
FROM docker.io/library/postgres:17.11-bookworm

# Security fixes the base image does not have yet (weekly Trivy scan, 2026-10-26):
# openssl/libssl3 CVE-2026-84782, fixed in 3.0.22-1~deb12u2. --only-upgrade takes the
# newest fix from bookworm-security; the version check fails the build instead of
# shipping without it. Edit this line for the next fix: an unchanged line lets the
# build cache reuse the old layer, and the upgrade would not run again.
# hadolint ignore=DL3008
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --only-upgrade openssl libssl3 \
 && dpkg --compare-versions "$(dpkg-query -W -f='${Version}' libssl3)" ge 3.0.22-1~deb12u2 \
 && rm -rf /var/lib/apt/lists/*

# initdb/postgres refuse to run for a UID without a passwd entry, and the
# platform forces UID 1000. Directory for the template cluster is built below.
# gosu is removed: it only serves the upstream entrypoint, which pg-entrypoint.sh replaces (no privilege drop here,
# the platform sets the UID), and its Go standard library caused all 26 findings of the Trivy scan of this image.
RUN groupadd -g 1000 pg \
 && useradd -u 1000 -g 1000 -d /tmp -s /bin/sh -M pg \
 && mkdir /opt/pagila-pgdata \
 && chown 1000:1000 /opt/pagila-pgdata \
 && mkdir -m 755 /opt/pagila  && rm -f /usr/local/bin/gosu

# Pagila sample data, pinned to a commit and verified by checksum.
ADD --checksum=sha256:18de72ae8669a0099b47be6d54b60ca5334114f38db65bf21ae82b0fc752d1ad --chmod=0644 \
  https://raw.githubusercontent.com/devrimgunduz/pagila/23f7fe7a1e9f5772f85fc14f530583ffa258c6d2/pagila-schema.sql /opt/pagila/pagila-schema.sql
ADD --checksum=sha256:2ca58493e45c01e0978ddf9a9e4796ef3acd3290ac0093b91a6d4e7b6b80d625 --chmod=0644 \
  https://raw.githubusercontent.com/devrimgunduz/pagila/23f7fe7a1e9f5772f85fc14f530583ffa258c6d2/pagila-data.sql /opt/pagila/pagila-data.sql

# Build the template cluster once, at image build time (not at pod start). The
# entrypoint copies it to the storage volume on first start.
USER 1000:1000
RUN set -eux; \
    T=/opt/pagila-pgdata; \
    initdb -D "$T" -U postgres -E UTF8 --locale=C.UTF-8 --auth-local=trust --auth-host=scram-sha-256; \
    pg_ctl -D "$T" -w -o "-c listen_addresses='' -c unix_socket_directories=/tmp" start; \
    psql -h /tmp -U postgres -v ON_ERROR_STOP=1 \
      -c "CREATE DATABASE pagila;" \
      -c "CREATE USER pagila_user WITH PASSWORD 'pagila';" \
      -c "GRANT ALL PRIVILEGES ON DATABASE pagila TO pagila_user;"; \
    psql -h /tmp -U postgres -d pagila -v ON_ERROR_STOP=1 \
      -f /opt/pagila/pagila-schema.sql \
      -f /opt/pagila/pagila-data.sql \
      -c "GRANT USAGE ON SCHEMA public TO pagila_user;" \
      -c "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO pagila_user;" \
      -c "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO pagila_user;"; \
    pg_ctl -D "$T" -m fast -w stop

COPY --chmod=0755 entrypoint.sh /usr/local/bin/pg-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/pg-entrypoint.sh"]
