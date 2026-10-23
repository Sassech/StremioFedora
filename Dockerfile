# syntax=docker/dockerfile:1
FROM fedora:44

ENV LANG=C.UTF-8
ENV BUILDKIT_PROGRESS=plain
WORKDIR /workspace

# Build toolchain for stremio-linux-shell (Rust + GTK4 + libadwaita + WebKitGTK 6 + libmpv).
# gettext provides msgfmt and glib2-devel provides glib-compile-schemas (both used by build.rs).
# /usr/bin/node is a file provide so dnf picks whichever Node.js package Fedora ships.
RUN --mount=type=cache,target=/var/cache/dnf \
    --mount=type=cache,target=/var/lib/dnf \
    dnf -y upgrade-minimal && \
    dnf clean all && \
    dnf install -y --setopt=install_weak_deps=False \
    --setopt=timeout=60 --setopt=retries=10 --setopt=minrate=10k \
    git curl rpm-build gcc pkgconf-pkg-config \
    rust cargo \
    gtk4-devel libadwaita-devel webkitgtk6.0-devel mpv-devel libepoxy-devel \
    gettext glib2-devel desktop-file-utils \
    /usr/bin/node \
    && dnf clean all

# Creacion de usuario y grupo con el mismo UID y GID que el host para evitar problemas de permisos
ARG HOST_UID=1000
ARG HOST_GID=1000
RUN groupadd -g ${HOST_GID} builder && \
    useradd -u ${HOST_UID} -g builder -s /bin/bash -d /home/builder -m builder && \
    mkdir -p /workspace && chown -R builder:builder /workspace

COPY --chown=builder:builder . /workspace
RUN chmod +x /workspace/*.sh 2>/dev/null || true

USER builder

# Keep the Cargo registry/cache in a builder-owned directory
ENV CARGO_HOME=/home/builder/.cargo

ENTRYPOINT ["/bin/bash", "-c", "cd /workspace && bash build-in-docker.sh"]
