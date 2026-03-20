#!/bin/bash
# Generate RPM spec file for Stremio

# Check if variables are passed
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
    echo "Usage: $0 <RPM_NAME> <VERSION> <OUTPUT_FILE> <INSTALL_DIR>"
    echo "Example: $0 stremio 1.0.0 /path/to/stremio.spec /tmp/opt-stremio"
    exit 1
fi

RPM_NAME="$1"
VERSION="$2"
OUTPUT_FILE="$3"
INSTALL_DIR="$4"

# Get current user info
MAINTAINER="sassech"
MAINTAINER_EMAIL="${MAINTAINER_EMAIL:-lainstroop@gmail.com}"
BUILD_DATE=$(date '+%a %b %d %Y')

# Generate spec file
cat > "$OUTPUT_FILE" <<EOF
Name:           stremio
Version:        ${VERSION}
Release:        1%{?dist}
Summary:        Stremio media player
License:        GPLv2+
URL:            https://github.com/Stremio/stremio-shell
BuildArch:      x86_64

# Runtime dependencies
Requires:       qt5-qtbase
Requires:       qt5-qtwebengine
Requires:       qt5-qtquickcontrols
Requires:       qt5-qtquickcontrols2
Requires:       qt5-qtdeclarative
Requires:       qt5-qtgraphicaleffects
Requires:       mpv-libs
Requires:       openssl-libs
Requires:       nodejs >= 18

%description
Stremio is a modern media center that gives you the freedom to watch
everything you want. Custom build for Fedora.

%prep
# No prep needed

%build
# Already built

%install
# Copy files from install directory to buildroot
mkdir -p %{buildroot}/opt/stremio
cp -r ${INSTALL_DIR}/* %{buildroot}/opt/stremio/

# Create desktop file
mkdir -p %{buildroot}/usr/share/applications
cat > %{buildroot}/usr/share/applications/smartcode-stremio.desktop <<DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=Stremio
Comment=Watch movies, series, TV channels and video channels
Exec=/opt/stremio/stremio %U
Icon=/opt/stremio/icons/smartcode-stremio_128.png
Categories=AudioVideo;Video;Player;TV;
MimeType=x-scheme-handler/stremio;
Terminal=false
StartupNotify=true
DESKTOP

%files
%dir /opt/stremio
/opt/stremio/*
%{_datadir}/applications/smartcode-stremio.desktop

%post
# Create symlink to node from system PATH (Stremio shell looks for /opt/stremio/node)
ln -sf /usr/bin/node /opt/stremio/node 2>/dev/null || true
# Create symlink in /usr/bin for easy access
ln -sf /opt/stremio/stremio /usr/bin/stremio 2>/dev/null || true
# Update desktop database
update-desktop-database /usr/share/applications 2>/dev/null || true

%postun
# Remove symlink
rm -f /usr/bin/stremio 2>/dev/null || true
# Update desktop database
update-desktop-database /usr/share/applications 2>/dev/null || true

%changelog
* ${BUILD_DATE} ${MAINTAINER} <${MAINTAINER_EMAIL}> - ${VERSION}-1
- Initial RPM package
- Custom build for Fedora from stremio-shell source
EOF

if [ $? -eq 0 ]; then
    echo "✓ Spec file generated: $OUTPUT_FILE"
    exit 0
else
    echo "✗ Failed to generate spec file"
    exit 1
fi
