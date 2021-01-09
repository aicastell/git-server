#!/bin/sh

if [ -d /git-server/keys/ ]; then
    cat /git-server/keys/*.pub > /home/${USERNAME}/.ssh/authorized_keys
fi

if [ -d /home/${USERNAME}/.ssh ]; then
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh
    chmod 700 /home/${USERNAME}/.ssh
    chmod -R 600 /home/${USERNAME}/.ssh/*
fi

if [ -d /git-server/repos/ ]; then
    chown -R ${USERNAME}:${USERNAME} /git-server/repos/
    chmod -R ug+rwX /git-server/repos/
    find /git-server/repos -type d -exec chmod g+s '{}' +
fi

# -D flag avoids executing sshd as a daemon
/usr/sbin/sshd -D

