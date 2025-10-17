# Stremio RPM Builder for Fedora

Automated build system to compile Stremio from source and create an RPM package for Fedora Linux with full multimedia codec support.

## Prebuild RPM

If you want to skip the build process, you can download a prebuilt RPM from this repo's [Releases](https://github.com/sassech/StremioFedora/releases):

## 📋 Features

- ✅ Automatic RPM Fusion and codec installation
- ✅ Hardware acceleration support (VA-API)
- ✅ Automatic dependency installation
- ✅ Downloads latest Stremio source code
- ✅ Compiles from source with Qt5
- ✅ Creates custom RPM package
- ✅ Automatic cleanup of build artifacts
- ✅ Optional removal of build dependencies
- ✅ Fully automated - single command setup

## 🔧 Requirements

- **Operating System**: Fedora 30 or newer
- **Privileges**: sudo access required
- **Internet**: Active connection for downloading dependencies and source code
- **Disk Space**: ~1GB free space for build process

## Quick start

### Preferred: Dockerized build (recommended)

Use the included helper to build the RPM inside a Fedora container. This keeps build dependencies out of your host system and makes the process reproducible.

`docker-build.sh` will automatically prefer `podman` if it is installed; otherwise it falls back to `docker`.

```bash
./docker-build.sh
```

When the container finishes, the produced RPM (if successfully created) will be available under `./output/rpms`.

Note: The helper is configured to avoid creating build artifacts in the repository tree. It only mounts `./output` from the host and performs the build inside the container's temporary filesystem. After running `./docker-build.sh` you should only see the `output/rpms` directory appear (unless you previously had other files there).

If you still need the legacy host-based installer, those scripts have been archived in `scripts/legacy/`.

### Install the Generated RPM (host)

After the build completes (either via Docker or manual host build):

```bash
sudo dnf install ./stremio-custom-1.0.0-1.fc42.x86_64.rpm
```

### Launch Stremio

```bash
stremio
```

Or find it in your application menu.

## 📦 What Gets Installed

### Multimedia Codecs (via stremio-install-codecs.sh)

- **RPM Fusion Non-Free**: Repository for proprietary codecs
- **FFmpeg**: Complete codec support (H.264, H.265, AAC, MP3, etc.)
- **MPV**: Video player backend
- **Hardware Acceleration**: VA-API support for GPU decoding

### Build Dependencies (temporary)

- Development tools: `gcc`, `gcc-c++`, `make`
- Qt5 libraries: `qt5-qtbase-devel`, `qt5-qtwebengine-devel`
- Media libraries: `mpv-libs-devel`, `librsvg2-devel`
- Build tools: `rpm-build`, `rpmdevtools`, `nodejs`, `git`

### Final RPM Package Includes

- Stremio binary and assets in `/opt/stremio`
- Symlink in `/usr/bin/stremio`
- Desktop entry for application launcher

## 📁 Project Structure

```
StremioFedora/
├── scripts/legacy/                       # Archived host-based scripts (moved from repo root)
│   ├── stremio-install.sh                # Legacy host install (archived)
│   └── stremio-cleanup-build.sh          # Legacy cleanup (archived)
├── stremio-install-codecs.sh            # Codec installer (called automatically by legacy script)
├── generate-spec.sh                     # Generate RPM spec file
├── Dockerfile                           # Image to build Stremio and RPM inside container
├── docker-build.sh                      # Host helper: build image and run container
├── build-in-docker.sh                   # Runs the build steps inside the container
├── .dockerignore                        # Ignore files for docker build context
├── output/                              # Build output (populated after container run)
│   └── rpms/
├── stremio-custom-VERSION.rpm           # Generated RPM (after build)
└── README.md                            # This file
```

## 🔄 Complete Build Process Flow

