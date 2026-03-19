#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-stremio-builder:fedora}"
LOG_FILE="$SCRIPT_DIR/docker-build.log"

# Clear previous log
> "$LOG_FILE"

CMD_TOOL=""
if command -v podman &> /dev/null; then
	CMD_TOOL=podman
elif command -v docker &> /dev/null; then
	CMD_TOOL=docker
else
	echo "Error: neither podman nor docker is installed. Install one to proceed." >&2
	exit 1
fi

echo "Using container tool: $CMD_TOOL"
echo "Building Docker image..."

# Support optional build args (pass-through)
BUILD_ARGS=()
if [ "$#" -gt 0 ]; then
	BUILD_ARGS=("$@")
fi

if ! "$CMD_TOOL" build -t "$IMAGE_NAME" "$SCRIPT_DIR" "${BUILD_ARGS[@]}" >> "$LOG_FILE" 2>&1; then
	echo "Error building Docker image. Check $LOG_FILE for details."
	tail -n 20 "$LOG_FILE"
	exit 1
fi

echo "Docker image built successfully"
echo "Running build inside container..."

# Use :Z for local builds (Fedora/SELinux), but skip it in GitHub Actions
MOUNT_OPTION=":Z"
if [ "${GITHUB_ACTIONS:-false}" = "true" ]; then
	MOUNT_OPTION=""
fi

if ! "$CMD_TOOL" run --rm -v "$SCRIPT_DIR":/workspace${MOUNT_OPTION} "$IMAGE_NAME"; then
	echo "Build failed inside container"
	exit 1
fi

echo ""
echo "Build completed successfully!"
echo "RPM file available in: $SCRIPT_DIR/output/"
ls -lh "$SCRIPT_DIR/output/"*.rpm 2>/dev/null || true
