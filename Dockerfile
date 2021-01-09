FROM alpine:latest

MAINTAINER Angel Ivan Castell Rovira <al004140@gmail.com>

RUN apk add --no-cache \
    openssh \
    git
RUN ssh-keygen -A

ENV USERNAME=git
ENV PASSWORD=

RUN mkdir -p /git-server/keys /git-server/repos \
    && adduser -D -s /usr/bin/git-shell ${USERNAME} \
    && echo ${USERNAME}:${PASSWORD} | chpasswd \
    && mkdir -p /home/${USERNAME}/.ssh/

# https://git-scm.com/docs/git-shell
COPY git-shell-commands /home/${USERNAME}/git-shell-commands
COPY start.sh start.sh

EXPOSE 22

CMD ["sh", "start.sh"]

