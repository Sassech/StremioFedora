#!/bin/bash
set -euo pipefail

SCRIPT_DIR="/workspace"
OUTPUT_DIR="$SCRIPT_DIR/output"
TMP_BUILD="/tmp/build"
BUILD_LOG="/tmp/build.log"
REPO_URL="https://github.com/Stremio/stremio-linux-shell.git"
REPO_API="https://api.github.com/repos/Stremio/stremio-linux-shell/releases/latest"
SRC_DIR="$TMP_BUILD/stremio-linux-shell"
FAKEROOT="$TMP_BUILD/fakeroot"
LIBEXEC_DIR="$FAKEROOT/usr/libexec/stremio"
APP_ID="com.stremio.Stremio"

mkdir -p "$TMP_BUILD" "$OUTPUT_DIR"

cd "$TMP_BUILD"

# Limpiar cualquier build previo
rm -rf "$SRC_DIR" "$FAKEROOT"

# Only published releases are built: STREMIO_REF (a release tag) or the latest release tag
STREMIO_REF="${STREMIO_REF:-}"
if [ -z "$STREMIO_REF" ]; then
    echo "Fetching latest Stremio release tag..."
    STREMIO_REF="$(curl -fsS "$REPO_API" 2>/dev/null \
        | grep -oP '"tag_name":\s*"\K[^"]+' || true)"
fi
if [ -z "$STREMIO_REF" ]; then
    echo "Error: could not resolve the latest Stremio release tag"
    exit 1
fi
echo "Using Stremio release: $STREMIO_REF"

CLONE_ARGS=(--depth 1 --single-branch --branch "$STREMIO_REF")

echo "Downloading Stremio source code..."
if ! git clone "${CLONE_ARGS[@]}" "$REPO_URL" "$SRC_DIR" >> "$BUILD_LOG" 2>&1; then
    echo "Error downloading Stremio source"
    tail -n 20 "$BUILD_LOG"
    exit 1
fi

cd "$SRC_DIR"

# Version comes from the [package] section of the cloned Cargo.toml
VERSION="$(awk -F'"' '
    /^\[/ { in_pkg = ($0 == "[package]") }
    in_pkg && /^version[[:space:]]*=/ { print $2; exit }
' Cargo.toml)"
if [ -z "$VERSION" ]; then
    echo "Error: could not read package version from Cargo.toml"
    exit 1
fi
echo "Building Stremio version: $VERSION"

# Must run from the repo root: .cargo/config.toml uses cwd-relative env paths
echo "Compiling Stremio..."
if ! cargo build --release --locked >> "$BUILD_LOG" 2>&1; then
    echo "Error compiling Stremio"
    tail -n 30 "$BUILD_LOG"
    exit 1
fi

echo "Installing Stremio files..."
install -Dm755 target/release/stremio-linux-shell "$LIBEXEC_DIR/stremio"
install -Dm644 data/server.js -t "$LIBEXEC_DIR/"
install -Dm644 "data/$APP_ID.desktop" -t "$FAKEROOT/usr/share/applications/"
install -Dm644 "data/$APP_ID.service" -t "$FAKEROOT/usr/share/dbus-1/services/"
sed -i 's|^Exec=.*|Exec=/usr/bin/stremio --gapplication-service|' \
    "$FAKEROOT/usr/share/dbus-1/services/$APP_ID.service"
install -Dm644 "data/icons/$APP_ID.svg" -t "$FAKEROOT/usr/share/icons/hicolor/scalable/apps/"
# Source schema only; Fedora's glib2 file triggers compile it on install
install -Dm644 "data/$APP_ID.gschema.xml" -t "$FAKEROOT/usr/share/glib-2.0/schemas/"
install -Dm644 "data/$APP_ID.metainfo.xml" -t "$FAKEROOT/usr/share/metainfo/"
install -Dm644 data/stremio.1 -t "$FAKEROOT/usr/share/man/man1/"
install -Dm644 LICENSE -t "$FAKEROOT/usr/share/licenses/stremio/"

# Translations are not packaged: release builds load them from the build-time source path

# Launcher wrapper, adapted from upstream data/stremio.sh
install -d "$FAKEROOT/usr/bin"
cat > "$FAKEROOT/usr/bin/stremio" << 'WRAPPER'
#!/bin/bash

# Use GSK OpenGL renderer for Nvidia cards
if [ -e /dev/nvidia0 ]; then
    export GSK_RENDERER=opengl
fi

# Optional VA-API driver override, e.g. LIBVA_DRIVER_NAME=radeonsi stremio
#   Intel: iHD    AMD: radeonsi    NVIDIA: nouveau

export SERVER_PATH="${SERVER_PATH:-/usr/libexec/stremio/server.js}"

exec /usr/libexec/stremio/stremio "$@"
WRAPPER
chmod 0755 "$FAKEROOT/usr/bin/stremio"

desktop-file-validate "$FAKEROOT/usr/share/applications/$APP_ID.desktop" >> "$BUILD_LOG" 2>&1 \
    || echo "Warning: desktop file validation reported issues (see build log)"

echo "Verifying streaming server..."
mkdir -p ~/.stremio-server
cd "$LIBEXEC_DIR"
node server.js > /tmp/server_test.log 2>&1 &
SERVER_PID=$!

POLL_ATTEMPTS=30
SERVER_READY=false
for ((i = 1; i <= POLL_ATTEMPTS; i++)); do
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "Error: streaming server crashed during startup (attempt $i)"
        cat /tmp/server_test.log
        exit 1
    fi
    if grep -q "EngineFS server started" /tmp/server_test.log 2>/dev/null; then
        SERVER_READY=true
        echo "Streaming server verified successfully"
        break
    fi
    sleep 1
done

if [ "$SERVER_READY" != "true" ]; then
    echo "Error: streaming server did not report ready within ${POLL_ATTEMPTS}s"
    cat /tmp/server_test.log
    kill "$SERVER_PID" 2>/dev/null || true
    exit 1
fi

kill "$SERVER_PID" 2>/dev/null || true
wait "$SERVER_PID" 2>/dev/null || true

cd "$TMP_BUILD"

# Genera el archivo spec para rpmbuild
RPM_TOP_DIR="$TMP_BUILD/rpmbuild"
RPM_NAME="stremio"
RPM_ARCH="${RPM_ARCH:-$(uname -m)}"

mkdir -p "$RPM_TOP_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

echo "Creating RPM package..."

SOURCE_DIR="$RPM_TOP_DIR/SOURCES"
tar -czf "$SOURCE_DIR/${RPM_NAME}-${VERSION}.tar.gz" -C "$TMP_BUILD" fakeroot 2>/dev/null

/workspace/generate-spec.sh "$RPM_NAME" "$VERSION" "$RPM_TOP_DIR/SPECS/${RPM_NAME}.spec" "$FAKEROOT" "$RPM_ARCH" >> "$BUILD_LOG" 2>&1

if ! rpmbuild --define "_topdir ${RPM_TOP_DIR}" -bb "$RPM_TOP_DIR/SPECS/${RPM_NAME}.spec" >> "$BUILD_LOG" 2>&1; then
    echo "Error creating RPM package"
    tail -n 30 "$BUILD_LOG"
    exit 1
fi

RPM_FILE=$(find "$RPM_TOP_DIR/RPMS" -name "${RPM_NAME}-${VERSION}-1*.rpm" -type f 2>/dev/null | head -n 1)
if [ -z "$RPM_FILE" ]; then
    echo "Error: RPM file not found in $RPM_TOP_DIR/RPMS/"
    find "$RPM_TOP_DIR/RPMS" -type f 2>/dev/null || true
    exit 1
fi
cp "$RPM_FILE" "$OUTPUT_DIR/"

echo "Verifying RPM package..."
if ! rpm -qpl "$OUTPUT_DIR/$(basename "$RPM_FILE")" &>/dev/null; then
    echo "Error: RPM package is empty or invalid"
    exit 1
fi
echo "RPM package verified: $(basename "$RPM_FILE")"

rm -rf "$TMP_BUILD" "$BUILD_LOG" 2>/dev/null || true

echo "RPM package created successfully"
