---
name: codex-cloud-env
description: Use the repository's custom Nix Docker image in Codex Cloud.
---

Each Cloud task already has an isolated environment. Use existing checkouts;
do not create a Git worktree unless the user explicitly requests one.

For all repositories in this environment, use Git identity
`Nano <nano@linyinfeng.com>`. Unless the user explicitly opts out, all new commits
must include `Co-authored-by: Lin Yinfeng <lin.yinfeng@outlook.com>`.
Do not add trailers while rebasing existing commits.

`install.sh` installs the tracked hook to `$HOME/.config/codex/git-hooks` and sets
global `core.hooksPath` and identity, so future environments get the same behavior
when they run the script. If those global settings or the installed hook are
missing, rerun `install.sh`. Do not overwrite another global hook setup; integrate
with it first. A repository-local `core.hooksPath` takes precedence: inspect it
before committing and preserve its existing hooks while honoring this convention.

Respect these opt-outs; do not re-enable the hook automatically:

```bash
# One commit:
git -c codex.coauthor=false commit ...
# One repository:
git config --local codex.coauthor false
# All repositories for this environment user:
git config --global codex.coauthor false
# Re-enable at the same scope by setting true, or unset that scope's override.
```

The outer environment runs Codex and GitHub tooling. Nix commands run in the
custom image built from this repository's Dockerfile. This uses the base image's
Nix setup; it does not install a multi-user Nix daemon on the outer environment.

## Prepare

Use the managed Docker daemon. Preserve Docker's configured registry credentials
and proxy defaults. If Docker is unavailable, diagnose the managed daemon;
the non-root outer user cannot start or restart it.

```bash
unset DOCKER_HOST DOCKER_CONTEXT DOCKER_TLS DOCKER_TLS_VERIFY DOCKER_CERT_PATH
export DOCKER_HOST=unix:///var/run/docker.sock
docker info >/dev/null
```

If `docker image inspect codex-cloud-env:local` fails, run `bash install.sh`
from this repository. Run it again after changing the Dockerfile.

## Run commands

Define this helper in the shell executing the task (shell functions do not
persist between independent shell calls):

```bash
nixrun() {
    docker --host=unix:///var/run/docker.sock run --rm \
        --mount type=bind,src=/workspace,dst=/workspace \
        --mount type=bind,src=/etc/ssl/certs/ca-certificates.crt,dst=/run/cloud-ca.pem,readonly \
        --env NIX_SSL_CERT_FILE=/run/cloud-ca.pem \
        --env SSL_CERT_FILE=/run/cloud-ca.pem \
        --env CURL_CA_BUNDLE=/run/cloud-ca.pem \
        --workdir "$PWD" \
        codex-cloud-env:local "$@"
}
nixrun nix --version
# From a project under /workspace:
# nixrun nix develop --command <command> <args...>
```

Keep the current directory under `/workspace`. Docker supplies the configured
container proxy settings; do not override them with outer-shell proxy values.
The read-only CA bundle preserves HTTPS verification inside the container.
Use outer-environment Git/GitHub tooling for authenticated repository operations.

Containers are disposable: workspace edits persist through the bind mount, but
interactive package installations do not. Put shared tools and configuration in
the Dockerfile. The default container user is root; files it creates in the
workspace can be root-owned. Avoid modifying outer-owned Git metadata inside it.
Image availability across future tasks is not guaranteed; rebuild when missing.
