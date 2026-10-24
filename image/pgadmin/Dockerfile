# pgAdmin 4 for the pod runtime (appstore.yaml). Runs next to the postgres
# container of the same pod. The platform sets user (UID 1000), a read-only root
# filesystem and the env (PGADMIN_DEFAULT_EMAIL / PGADMIN_DEFAULT_PASSWORD).
FROM docker.io/dpage/pgadmin4:9.18.0

# Security fixes that upstream 9.18.0 does not have yet: Alpine packages (brotli-libs, sudo) and Python packages in
# the bundled /venv (Pillow, urllib3, certifi, brotli, msgpack, setuptools; Trivy reported 39 fixable HIGH/CRITICAL
# findings). Needs root for the build only; the image goes back to upstream's user 5050 below, and everything else
# (entrypoint, ports, read-only root) stays as upstream built it.
USER root
RUN apk upgrade --no-cache  && /venv/bin/python -m pip install --no-cache-dir --upgrade pillow urllib3 certifi brotli msgpack setuptools
USER 5050

# Non-empty config_distro.py: the upstream entrypoint only writes this file when
# it is empty, and it could not (read-only root filesystem). Data directory stays
# the default /var/lib/pgadmin, which the platform mounts as the storage volume.
COPY config_distro.py /pgadmin4/config_distro.py
# Registers the Pagila database for the first user (entrypoint: load-servers).
COPY servers.json /pgadmin4/servers.json

# No USER, no ENTRYPOINT override: the upstream entrypoint is written for
# restricted security contexts (no root, no capabilities). The environment sets
# the port (>= 1024) and disables postfix (it needs sudo).
