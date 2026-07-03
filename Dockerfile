ARG MP_TAG=latest
FROM jxxghp/moviepilot-v2:${MP_TAG}

ARG PUID=1000
ARG PGID=1001

RUN groupmod -o -g ${PGID} moviepilot \
    && usermod -o -u ${PUID} moviepilot \
    && chown -R ${PUID}:${PGID} /app /public

COPY entrypoint-wrapper.sh /entrypoint-wrapper.sh
RUN chmod +x /entrypoint-wrapper.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/entrypoint-wrapper.sh"]
