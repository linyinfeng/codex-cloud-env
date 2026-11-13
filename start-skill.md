---
name: codex-cloud-env
description: Work on linyinfeng's repositories as the littlenano GitHub bot.
---

## Purpose and Git

This is a general development environment for linyinfeng's repositories, using
the littlenano bot's existing platform-provided GitHub authentication. The only
default checkout is `/workspace/codex-cloud-env`. Clone task-specific repositories
under `/workspace` when requested, using the existing HTTPS Git/GitHub tooling.
Check `gh auth status` before authenticated work; the expected account is
`littlenano`. Do not replace bot credentials with personal credentials.

Each Cloud task is already isolated. Use existing checkouts and do not create
Git worktrees unless explicitly requested. Use host tools for Git operations.
Git author and committer identity is `Nano <nano@linyinfeng.com>`; `install.sh`
sets this globally. Inspect repository-local identity overrides before committing.

Unless the user says otherwise, ordinary NEW commits must explicitly use:

```bash
git commit --trailer 'Co-authored-by: Lin Yinfeng <lin.yinfeng@outlook.com>' -m '...'
```

There is no automatic commit hook. Preserve existing messages during amend,
rebase, cherry-pick, revert, merge, squash, or reuse with `-c`/`-C`; do not add
trailers to those operations by default. The user can opt out per task/commit.
Also respect `git config --local codex.coauthor false` for one repository or
`git config --global codex.coauthor false` for this environment user: check
`git config --bool --get codex.coauthor` before adding a trailer. An unset value
means enabled. Re-enable with true or by unsetting the relevant override.

## Prepare the custom Nix image

The outer environment runs Codex, Git, and GitHub tooling. Nix runs in the
Dockerfile's custom image, based on `nixos/nix:latest`. Shared Nix settings live
in `nix.conf`, which is appended to `/etc/nix/nix.conf` at build time. Customize
these files for shared tools; do not put credentials in the repository or image.

```bash
unset DOCKER_HOST DOCKER_CONTEXT DOCKER_TLS DOCKER_TLS_VERIFY DOCKER_CERT_PATH
export DOCKER_HOST=unix:///var/run/docker.sock
docker info >/dev/null
```

If `docker image inspect codex-cloud-env:local` fails, run
`bash /workspace/codex-cloud-env/install.sh`. Run it again after image changes.
Preserve Docker's registry credentials and proxy defaults. A non-root outer
user cannot start/restart the managed daemon; diagnose failures before proceeding.

## Start the task container

At the beginning of each new/restored task, recreate only this setup's container
to refresh its proxy defaults, CA mount, and bot token. Container state is
disposable; workspace files and the built image are filesystem state. No process
is assumed to survive restoration. Keep TLS and Nix signature verification on.

```bash
if docker container inspect codex-cloud-env >/dev/null 2>&1; then
    owner="$(docker inspect --format '{{index .Config.Labels "codex.environment"}}' codex-cloud-env)"
    if [ "$owner" != codex-cloud-env ]; then
        echo 'Container name is in use by another setup' >&2
        return 1 2>/dev/null || exit 1
    fi
    docker rm -f codex-cloud-env
fi
docker run -d --name codex-cloud-env \
    --label codex.environment=codex-cloud-env \
    --mount type=bind,src=/workspace,dst=/workspace \
    --mount type=bind,src=/etc/ssl/certs/ca-certificates.crt,dst=/run/cloud-ca.pem,readonly \
    --env NIX_SSL_CERT_FILE=/run/cloud-ca.pem \
    --env SSL_CERT_FILE=/run/cloud-ca.pem \
    --env CURL_CA_BUNDLE=/run/cloud-ca.pem \
    --env GH_TOKEN \
    --workdir /workspace \
    codex-cloud-env:local sleep infinity
docker exec codex-cloud-env nix --version
docker exec codex-cloud-env curl -fsS --max-time 30 https://cache.nixos.org/nix-cache-info
```

The entrypoint writes Nix's `access-tokens = github.com=...` from the existing
`GH_TOKEN` to a private runtime file included by `nix.conf`. If the variable is
absent, public Nix operations still work; private GitHub access is unconfigured.
Never print token files or the full Nix configuration. Do not bake runtime token
files into an image or commit them. Container configuration contains the injected
token; recreate the container for each task rather than retaining old credentials.

## Run tools

Define this in the shell running commands; functions do not persist between
independent shell calls:

```bash
nixrun() {
    docker --host=unix:///var/run/docker.sock exec --workdir "$PWD" \
        codex-cloud-env "$@"
}
# From a project directory under /workspace:
# nixrun nix develop --command <command> <args...>
# Use path:. flake references if container/host Git ownership differs.
```

Keep the working directory under `/workspace`. Docker supplies container proxy
defaults; do not replace them with outer-shell proxy addresses. Use the mounted
CA bundle for HTTPS. The default inner user is root, so new workspace files may
be root-owned. Avoid editing outer Git metadata inside the container.

Nix downloads and interactive package installations remain in this container
until it is recreated. Put shared dependencies in the Dockerfile for repeatable
setup. Docker's `vfs` driver can make container creation slow; reuse the task
container for commands. No project build is required for this generic environment.
