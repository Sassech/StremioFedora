#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-stremio-builder:fedora}"

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
echo "Building image: $IMAGE_NAME"

# Support optional build args (pass-through)
BUILD_ARGS=()
if [ "$#" -gt 0 ]; then
	BUILD_ARGS=("$@")
fi

"$CMD_TOOL" build -t "$IMAGE_NAME" "$SCRIPT_DIR" "${BUILD_ARGS[@]}"


echo "Running build inside container (repo mounted to /workspace; RPM will be copied to repo root)"

# Mount the repo so the container can copy the RPM into its root. Build artifacts are still produced inside the container's temp dir.
"$CMD_TOOL" run --rm -v "$SCRIPT_DIR":/workspace "$IMAGE_NAME"

echo "Done. Check for RPMs in the repository root ($SCRIPT_DIR)"
