ARG MP_TAG=latest
FROM jxxghp/moviepilot-v2:${MP_TAG}

RUN chown -R moviepilot:moviepilot /app/app/plugins
