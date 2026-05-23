#!/usr/bin/env bash
# bootstrap.sh — one-liner installer for agent-config.
#
# Usage (curl-pipe-bash):
#   curl -fsSL https://raw.githubusercontent.com/elleryfamilia/agent-config/main/bootstrap.sh | bash
#
# Preview without making changes:
#   curl -fsSL https://raw.githubusercontent.com/elleryfamilia/agent-config/main/bootstrap.sh | bash -s -- --dry-run
#
# Env vars to override defaults:
#   AGENT_CONFIG_DIR          clone destination (default: $HOME/.agent-config)
#   AGENT_CONFIG_REPO         repo URL (default: https://github.com/elleryfamilia/agent-config)
#   AGENT_CONFIG_REF          branch/tag/sha to checkout (default: main)
#   AGENT_CONFIG_SKIP_INSTALL set to 1 to clone-only (don't run install.sh)
#
# Any extra args (e.g. --dry-run, --uninstall, --force) are forwarded to install.sh.

set -euo pipefail

REPO="${AGENT_CONFIG_REPO:-https://github.com/elleryfamilia/agent-config}"
DIR="${AGENT_CONFIG_DIR:-$HOME/.agent-config}"
REF="${AGENT_CONFIG_REF:-main}"

command -v git >/dev/null 2>&1 || { echo "error: git is required but not installed" >&2; exit 1; }

if [ -d "$DIR/.git" ]; then
    echo "Updating existing checkout at $DIR"
    git -C "$DIR" fetch origin --tags --prune
    git -C "$DIR" checkout "$REF"
    # Only fast-forward when on a branch tip; for tags/SHAs a checkout is enough.
    if git -C "$DIR" symbolic-ref --quiet HEAD >/dev/null; then
        git -C "$DIR" pull --ff-only origin "$REF"
    fi
else
    echo "Cloning $REPO → $DIR"
    git clone --branch "$REF" "$REPO" "$DIR"
fi

if [ "${AGENT_CONFIG_SKIP_INSTALL:-0}" = "1" ]; then
    echo ""
    echo "Clone complete. Run $DIR/install.sh manually when ready."
    exit 0
fi

echo ""
echo "Running installer..."
exec "$DIR/install.sh" "$@"
