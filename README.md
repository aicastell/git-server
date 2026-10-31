# git-server

A minimal, self-hosted Git server using **Alpine Linux**, **OpenSSH**, and **Git** in a Docker container.

Git repositories are accessed over SSH using public-key authentication. There is no web interface, database, or interactive shell.

## Requirements

- Docker Engine with the Docker Compose v2 plugin (`docker compose`)
- An SSH key pair on each client
- A free TCP port on the host (default: `2222`)

## Quick start

### 1. Clone the project

```sh
git clone https://github.com/aicastell/git-server.git
cd git-server
```

### 2. Prepare persistent directories

The container runs Git as UID/GID **10001:10001**. Create the directories before starting Docker so that bind-mount ownership is predictable:

```sh
mkdir -p data/keys data/repos data/ssh-host-keys
sudo chown 10001:10001 data/repos
chmod 755 data/keys data/repos
```

Keep `data/ssh-host-keys` writable by the container's root user. It contains the **server's private SSH host keys** and must be protected and backed up.

> If you set `GIT_DATA_DIR`, create these directories under that path instead of `./data`.

### 3. Authorize a client public key

Copy **only the public key** (`.pub`) to the `keys` directory:

```sh
cp /path/to/client-key.pub data/keys/client.pub
```

Never copy a client's private key into the project, Docker image, or container. Public keys are loaded into `authorized_keys` when the container starts; restart the service after adding or removing them.

### 4. Start the server

```sh
docker compose up -d --build
```

By default, SSH is exposed only on the host's loopback address, `127.0.0.1:2222`. To accept connections from other computers, set a reachable bind address, for example:

```sh
GIT_BIND_ADDRESS=0.0.0.0 docker compose up -d
```

Only expose the port on trusted networks, and use host firewall rules as appropriate. To customize the host port, set `GIT_SSH_PORT` (default: `2222`). To store persistent data elsewhere, set `GIT_DATA_DIR` (default: `./data`). Put persistent deployment settings in a local `.env` file if desired; **do not commit `.env`**.

### 5. Verify SSH authentication

From an authorized client, using the appropriate host address:

```sh
ssh -T -p 2222 -i /path/to/client-private-key git@localhost
```

A successful connection prints a welcome message and refuses an interactive shell. The command intentionally exits with a nonzero status; that is expected. If the host is remote, replace `localhost` with its hostname or IP address.

On first connection, verify the server's host-key fingerprint through a trusted channel before accepting it:

```sh
docker compose exec git ssh-keygen -lf /git-server/ssh-host-keys/ssh_host_ed25519_key.pub
```

## Manage repositories

### Create a bare repository

Run this on the Docker host, in the project directory:

```sh
docker compose exec -u git git git init --bare --initial-branch=main /git-server/repos/example.git
```

No container restart is needed. The `git` user must have write access to `data/repos` and its contents.

### Clone a repository

From a client with SSH configured for the correct identity and port:

```sh
git clone ssh://git@HOSTNAME:2222/git-server/repos/example.git
```

Replace `HOSTNAME` with the Docker host's reachable hostname or IP address. Alternatively, configure an SSH host alias in `~/.ssh/config`:

```sshconfig
Host my-git-server
    HostName HOSTNAME
    User git
    Port 2222
    IdentityFile /path/to/client-private-key
    IdentitiesOnly yes
```

Then clone with:

```sh
git clone my-git-server:/git-server/repos/example.git
```

### Push an existing local repository

If you cloned an empty repository and your local branch is named `master`, rename it to `main` before the first push using `git branch -m main`. This is only necessary when the local branch name differs from the intended remote branch.

```sh
cd /path/to/local/repository
git remote add selfhosted ssh://git@HOSTNAME:2222/git-server/repos/example.git
git push -u selfhosted main
```

Replace `main` with your local branch name if different.

## Persistent data

The Compose configuration mounts three host directories:

| Host path (relative to `GIT_DATA_DIR`) | Container path | Purpose |
| --- | --- | --- |
| `repos/` | `/git-server/repos` | Bare Git repositories |
| `keys/` | `/git-server/keys` (read-only) | Authorized client public keys (`*.pub`) |
| `ssh-host-keys/` | `/git-server/ssh-host-keys` | Persistent server SSH identity (private and public host keys) |

The server regenerates `authorized_keys` from `keys/*.pub` on startup. SSH host keys are generated on first start and retained in the persistent directory.

**Back up** the repositories, authorized public keys, and SSH host keys. Keep backup copies of private host keys protected. A backup is not complete until you have tested restoration. For actively updated repositories, use a consistent backup method and verify repository integrity (for example, with `git fsck`).

## Operations

```sh
# View status and logs
docker compose ps
docker compose logs --tail=50 git

# Reload authorized public keys (restart the container)
docker compose restart git

# Stop and remove this project's container/network (preserves bind-mounted data)
docker compose down

# Start or rebuild
docker compose up -d --build
```

The project also provides `runall.sh` (build/start) and `cleanall.sh` (stop/remove the project container and the local `alpine:git-server` image). **Do not use `cleanall.sh` to delete persistent data**; it does not remove bind-mounted directories.

## Security notes

- SSH password and keyboard-interactive authentication are disabled. Only authorized public keys can authenticate.
- The `git` account uses `git-shell` and cannot open an interactive shell.
- SSH host keys persist independently of container rebuilds; protect the private host keys.
- The Git account uses UID/GID `10001:10001`. Ensure repository ownership matches on the host.
- The default SSH bind address is `127.0.0.1`. Remote access requires an explicit bind-address change and appropriate network controls.
- Keep the Alpine base image and installed packages updated, and rebuild when security updates are available.

## License

This project is licensed under the GNU General Public License
version 2.0 only (GPL-2.0-only).

See the [LICENSE](LICENSE) file for the complete license text.
