FROM fedora:42

ENV LANG C.UTF-8
WORKDIR /workspace

# Install build dependencies
RUN dnf -y upgrade-minimal && \
    dnf -y install --setopt=install_weak_deps=False \
    git wget nodejs \
    librsvg2-devel librsvg2-tools \
    mpv-libs-devel \
    qt5-qtbase-devel qt5-qtwebengine-devel \
    qt5-qtquickcontrols qt5-qtquickcontrols2 \
    openssl-devel \
    gcc gcc-c++ make \
    glibc-devel kernel-headers binutils \
    rpm-build rpmdevtools \
    && dnf clean all

# Copy project into image
COPY . /workspace

# Make the build script executable
RUN chmod +x /workspace/build-in-docker.sh /workspace/docker-build.sh || true

ENV RPM_NAME=stremio-custom
ENV VERSION=4.4.107

CMD ["/workspace/build-in-docker.sh"]
