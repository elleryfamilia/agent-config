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
REF="${AGENT_CONFIG_REF:-main}"

# Resolve clone destination. Priority:
#   1. AGENT_CONFIG_DIR  — explicit override always wins.
#   2. Existing install  — follow well-known symlinks created by install.sh.
#                          Avoids creating a redundant second clone on a host
#                          that already has agent-config installed at a
#                          non-default path (e.g. ~/_git/agent-config).
#   3. Default $HOME/.agent-config.
detect_existing_install() {
    local target candidate
    for target in \
        "$HOME/AGENTS.md" \
        "$HOME/.claude/CLAUDE.md" \
        "$HOME/.codex/AGENTS.md" \
        "$HOME/.gemini/GEMINI.md" \
        "$HOME/.config/opencode/AGENTS.md" \
        "$HOME/.config/github-copilot/global-copilot-instructions.md"; do
        if [ -L "$target" ]; then
            candidate=$(dirname "$(readlink "$target")")
            if [ -f "$candidate/install.sh" ] && [ -d "$candidate/.git" ]; then
                printf '%s' "$candidate"
                return 0
            fi
        fi
    done
    return 1
}

if [ -n "${AGENT_CONFIG_DIR:-}" ]; then
    DIR="$AGENT_CONFIG_DIR"
elif detected=$(detect_existing_install); then
    DIR="$detected"
    echo "Detected existing install at $DIR — using it (set AGENT_CONFIG_DIR to override)"
else
    DIR="$HOME/.agent-config"
fi

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
