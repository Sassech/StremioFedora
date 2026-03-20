# Stremio RPM Builder for Fedora

Automated build system to compile Stremio from source and create an RPM package.

## Download Prebuilt RPM

Get the latest release from [Releases](https://github.com/sassech/StremioFedora/releases).

## Build from Source

### Requirements
- Docker or Podman
- Fedora 30+ / RHEL 8+
- ~2GB disk space

### Quick Start

```bash
./docker-build.sh
```

RPM output: `./output/stremio-*.rpm`

## Dependencies (on target system)

```bash
sudo dnf install ffmpeg mpv gstreamer1-vaapi libva-utils  # codecs + VA-API
```

## Uninstall

```bash
sudo dnf remove stremio
```

## Build Info
- **Build Time**: ~10-15 min (first run), ~5-8 min (cached)
- **RPM Size**: ~1.1MB
- **Source**: [github.com/Stremio/stremio-shell](https://github.com/Stremio/stremio-shell)

---

Build system by [sassech](https://github.com/sassech). Provided as-is. Stremio is subject to its own license.
