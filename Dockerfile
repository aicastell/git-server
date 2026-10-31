FROM alpine:3.22

LABEL org.opencontainers.image.authors="Angel Ivan Castell Rovira"

RUN apk add --no-cache openssh git

ENV USERNAME=git

RUN addgroup -g 10001 git \
    && adduser -D -u 10001 -G git -h /home/git -s /usr/bin/git-shell "${USERNAME}" \
    && mkdir -p /git-server/keys /git-server/repos \
                /home/git/.ssh /home/git/git-shell-commands \
                /run/sshd \
    && chown -R git:git /home/git \
    && chmod 700 /home/git/.ssh

# Unlock the account with an unusable password hash.
# SSH password authentication remains disabled.
RUN sed -i 's/^git:[^:]*:/git:*NP*:/' /etc/shadow

COPY git-shell-commands/ /home/git/git-shell-commands/

RUN chmod 755 /home/git/git-shell-commands/no-interactive-login

COPY start.sh /start.sh

EXPOSE 22

CMD ["/bin/sh", "/start.sh"]
