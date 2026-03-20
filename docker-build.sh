#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-stremio-builder:fedora}"
LOG_FILE="$SCRIPT_DIR/docker-build.log"

# Detect container tool
CMD_TOOL=""
if command -v podman &> /dev/null; then
	CMD_TOOL=podman
elif command -v docker &> /dev/null; then
	CMD_TOOL=docker
else
	echo "Error: neither podman nor docker is installed. Install one to proceed." >&2
	exit 1
fi

# Get host uid/gid for matching container user
HOST_UID=$(id -u)
HOST_GID=$(id -g)

echo "Using container tool: $CMD_TOOL"
echo "Host uid=$HOST_UID gid=$HOST_GID"

# Clear previous log
> "$LOG_FILE"

# Build args with uid/gid
BUILD_ARGS=(
	--build-arg "HOST_UID=$HOST_UID"
	--build-arg "HOST_GID=$HOST_GID"
)

# Pass additional build args if provided
if [ "$#" -gt 0 ]; then
	BUILD_ARGS+=("$@")
fi

echo "Building Docker image..."
if ! "$CMD_TOOL" build -t "$IMAGE_NAME" "$SCRIPT_DIR" "${BUILD_ARGS[@]}" >> "$LOG_FILE" 2>&1; then
	echo "Error building Docker image. Check $LOG_FILE for details."
	tail -n 20 "$LOG_FILE"
	exit 1
fi

echo "Docker image built successfully"
echo "Running build inside container..."

# Mount options: :Z for SELinux (Fedora), skip in GitHub Actions
MOUNT_OPTION=":Z"
RUN_ARGS=(--rm -v "$SCRIPT_DIR:/workspace${MOUNT_OPTION}")

# podman: keep host user namespace so output files are owned by host user
if [ "$CMD_TOOL" = "podman" ]; then
	RUN_ARGS+=(--userns=keep-id)
fi

if [ "${GITHUB_ACTIONS:-false}" = "true" ]; then
	RUN_ARGS=(--rm -v "$SCRIPT_DIR:/workspace")
fi

if ! "$CMD_TOOL" run "${RUN_ARGS[@]}" "$IMAGE_NAME"; then
	echo "Build failed inside container"
	exit 1
fi

echo ""
echo "Build completed successfully!"
echo "RPM file available in: $SCRIPT_DIR/output/"
ls -lh "$SCRIPT_DIR/output/"*.rpm 2>/dev/null || true
