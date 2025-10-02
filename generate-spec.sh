#!/bin/bash
# Generate RPM spec file for Stremio

# Check if variables are passed
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 <RPM_NAME> <VERSION> <OUTPUT_FILE>"
    echo "Example: $0 stremio-custom 1.0.0 /path/to/stremio-custom.spec"
    exit 1
fi

RPM_NAME="$1"
VERSION="$2"
OUTPUT_FILE="$3"

# Get current user info
MAINTAINER="sassech"
MAINTAINER_EMAIL="${MAINTAINER_EMAIL:-lainstroop@gmail.com}"
BUILD_DATE=$(date '+%a %b %d %Y')

# Generate spec file
cat > "$OUTPUT_FILE" <<EOF
Name:           ${RPM_NAME}
Version:        ${VERSION}
Release:        1%{?dist}
Summary:        Stremio media player custom build
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

%description
Stremio is a modern media center that gives you the freedom to watch
everything you want. Custom build for Fedora.

%prep
# No prep needed

%build
# Already built

%install
# Copy files from system installation to buildroot
mkdir -p %{buildroot}/opt/stremio
mkdir -p %{buildroot}/usr/share/applications

# Copy all stremio files
cp -r /opt/stremio/* %{buildroot}/opt/stremio/

# Copy desktop file to standard location
if [ -f %{buildroot}/opt/stremio/smartcode-stremio.desktop ]; then
    cp %{buildroot}/opt/stremio/smartcode-stremio.desktop %{buildroot}/usr/share/applications/
    # Update Exec path in desktop file
    sed -i 's|Exec=.*|Exec=/opt/stremio/stremio|g' %{buildroot}/usr/share/applications/smartcode-stremio.desktop
fi

%files
%dir /opt/stremio
/opt/stremio/*
/usr/share/applications/smartcode-stremio.desktop

%post
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
