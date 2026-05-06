#!/usr/bin/env bash
set -euo pipefail

KIT_DIR="${KIT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
WORKSPACE_DIR="${WORKSPACE_DIR:-$KIT_DIR}"
CREATE=0
CREATED_SANDBOX=0
SANDBOX_NAME="${SANDBOX_NAME:-}"

usage() {
  cat <<'EOF'
Usage: scripts/smoke.sh [--create] [--sandbox NAME]

Validates the Kernel sbx mixin. By default, this checks local
prerequisites and validates the kit without creating a sandbox.

Options:
  --create        Create a fresh Claude sandbox with this kit, then run checks.
  --sandbox NAME  Run checks against an existing sandbox.

Environment:
  KERNEL_API_KEY  Host-side Kernel API key read by the sbx proxy.
  KEEP_SANDBOX    Set to 1 to keep a sandbox created by --create.
  KIT_DIR         Kit directory to validate. Defaults to the repo root.
  WORKSPACE_DIR   Workspace mounted into a created sandbox. Defaults to KIT_DIR.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --create)
      CREATE=1
      shift
      ;;
    --sandbox)
      SANDBOX_NAME="${2:-}"
      if [[ -z "$SANDBOX_NAME" ]]; then
        echo "--sandbox requires a sandbox name" >&2
        exit 2
      fi
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd sbx
require_cmd docker

if [[ ! -e /dev/kvm ]]; then
  echo "Missing /dev/kvm. Docker Sandboxes require KVM on Linux." >&2
  exit 1
fi

if [[ -z "${KERNEL_API_KEY:-}" ]]; then
  echo "KERNEL_API_KEY must be set on the host for the sbx proxy credential source." >&2
  exit 1
fi

echo "Validating kit at $KIT_DIR"
sbx kit validate "$KIT_DIR"
sbx kit inspect "$KIT_DIR"

if [[ "$CREATE" -eq 1 ]]; then
  if [[ -z "$SANDBOX_NAME" ]]; then
    SANDBOX_NAME="kernel-smoke-$(date +%Y%m%d%H%M%S)"
  fi

  echo "Creating Claude sandbox $SANDBOX_NAME"
  sbx create --name "$SANDBOX_NAME" --kit "$KIT_DIR" claude "$WORKSPACE_DIR"
  CREATED_SANDBOX=1
fi

if [[ -z "$SANDBOX_NAME" ]]; then
  cat <<EOF

Kit validation passed.

To run the full sandbox smoke test:
  KERNEL_API_KEY=... scripts/smoke.sh --create

Or validate manually:
  KERNEL_API_KEY=... sbx run --name kernel-demo --kit "$KIT_DIR" claude
EOF
  exit 0
fi

echo "Checking Kernel tooling inside sandbox $SANDBOX_NAME"
sbx exec "$SANDBOX_NAME" sh -lc 'command -v kernel && kernel --version'

echo "Checking Kernel skills inside sandbox $SANDBOX_NAME"
sbx exec "$SANDBOX_NAME" sh -lc 'test -d "$HOME/.claude/skills/kernel-cli" && test -d "$HOME/.agents/skills/kernel-cli"'

echo "Checking Kernel API access through the proxy"
sbx exec "$SANDBOX_NAME" sh -lc 'kernel browsers list >/dev/null'

echo "Recent Kernel policy matches, if present:"
sbx policy log | grep -E 'api\.onkernel\.com|kernel' || true

if [[ "$CREATED_SANDBOX" -eq 1 && "${KEEP_SANDBOX:-0}" != "1" ]]; then
  echo "Removing smoke sandbox $SANDBOX_NAME"
  sbx rm --force "$SANDBOX_NAME"
fi
