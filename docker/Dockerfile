FROM ubuntu:focal

RUN apt-get update && apt-get full-upgrade -y && apt-get install sudo -y

COPY ./entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && adduser --home /home/fsjob \
    --gecos "FsJob User" --shell /bin/bash --disabled-password --disabled-login \
    --uid 1000 fsjob && \
    mkdir /etc/fsjob && \
    echo "%fsjob         ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers && chown -R fsjob:fsjob /home/fsjob

VOLUME [ "/etc/fsjob" ]

USER fsjob
WORKDIR /home/fsjob

ENTRYPOINT ["/entrypoint.sh"]