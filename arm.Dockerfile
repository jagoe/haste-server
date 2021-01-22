FROM hypriot/rpi-alpine as rpi

FROM node:14.8-stretch as builder

RUN mkdir -p /app && chown node:node /app

USER node:node

WORKDIR /app

COPY --chown=node:node . .

RUN npm install && \
    npm install redis@0.8.1 \
    pg@4.1.1 memcached@2.2.2 \
    aws-sdk@2.738.0 \
    rethinkdbdash@2.3.31

FROM arm32v7/node:14.8-alpine

COPY --from=rpi ["/usr/bin/qemu-arm-static", "/usr/bin/qemu-arm-static"]

RUN mkdir -p /app && chown node:node /app
USER node:node

WORKDIR /app

ENV STORAGE_TYPE=memcached \
    STORAGE_HOST=127.0.0.1 \
    STORAGE_PORT=11211\
    STORAGE_EXPIRE_SECONDS=2592000\
    STORAGE_DB=2 \
    STORAGE_AWS_BUCKET= \
    STORAGE_AWS_REGION= \
    STORAGE_USENAMER= \
    STORAGE_PASSWORD= \
    STORAGE_FILEPATH=

ENV LOGGING_LEVEL=verbose \
    LOGGING_TYPE=Console \
    LOGGING_COLORIZE=true

ENV HOST=0.0.0.0\
    PORT=7777\
    KEY_LENGTH=10\
    MAX_LENGTH=400000\
    STATIC_MAX_AGE=86400\
    RECOMPRESS_STATIC_ASSETS=true

ENV KEYGENERATOR_TYPE=phonetic \
    KEYGENERATOR_KEYSPACE=

ENV RATELIMITS_NORMAL_TOTAL_REQUESTS=500\
    RATELIMITS_NORMAL_EVERY_MILLISECONDS=60000 \
    RATELIMITS_WHITELIST_TOTAL_REQUESTS= \
    RATELIMITS_WHITELIST_EVERY_MILLISECONDS=  \
    # comma separated list for the whitelisted \
    RATELIMITS_WHITELIST=example1.whitelist,example2.whitelist \
    \
    RATELIMITS_BLACKLIST_TOTAL_REQUESTS= \
    RATELIMITS_BLACKLIST_EVERY_MILLISECONDS= \
    # comma separated list for the blacklisted \
    RATELIMITS_BLACKLIST=example1.blacklist,example2.blacklist
ENV DOCUMENTS=about=./about.md

EXPOSE ${PORT}
STOPSIGNAL SIGINT
ENTRYPOINT [ "sh", "docker-entrypoint.sh" ]

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s \
    --retries=3 CMD [ "curl" , "-f" "localhost:${PORT}", "||", "exit", "1"]

COPY --chown=node:node --from=builder ["/app/docker-entrypoint.sh", "/app/docker-entrypoint.js", "./"]
COPY --chown=node:node --from=builder ["/app/about.md", "/app/Procfile", "./"]
COPY --chown=node:node --from=builder ["/app/static", "./static"]
COPY --chown=node:node --from=builder ["/app/server.js", "./"]
COPY --chown=node:node --from=builder ["/app/lib", "./lib"]
COPY --chown=node:node --from=builder ["/app/package.json", "./"]
COPY --chown=node:node --from=builder ["/app/node_modules", "./node_modules"]

CMD ["npm", "start"]
