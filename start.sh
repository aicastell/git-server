#!/bin/sh
set -eu

GIT_HOME="/home/git"
KEYS_DIR="/git-server/keys"
REPOS_DIR="/git-server/repos"
HOST_KEYS_DIR="/git-server/ssh-host-keys"

# Initialize persistent SSH host keys.
mkdir -p "$HOST_KEYS_DIR" /run/sshd

for type in ed25519 rsa; do
    key="$HOST_KEYS_DIR/ssh_host_${type}_key"

    if [ ! -f "$key" ]; then
        ssh-keygen -q -t "$type" -N '' -f "$key"
    fi

    chmod 600 "$key"
    chmod 644 "${key}.pub"
done

# Prepare Git user SSH configuration.
mkdir -p "$GIT_HOME/.ssh"
chmod 700 "$GIT_HOME/.ssh"

: > "$GIT_HOME/.ssh/authorized_keys"

for key in "$KEYS_DIR"/*.pub; do
    [ -f "$key" ] || continue
    cat "$key" >> "$GIT_HOME/.ssh/authorized_keys"
    printf '\n' >> "$GIT_HOME/.ssh/authorized_keys"
done

chown -R git:git "$GIT_HOME/.ssh"
chmod 600 "$GIT_HOME/.ssh/authorized_keys"

# Configure SSH access.
cat > /etc/ssh/sshd_config <<EOF
Port 22
HostKey $HOST_KEYS_DIR/ssh_host_ed25519_key
HostKey $HOST_KEYS_DIR/ssh_host_rsa_key

PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey
AuthorizedKeysFile .ssh/authorized_keys

AllowUsers git
AllowTcpForwarding no
AllowAgentForwarding no
X11Forwarding no
PermitTunnel no
PermitTTY no
GatewayPorts no
PermitUserEnvironment no
EOF

chmod 700 "$HOST_KEYS_DIR"

# Check configuration before starting SSH.
sshd -t

# Keep SSH running as the container's main process.
exec /usr/sbin/sshd -D -e
