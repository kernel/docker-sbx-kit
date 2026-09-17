#!/usr/bin/env bash
set -euo pipefail

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
  x86_64 | amd64) ARCH=amd64 ;;
  aarch64 | arm64) ARCH=arm64 ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
fi

case "${ID:-}:${VERSION_ID:-}" in
  ubuntu:24.04) UBUNTU_VERSION=2404 ;;
  ubuntu:26.04) UBUNTU_VERSION=2604 ;;
  *)
    echo "This helper supports Ubuntu 24.04 and 26.04. Follow Docker's installation guide for this distribution." >&2
    exit 1
    ;;
esac

DEB_URL="${SBX_DEB_URL:-https://github.com/docker/sbx-releases/releases/latest/download/DockerSandboxes-linux-${ARCH}-ubuntu${UBUNTU_VERSION}.deb}"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "Adding Docker's apt repository"
curl -fsSL https://get.docker.com | sudo REPO_ONLY=1 sh

echo "Installing docker-sbx from apt"
if sudo apt-get install -y docker-sbx; then
  sudo usermod -aG kvm "$USER"
  sbx version || true
  echo "Next step: run sbx login"
  exit 0
fi

echo "docker-sbx is not available from the configured apt repository."
echo "Falling back to $DEB_URL"

deb="$tmpdir/docker-sbx.deb"
curl -fsSL "$DEB_URL" -o "$deb"
sudo apt-get install -y "$deb"
sudo usermod -aG kvm "$USER"

sbx version || true
echo "Next step: run sbx login"
