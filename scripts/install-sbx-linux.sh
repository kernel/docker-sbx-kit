#!/usr/bin/env bash
set -euo pipefail

DEB_URL="${SBX_DEB_URL:-https://github.com/docker/sbx-releases/releases/latest/download/DockerSandboxes-linux-amd64-ubuntu2404.deb}"

if command -v sbx >/dev/null 2>&1; then
  echo "sbx is already installed: $(command -v sbx)"
  sbx version || true
  exit 0
fi

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This helper only installs sbx on Linux." >&2
  exit 1
fi

case "$(uname -m)" in
  x86_64 | amd64) ;;
  *)
    echo "Docker Sandboxes currently publishes Linux amd64 packages for this path." >&2
    exit 1
    ;;
esac

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "Adding Docker apt repository"
curl -fsSL https://get.docker.com | sudo REPO_ONLY=1 sh

echo "Installing docker-sbx from apt"
if sudo apt-get install -y docker-sbx; then
  sudo usermod -aG kvm "$USER"
  sbx version || true
  echo "Next step: run sbx login"
  exit 0
fi

echo "docker-sbx is not available from this apt repository."
echo "Falling back to the Ubuntu 24.04 release .deb: $DEB_URL"

deb="$tmpdir/docker-sbx.deb"
curl -fsSL "$DEB_URL" -o "$deb"
sudo apt-get install -y "$deb"
sudo usermod -aG kvm "$USER"

sbx version || true
echo "Next step: run sbx login"
