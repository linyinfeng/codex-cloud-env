# Agent instructions

Before starting work, read and follow `/workspace/codex-cloud-env/start-skill.md`.
It defines this environment's Git identity, commit trailers, and Docker/Nix workflow.

Each Cloud task is already isolated. Use existing checkouts under `/workspace`;
do not create Git worktrees unless the user explicitly asks.

Use host Git/GitHub tools and the task container for Nix commands. Check whether
the required container is running and start it as documented before using Nix;
do not assume installation restored running services.
