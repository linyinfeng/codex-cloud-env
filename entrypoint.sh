#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${GH_TOKEN:-}" ]]; then
    umask 077
    printf 'access-tokens = github.com=%s\n' "$GH_TOKEN" \
        > /run/codex-nix-access-tokens.conf
fi
unset GH_TOKEN
exec "$@"
