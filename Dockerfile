# Customize the base image with: docker build --build-arg NIX_BASE=... .
ARG NIX_BASE=nixos/nix:latest
FROM ${NIX_BASE}

COPY nix.conf /tmp/codex-nix.conf
RUN printf '\n' >> /etc/nix/nix.conf \
    && cat /tmp/codex-nix.conf >> /etc/nix/nix.conf \
    && rm /tmp/codex-nix.conf
COPY --chmod=755 entrypoint.sh /usr/local/bin/codex-nix-entrypoint

# Add shared tools here, preferably using a pinned nixpkgs revision:
# RUN nix profile install github:NixOS/nixpkgs/<revision>#ripgrep

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/codex-nix-entrypoint"]
CMD ["bash"]