```
┌─────────────────────────────────────────┐
│  ./stremio-install.sh                   │
│  (Single command - fully automated)     │
└────────────┬────────────────────────────┘
             │
             ├─► 1. stremio-install-codecs.sh
             │   ├─► Install RPM Fusion Non-Free
             │   ├─► Install FFmpeg & MPV
             │   └─► Install hardware acceleration
             │
             ├─► 2. Install Build Dependencies
             │   └─► Qt5, gcc, make, etc.
             │
             ├─► 3. Download Source Code
             │   └─► git clone stremio-shell
             │
             ├─► 4. Patch Files
             │   └─► qmake → qmake-qt5
             │
             ├─► 5. stremio-previous-installation.sh
             │   └─► Clean old installations
             │
             ├─► 6. Compile & Install
             │   ├─► qmake-qt5
             │   ├─► make
             │   └─► make install
             │
             ├─► 7. generate-spec.sh
             │   └─► Create RPM spec file
             │
             ├─► 8. Build RPM
             │   └─► rpmbuild
             │
             └─► 9. stremio-cleanup-build.sh
                 ├─► Remove build directories
                 ├─► Remove manual installation
                 └─► Optional: Remove dependencies
```

## ⚙️ Configuration

Edit `stremio-install.sh` to customize:

```bash
VERSION="1.0.0"                # RPM version
RPM_NAME="stremio-custom"      # RPM package name
INSTALL_PREFIX="/opt/stremio"  # Installation directory
```

## 🎬 Codec Information

The script installs the following codecs via RPM Fusion:

- **H.264/AVC** (libx264): Most common video codec
- **H.265/HEVC** (libx265): High efficiency codec
- **VP8/VP9** (libvpx): Open video codecs
- **AAC**: Advanced audio codec
- **MP3** (libmp3lame): Common audio codec
- **Opus, Vorbis, FLAC**: Open audio codecs

**Hardware Acceleration:** VA-API support for Intel, AMD, and NVIDIA GPUs.

## 🐛 Troubleshooting

### Script stops with "stremio-install-codecs.sh not found"

Make sure all scripts are executable:

```bash
chmod +x *.sh
```

### Video playback doesn't work

Codecs should be installed automatically. If not, run manually:

```bash
./stremio-install-codecs.sh
```

### Build fails with "qmake: command not found"

The script should patch this automatically. If it persists:

```bash
sudo dnf install qt5-qtbase-devel
```

### RPM build fails

Verify Stremio was installed:

```bash
ls -la /opt/stremio
```

### Check hardware acceleration

After installing codecs:

```bash
vainfo  # Shows VA-API devices and supported formats
```

### Dependencies installation fails

Update your system:

```bash
sudo dnf update
```

## 📝 Notes

- **Fully automated**: Single command does everything
- **Codecs first**: Multimedia support installed before building
- **Clean system**: Temporary files automatically removed
- **Build time**: 10-15 minutes depending on hardware
- **RPM architecture**: x86_64 only
- **Safe**: All packages from official Fedora and RPM Fusion repos

## 🔐 Security

- All dependencies from official Fedora repositories
- RPM Fusion packages are signed and verified
- Source code from official Stremio GitHub
- RPM built locally on your machine
- No external binaries downloaded

## 🗑️ Uninstallation

### Remove Stremio RPM

```bash
sudo dnf remove stremio-custom
```

### Remove codecs (optional)

```bash
sudo dnf remove ffmpeg mpv
sudo dnf remove rpmfusion-nonfree-release
```

### Clean manual installations

```bash
./stremio-cleanup-build.sh
```

## � Dockerized build (build RPM inside a container)

If you prefer to build the RPM inside a Fedora container (recommended to avoid polluting the host with build deps), use the included Docker helpers.

1. Build the builder image and run the build (from the repo root):

```bash
./docker-build.sh
```

2. The produced RPM (if successfully built) will be available under `./output/rpms` in the repository directory.

Notes:

- The container image installs build dependencies inside the image. The build runs non-interactively and attempts to place the installed files into a fake root so `rpmbuild` can package them.
- Building large components (Qt/WebEngine) may take time and require sufficient disk space.

## �📄 License

This build system is provided as-is for building Stremio on Fedora. Stremio itself is subject to its own license terms.

## 🔗 Links

- **Stremio Official**: https://www.stremio.com/
- **Stremio GitHub**: https://github.com/Stremio/stremio-shell
- **Fedora Project**: https://getfedora.org/
- **RPM Fusion**: https://rpmfusion.org/

## 📊 Build Statistics

- **Total Time**: 10-15 minutes (including codec installation)
- **Disk Space**: ~1GB temporary, 50MB installed
- **Final RPM Size**: ~1.1MB
- **Scripts**: 5 modular scripts

---

**Made with ❤️ for Fedora users**

**One command. Full setup. Ready to stream.** 🚀
