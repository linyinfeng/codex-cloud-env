# Customize the base image with: docker build --build-arg NIX_BASE=... .
ARG NIX_BASE=nixos/nix@sha256:b49cb33f3a7e5cf3933ad8774529de0e3807ec5cf54987aa7ccdfb49f2fc55ed
FROM ${NIX_BASE}

RUN printf '\nexperimental-features = nix-command flakes\nsandbox = false\n' >> /etc/nix/nix.conf

# Add shared tools here, preferably using a pinned nixpkgs revision:
# RUN nix profile install github:NixOS/nixpkgs/<revision>#ripgrep
# For networked RUN steps, mount the Cloud CA using BuildKit's proxy_ca secret
# and set NIX_SSL_CERT_FILE/SSL_CERT_FILE/CURL_CA_BUNDLE for that step.

WORKDIR /workspace
ENTRYPOINT []
CMD ["bash"]
