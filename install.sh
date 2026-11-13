#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
cp -- AGENTS.gen.md /workspace/AGENTS.md
git config --global user.name Nano
git config --global user.email nano@linyinfeng.com
docker pull ghcr.io/linyinfeng/codex-cloud-env:latest
