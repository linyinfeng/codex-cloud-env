#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
hooks_dir="$HOME/.config/codex/git-hooks"
existing_hooks="$(git config --global --get core.hooksPath || true)"
if [[ -n "$existing_hooks" && "$existing_hooks" != "$hooks_dir" ]]; then
    printf 'Existing global core.hooksPath: %s; integrate hooks before proceeding.\n' "$existing_hooks" >&2
    exit 1
fi
mkdir -p "$hooks_dir"
install -m 0755 "$repo_dir/.githooks/prepare-commit-msg" "$hooks_dir/prepare-commit-msg"
git config --global user.name Nano
git config --global user.email nano@linyinfeng.com
git config --global core.hooksPath "$hooks_dir"
# Preserve codex.coauthor=false if the user has disabled the hook.
# Always use the managed local daemon, preserving Docker's registry credentials
# and configured proxy defaults for builds and containers.
unset DOCKER_HOST DOCKER_CONTEXT DOCKER_TLS DOCKER_TLS_VERIFY DOCKER_CERT_PATH
export DOCKER_HOST=unix:///var/run/docker.sock
docker info >/dev/null

build_args=()
if [[ -n "${CODEX_PROXY_CERT:-}" ]]; then
    build_args+=(--secret "id=proxy_ca,src=${CODEX_PROXY_CERT}")
fi
docker build "${build_args[@]}" --tag codex-cloud-env:local "$repo_dir"
docker run --rm codex-cloud-env:local nix --version
