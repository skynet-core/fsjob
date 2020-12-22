ARG APLPINE_VERSION=3.12.1
FROM alpine:${APLPINE_VERSION}

RUN apk update && apk upgrade && apk add --no-cache inotify-tools

COPY ./entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && addgroup -g 1000 fsjob && adduser -h /home/fsjob -g "FsJob User" \
    -s /bin/bash -D -u 1000 -G fsjob fsjob && \
    mkdir /etc/fsjob && \
    echo "%fsjob         ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers && chown -R fsjob:fsjob /home/fsjob

VOLUME [ "/etc/fsjob" ]

USER fsjob
WORKDIR /home/fsjob

ENTRYPOINT ["/entrypoint.sh"]