#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
git config --global user.name Nano
git config --global user.email nano@linyinfeng.com
docker build --pull -t codex-cloud-env:local .
