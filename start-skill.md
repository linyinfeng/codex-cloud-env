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

## Nix container

Build the custom image with `bash /workspace/codex-cloud-env/install.sh`.
It uses `nixos/nix:latest` and appends the repository's `nix.conf` to the image's
configuration, including flakes and linyinfeng's Cachix cache.

Create a container for each task. If a container from the previous task remains,
remove it with `docker rm -f codex-cloud-env` before starting the new one.

```bash
docker run -d --name codex-cloud-env \
    -v /workspace:/workspace \
    -v /etc/ssl/certs/ca-certificates.crt:/run/cloud-ca.pem:ro \
    -e NIX_SSL_CERT_FILE=/run/cloud-ca.pem \
    -e SSL_CERT_FILE=/run/cloud-ca.pem \
    -e CURL_CA_BUNDLE=/run/cloud-ca.pem \
    -e GH_TOKEN \
    -w /workspace \
    codex-cloud-env:local sleep infinity
docker exec codex-cloud-env nix --version
```

Docker supplies the proxy settings. The CA mount enables HTTPS verification.
The entrypoint configures Nix's GitHub access token from `GH_TOKEN` at runtime;
keep tokens out of the repository, image, and logs.

Reuse the container for commands:

```bash
nixrun() {
    docker exec -w "$PWD" codex-cloud-env "$@"
}
# From a project under /workspace:
# nixrun nix develop --command <command> <args...>
```

Workspace files persist through the bind mount. Nix downloads stay in the task
container until it is removed. Put shared tools in the Dockerfile. Use host
Git/GitHub tooling and container Nix tooling; use `path:.` flake references if
Git ownership differs. No project build is required for this generic environment.
