#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
git config --global user.name Nano
git config --global user.email nano@linyinfeng.com
# Remove only the automatic hook previously installed by this setup.
hooks_dir="$HOME/.config/codex/git-hooks"
if [[ "$(git config --global --get core.hooksPath || true)" == "$hooks_dir" ]]; then
    git config --global --unset core.hooksPath
    rm -f "$hooks_dir/prepare-commit-msg"
fi
# Always use the managed local daemon, preserving Docker's registry credentials
# and configured proxy defaults for builds and containers.
unset DOCKER_HOST DOCKER_CONTEXT DOCKER_TLS DOCKER_TLS_VERIFY DOCKER_CERT_PATH
export DOCKER_HOST=unix:///var/run/docker.sock
docker info >/dev/null

build_args=()
if [[ -n "${CODEX_PROXY_CERT:-}" ]]; then
    build_args+=(--secret "id=proxy_ca,src=${CODEX_PROXY_CERT}")
fi
docker build --pull "${build_args[@]}" --tag codex-cloud-env:local "$repo_dir"
docker image inspect codex-cloud-env:local >/dev/null
