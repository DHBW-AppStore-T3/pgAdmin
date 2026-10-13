# PostgreSQL with the Pagila sample database for the pod runtime (appstore.yaml).
# Second container of the pgAdmin pod. The platform runs it as UID 1000 on a
# read-only root filesystem, with the storage volume mounted at /var/lib/pgadmin.
FROM docker.io/library/postgres:17.11-bookworm

# initdb/postgres refuse to run for a UID without a passwd entry, and the
# platform forces UID 1000. Directory for the template cluster is built below.
RUN groupadd -g 1000 pg \
 && useradd -u 1000 -g 1000 -d /tmp -s /bin/sh -M pg \
 && mkdir /opt/pagila-pgdata \
 && chown 1000:1000 /opt/pagila-pgdata \
 && mkdir -m 755 /opt/pagila

# Pagila sample data, pinned to a commit and verified by checksum.
ADD --checksum=sha256:071ee940a73c8f4fad2997185788065291607e2c55559e3747959e8275391536 --chmod=0644 \
  https://raw.githubusercontent.com/devrimgunduz/pagila/ce6e114236bb828e5ec0dc835f65f1bf1b9179f5/pagila-schema.sql /opt/pagila/pagila-schema.sql
ADD --checksum=sha256:a88efa94c7ae8bc9cf55def4efc9f164d064d5b9cd93f11719ba3b5ace1602f7 --chmod=0644 \
  https://raw.githubusercontent.com/devrimgunduz/pagila/ce6e114236bb828e5ec0dc835f65f1bf1b9179f5/pagila-data.sql /opt/pagila/pagila-data.sql

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
