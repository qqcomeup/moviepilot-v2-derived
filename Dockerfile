ARG MP_TAG=latest
FROM jxxghp/moviepilot-v2:${MP_TAG}

ARG PUID=1000
ARG PGID=1001

RUN chown -R ${PUID}:${PGID} /app /public
