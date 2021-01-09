#!/bin/sh

#cd /home/git
cat /git-server/keys/*.pub > /home/git/.ssh/authorized_keys
chown -R git:git /home/git/.ssh
chmod 700 /home/git/.ssh
chmod -R 600 /home/git/.ssh/*

#cd /git-server/repos
chown -R git:git /git-server/repos/
chmod -R ug+rwX /git-server/repos/
find /git-server/repos -type d -exec chmod g+s '{}' +

# -D flag avoids executing sshd as a daemon
/usr/sbin/sshd -D

