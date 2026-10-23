# Stremio RPM Builder for Fedora

Automated build system to compile Stremio from source and create an RPM package.

Builds [stremio-linux-shell](https://github.com/Stremio/stremio-linux-shell), the
current Linux client (Rust, GTK4, libadwaita, WebKitGTK 6, libmpv). The legacy
Qt5 `stremio-shell` is no longer used.

## Download Prebuilt RPM

Get the latest release from [Releases](https://github.com/sassech/StremioFedora/releases).

## Build from Source

### Requirements
- Docker or Podman
- Target: Fedora 44+ (the build image is `fedora:44`; the RPM links against its GTK4/WebKitGTK)
- A few GB of disk space for the Rust toolchain and build cache

### Quick Start

```bash
./docker-build.sh
```

RPM output: `./output/stremio-*.rpm`

The latest upstream release tag is built by default. `build-in-docker.sh` also honors
`STREMIO_REF` (tag or branch) when it is set inside the container.

## Dependencies (on target system)

Runtime libraries (GTK4, libadwaita, WebKitGTK 6, mpv-libs, libepoxy, Node.js) are
pulled in by the RPM. No Qt is required. For extra codecs and hardware decoding:

```bash
sudo dnf install ffmpeg mpv gstreamer1-vaapi libva-utils  # codecs + VA-API
```

## Uninstall

```bash
sudo dnf remove stremio
```

## Build Info
- **Build Time**: approximate; first run compiles all Rust crates, later runs reuse the dnf cache
- **Source**: [github.com/Stremio/stremio-linux-shell](https://github.com/Stremio/stremio-linux-shell)

---
