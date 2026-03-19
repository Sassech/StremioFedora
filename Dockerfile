# syntax=docker/dockerfile:1
FROM fedora:43

ENV LANG=C.UTF-8
ENV BUILDKIT_PROGRESS=plain
WORKDIR /workspace

RUN --mount=type=cache,target=/var/cache/dnf \
    --mount=type=cache,target=/var/lib/dnf \
    dnf -y upgrade-minimal && \
    dnf clean all && \
    dnf install -y --setopt=install_weak_deps=False \
    git wget nodejs librsvg2-devel librsvg2-tools \
    mpv-libs-devel qt5-qtbase-devel qt5-qtwebengine-devel \
    qt5-qtquickcontrols qt5-qtquickcontrols2 openssl-devel \
    gcc gcc-c++ make glibc-devel kernel-headers binutils \
    rpm-build rpmdevtools curl \
    && dnf clean all

RUN groupadd -g 1001 builder && \
    useradd -u 1001 -g builder -s /bin/bash -d /home/builder -m builder && \
    mkdir -p /workspace && chown -R builder:builder /workspace

COPY --chown=builder:builder . /workspace
RUN chmod +x /workspace/*.sh 2>/dev/null || true

ENV RPM_NAME=stremio-custom
ENV VERSION=4.4.107

USER builder

ENTRYPOINT ["/bin/bash", "-c", "cd /workspace && bash build-in-docker.sh"]
