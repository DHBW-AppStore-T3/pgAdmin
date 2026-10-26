# pgAdmin 4 for the pod runtime (appstore.yaml). Runs next to the postgres
# container of the same pod. The platform sets user (UID 1000), a read-only root
# filesystem and the env (PGADMIN_DEFAULT_EMAIL / PGADMIN_DEFAULT_PASSWORD).
FROM docker.io/dpage/pgadmin4:9.18.0

# Security fixes that upstream 9.18.0 does not have yet: Alpine packages (brotli-libs, sudo; libcurl CVE-2026-92392,
# fixed in 8.23.0-r0: the minimum version fails the build instead of shipping without it, and editing this RUN line
# for the next fix makes the build cache run it again) and Python packages in
# the bundled /venv (Pillow, urllib3, certifi, brotli, msgpack, setuptools; Trivy reported 39 fixable HIGH/CRITICAL
# findings). Then pip is removed: it is not needed at runtime (read-only root), and it carries its own old vendored
# copies of urllib3, certifi and msgpack that cannot be upgraded separately. Needs root for the build only; the image
# goes back to upstream's user 5050 below, and everything else (entrypoint, ports, read-only root) stays as upstream
# built it.
USER root
RUN apk upgrade --no-cache  && apk add --no-cache "libcurl>=8.23.0-r0"  && /venv/bin/python -m pip install --no-cache-dir --upgrade pillow urllib3 certifi brotli msgpack setuptools  && /venv/bin/python -m pip uninstall -y pip  && rm -rf /usr/local/lib/python3*/site-packages/pip* /usr/local/bin/pip*
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
