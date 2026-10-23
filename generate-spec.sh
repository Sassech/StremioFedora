#!/bin/bash
# Generación de archivo spec para Stremio en Fedora
set -euo pipefail

# Verifica si se proporcionaron los argumentos necesarios
if [ -z "${1:-}" ] || [ -z "${2:-}" ] || [ -z "${3:-}" ] || [ -z "${4:-}" ]; then
    echo "Usage: $0 <RPM_NAME> <VERSION> <OUTPUT_FILE> <INSTALL_DIR> [ARCH]"
    echo "Example: $0 stremio 1.2.2 /path/to/stremio.spec /tmp/build/fakeroot x86_64"
    echo "INSTALL_DIR is a fakeroot tree laid out like / (usr/bin, usr/libexec, usr/share)"
    exit 1
fi

RPM_NAME="$1"
VERSION="$2"
OUTPUT_FILE="$3"
INSTALL_DIR="$4"
ARCH="${5:-$(uname -m)}"

BUILD_DATE=$(LC_ALL=C date '+%a %b %d %Y')

cat > "$OUTPUT_FILE" <<EOF
# Binary is prebuilt outside rpmbuild; no debuginfo subpackage
%global debug_package %{nil}

Name:           ${RPM_NAME}
# Epoch 1: stremio-linux-shell restarts at 1.x, below the legacy stremio-shell 4.4.x
# packages, so the epoch is required for dnf to treat this build as an upgrade.
Epoch:          1
Version:        ${VERSION}
Release:        1%{?dist}
Summary:        Stremio media center (GTK4 / WebKitGTK / libmpv shell)
License:        GPL-3.0-only
URL:            https://github.com/Stremio/stremio-linux-shell
BuildArch:      ${ARCH}

# Shared libraries are picked up by rpm autodeps; libepoxy is dlopen()ed at
# runtime and node is spawned from PATH, so those are listed explicitly.
Requires:       gtk4
Requires:       libadwaita
Requires:       webkitgtk6.0
Requires:       mpv-libs
Requires:       libepoxy
Requires:       /usr/bin/node

%description
Stremio is a modern media center that gives you the freedom to watch
everything you want. This package is built from stremio-linux-shell,
the GTK4, libadwaita, WebKitGTK and libmpv based Linux client.

%prep
# No prep needed

%build
# Already built

%install
mkdir -p %{buildroot}
cp -a ${INSTALL_DIR}/. %{buildroot}/

%files
%license %{_datadir}/licenses/stremio/LICENSE
%{_bindir}/stremio
%dir %{_libexecdir}/stremio
%{_libexecdir}/stremio/stremio
%{_libexecdir}/stremio/server.js
%{_datadir}/applications/com.stremio.Stremio.desktop
%{_datadir}/dbus-1/services/com.stremio.Stremio.service
%{_datadir}/icons/hicolor/scalable/apps/com.stremio.Stremio.svg
%{_datadir}/glib-2.0/schemas/com.stremio.Stremio.gschema.xml
%{_datadir}/metainfo/com.stremio.Stremio.metainfo.xml
%{_mandir}/man1/stremio.1*

%changelog
* ${BUILD_DATE} builder - ${VERSION}-1
- Build from stremio-linux-shell ${VERSION} for Fedora
EOF

echo "Spec file generated: $OUTPUT_FILE"
