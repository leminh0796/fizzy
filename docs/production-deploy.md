## Production deploy

Deploy the fetched `origin/main` commit with:

```sh
bin/deploy
```

The command leaves the current branch and working tree alone. It does not stash, merge, commit, or push. `bin/kamal deploy` is not the production command for this host.

### What the command does

1. Take a local lock (`.kamal/deploy.lock`) so a second `bin/deploy` stops before it touches the server.
2. Load `.kamal/production.env` and refuse to continue when a required secret is missing or empty.
3. `git fetch origin main` and resolve that commit.
4. Check Kamal 2.x, Docker buildx `linux/amd64`, SSH, and the Kamal deploy lock.
5. Build and pull that commit while the current container is still serving.
6. Back up the SQLite databases on the `fizzy_storage` volume. If the backup fails, the running container stays up.
7. Under Kamal's boot lock, stop the old container and boot the new commit.
8. Confirm the running image and `KAMAL_VERSION`, that the container did not restart, that startup logs show Puma plus Solid Queue's supervisor, worker, and scheduler, and that both `/up` and the login page return HTTP 200 over valid TLS. Kamal treating the container as running is not enough.
9. If boot or those checks fail after the old container was stopped, restore the SQLite backup and boot the recorded previous release.

There is brief downtime from the moment the old container stops until the new process passes those checks. This is not a zero-downtime deploy. Nginx and the public port stay as they are: Nginx proxies to `127.0.0.1:3006`, and the container publishes `127.0.0.1:3006:80`.

### Secrets

Kamal reads `.kamal/secrets`, which maps:

- `SECRET_KEY_BASE` from `RAILS_MASTER_KEY`
- `VAPID_PUBLIC_KEY` from `VAPID_PUBLIC_KEY`
- `VAPID_PRIVATE_KEY` from `VAPID_PRIVATE_KEY`
- `SMTP_USERNAME` from `AWS_SES_SMTP_USERNAME`
- `SMTP_PASSWORD` from `AWS_SES_SMTP_PASSWORD`

`bin/deploy` exports those variables from `.kamal/production.env` for that process. The file must be owned by the deploying user and must not be readable by group or other (`chmod 600`). It is gitignored. Values are taken literally; the file is not executed as a shell script.

Create it from the running production container when it does not exist yet:

```sh
bin/deploy --import-secrets
```

That reads `SECRET_KEY_BASE`, the VAPID keys, and the SMTP credentials from the running web container and stores `SECRET_KEY_BASE` as `RAILS_MASTER_KEY` so the existing mapping is unchanged. It does not print the values, and it does not replace a file that is already present. The local registry password is not stored in the app container and is not required by `config/deploy.yml`.

Check the setup without building or stopping anything:

```sh
bin/deploy --preflight
```

### Prerequisites

- Bash 4 or newer. macOS system bash is too old; `bin/deploy` re-execs Homebrew bash at `/opt/homebrew/bin/bash` when that exists (`brew install bash`).
- This checkout, with `bin/kamal` on Kamal 2.x. The cutover was checked against Kamal 2.12.0. Ruby comes from `.ruby-version`; `bin/deploy` activates mise when it is installed.
- Docker Desktop, with the daemon running and buildx able to build `linux/amd64`. The app image is built for amd64 even from Apple Silicon.
- SSH to the host and user in `config/deploy.yml`, non-interactive (`BatchMode`).
- The secrets file above, or a running container that `--import-secrets` can read.
- Network access to `origin` and to `https://fizzy.minhcode.net`.

### Database

The image entrypoint runs `db:prepare` before the server starts, including the queue database. `bin/deploy` copies the SQLite files with `sqlite3 .backup` into `/rails/storage/deploy-backups/<timestamp>/` on `fizzy_storage` before stopping the old container. On a failed boot it restores those files, including removing leftover `-wal` and `-shm` files, and only then boots the previous release. It does not delete the volume or other Active Storage files.

### Recovery

Successful and failed deploys append the previous version, target commit, and backup stamp to `.kamal/release-history` (gitignored).

Automatic recovery stops the new container, copies the SQLite backup back onto `fizzy_storage`, and then boots the previous release. The entrypoint migrates on boot, so the previous release starts only after that restore. The volume is left in place.

If automatic recovery fails, the new container is left stopped. Restore the database before booting anything. The backup directory is `/rails/storage/deploy-backups/<timestamp>` on `fizzy_storage`. The previous version is the `previous=` field in `.kamal/release-history`.

Copy each backed-up `*.sqlite3` back over `/rails/storage`, and remove the matching `-wal` and `-shm` files first. Use a one-off container that mounts `fizzy_storage` and does not publish a port. Leave every other file on the volume alone.

Then boot that previous version. `.kamal/hooks/pre-app-boot` stops the container bound to `127.0.0.1:3006` during `app boot`, and it reads the host from the environment:

```sh
export FIZZY_DEPLOY_HOST=154.26.128.168
export FIZZY_DEPLOY_USER=tlminh
export FIZZY_SERVICE=fizzy
bin/kamal app boot --version PREVIOUS_VERSION
```

Export those three variables first. The hook uses them to choose the container. If they are missing, the hook exits and Kamal stops before it can bind the port.

If a Kamal lock remains after a crashed command:

```sh
bin/kamal lock release
```

`.kamal/deploy.lock` is the local overlap lock. The command removes it on exit. A leftover directory is cleared on the next run when the recorded process id is no longer running.

### Why this is not `bin/kamal deploy`

Kamal 2.12 boots the new container before it stops the old one. With `proxy: false` and a fixed published port, Docker rejects the new container because `127.0.0.1:3006` is already allocated. `bin/kamal deploy` also starts kamal-proxy, which this host does not use. `.kamal/hooks/pre-app-boot` stops the current web container with `docker stop` while `kamal app boot` holds the deploy lock. It does not delete containers with `docker rm`, remove volumes, or change published ports.
