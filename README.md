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

## � Quick Start

### One Command Installation

```bash
./stremio-install.sh
```

That's it! This single command will:

1. **Install multimedia codecs** (RPM Fusion, FFmpeg, MPV)
2. **Install build dependencies** (Qt5, gcc, etc.)
3. **Download Stremio source code**
4. **Clean previous installations**
5. **Compile Stremio**
6. **Create RPM package**
7. **Clean up temporary files**

### Install the Generated RPM

After the build completes:

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
├── stremio-install.sh                   # Main orchestrator (run this!)
├── stremio-install-codecs.sh            # Codec installer (called automatically)
├── stremio-previous-installation.sh     # Clean previous installations
├── stremio-cleanup-build.sh             # Post-build cleanup
├── generate-spec.sh                     # Generate RPM spec file
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

## 📄 License

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
