ARG MP_TAG=latest
FROM jxxghp/moviepilot-v2:${MP_TAG}

ARG PUID=1000
ARG PGID=1001

RUN groupmod -o -g ${PGID} moviepilot \
    && usermod -o -u ${PUID} moviepilot \
    && chown -R ${PUID}:${PGID} /app /public

COPY entrypoint-wrapper.sh /entrypoint-wrapper.sh
RUN chmod +x /entrypoint-wrapper.sh

COPY sitecustomize.py /tmp/moviepilot-derived-sitecustomize.py
RUN "${VENV_PATH:-/opt/venv}/bin/python3" - <<'PY'
from pathlib import Path
import shutil
import sysconfig

target = Path(sysconfig.get_paths()["purelib"]) / "sitecustomize.py"
source = Path("/tmp/moviepilot-derived-sitecustomize.py")
shutil.copyfile(source, target)
PY
RUN rm -f /tmp/moviepilot-derived-sitecustomize.py

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/entrypoint-wrapper.sh"]
