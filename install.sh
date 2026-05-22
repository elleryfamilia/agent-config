#!/usr/bin/env bash
# install.sh — wire this repo's AGENTS.md into the global config locations of
# every supported AI coding tool, and put bin/agent-env on PATH.
#
# Idempotent. Backs up existing non-symlink files. Use --dry-run to preview.
#
# Targets:
#   Claude Code     ~/.claude/CLAUDE.md                                (symlink)
#   Codex           ~/.codex/AGENTS.md                                 (symlink)
#   OpenCode        ~/.config/opencode/AGENTS.md                       (symlink)
#   Gemini CLI      ~/.gemini/GEMINI.md                                (symlink)
#   Copilot (JB)    ~/.config/github-copilot/global-copilot-instructions.md (symlink)
#   Convenience     ~/AGENTS.md                                        (symlink)
#   agent-env       ~/.local/bin/agent-env                             (symlink)
#
# Manual (not automated, printed at end):
#   Cursor          paste contents of AGENTS.md into Cursor → Settings → Rules
#   Copilot CLI     export COPILOT_CUSTOM_INSTRUCTIONS_DIRS="$HOME" in your shell rc

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_AGENTS="$SCRIPT_DIR/AGENTS.md"
SRC_AGENT_ENV="$SCRIPT_DIR/bin/agent-env"

DRY_RUN=0
UNINSTALL=0
FORCE=0

usage() {
    cat <<EOF
Usage: install.sh [--dry-run] [--uninstall] [--force]

  --dry-run    Print actions without making changes.
  --uninstall  Remove symlinks that this installer created (only when they
               point at this repo — never touches unrelated files).
  --force      Replace existing symlinks that point elsewhere. Without --force
               those are reported and skipped.
  -h, --help   Show this help.

Repo: $SCRIPT_DIR
EOF
}

for arg in "$@"; do
    case "$arg" in
        --dry-run)   DRY_RUN=1 ;;
        --uninstall) UNINSTALL=1 ;;
        --force)     FORCE=1 ;;
        -h|--help)   usage; exit 0 ;;
        *) echo "Unknown argument: $arg" >&2; usage >&2; exit 2 ;;
    esac
done

# Color (suppressed when piped or NO_COLOR is set).
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_OK="$(printf '\033[32m')"; C_WARN="$(printf '\033[33m')"
    C_INFO="$(printf '\033[36m')"; C_OFF="$(printf '\033[0m')"
else
    C_OK=""; C_WARN=""; C_INFO=""; C_OFF=""
fi
ok()   { printf '%s✓%s %s\n' "$C_OK"   "$C_OFF" "$*"; }
warn() { printf '%s!%s %s\n' "$C_WARN" "$C_OFF" "$*"; }
info() { printf '%s·%s %s\n' "$C_INFO" "$C_OFF" "$*"; }

# Create symlink dst → src with backup and idempotency.
link_one() {
    local label="$1" src="$2" dst="$3"
    local parent; parent=$(dirname "$dst")

    if [ "$UNINSTALL" -eq 1 ]; then
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
            if [ "$DRY_RUN" -eq 1 ]; then
                info "[$label] would remove $dst"
            else
                rm "$dst"; ok "[$label] removed $dst"
            fi
        else
            info "[$label] no managed symlink at $dst — skipping"
        fi
        return
    fi

    # Create parent dir.
    if [ ! -d "$parent" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            info "[$label] would mkdir -p $parent"
        else
            mkdir -p "$parent"
        fi
    fi

    # Already correctly linked → no-op.
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        ok "[$label] already linked: $dst"
        return
    fi

    # Symlink pointing elsewhere → skip unless --force.
    if [ -L "$dst" ]; then
        local existing; existing=$(readlink "$dst")
        if [ "$FORCE" -ne 1 ]; then
            warn "[$label] $dst → $existing (use --force to replace)"
            return
        fi
        if [ "$DRY_RUN" -eq 1 ]; then
            info "[$label] would remove existing symlink $dst → $existing"
        else
            rm "$dst"
        fi
    elif [ -e "$dst" ]; then
        # Regular file at destination → back it up.
        local bak; bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
        if [ "$DRY_RUN" -eq 1 ]; then
            info "[$label] would back up $dst → $bak"
        else
            mv "$dst" "$bak"
            warn "[$label] backed up existing file to $bak"
        fi
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        info "[$label] would link $dst → $src"
    else
        ln -s "$src" "$dst"
        ok "[$label] linked $dst → $src"
    fi
}

# Preflight.
[ -f "$SRC_AGENTS" ]   || { echo "Missing $SRC_AGENTS"   >&2; exit 1; }
[ -f "$SRC_AGENT_ENV" ] || { echo "Missing $SRC_AGENT_ENV" >&2; exit 1; }
[ -x "$SRC_AGENT_ENV" ] || chmod +x "$SRC_AGENT_ENV"

mode_label="install"
[ "$DRY_RUN"   -eq 1 ] && mode_label="dry-run"
[ "$UNINSTALL" -eq 1 ] && mode_label="uninstall"
echo "agent-config installer ($mode_label)"
echo "  repo: $SCRIPT_DIR"
echo ""

# Per-tool wiring. We create the symlinks unconditionally so the config is in
# place when the tool gets installed later. Empty parent dirs are tiny and harmless.
link_one "Claude Code"    "$SRC_AGENTS" "$HOME/.claude/CLAUDE.md"
link_one "Codex"          "$SRC_AGENTS" "$HOME/.codex/AGENTS.md"
link_one "OpenCode"       "$SRC_AGENTS" "$HOME/.config/opencode/AGENTS.md"
link_one "Gemini CLI"     "$SRC_AGENTS" "$HOME/.gemini/GEMINI.md"
link_one "Copilot (JB)"   "$SRC_AGENTS" "$HOME/.config/github-copilot/global-copilot-instructions.md"
link_one "Convenience"    "$SRC_AGENTS" "$HOME/AGENTS.md"
link_one "agent-env"      "$SRC_AGENT_ENV" "$HOME/.local/bin/agent-env"

if [ "$UNINSTALL" -eq 0 ]; then
    echo ""
    echo "Manual steps (not automated):"
    echo ""
    echo "  Copilot CLI:  add to your shell rc (~/.zshrc, ~/.bashrc):"
    echo "      export COPILOT_CUSTOM_INSTRUCTIONS_DIRS=\"\$HOME\""
    echo "    Copilot CLI will then read ~/AGENTS.md as global instructions."
    echo ""
    echo "  Cursor:       Cursor has no global rules file on disk. Open Cursor →"
    echo "    Settings → Rules and paste the contents of AGENTS.md."
    echo ""
    echo "  PATH:         ensure ~/.local/bin is on PATH so agent-env is discoverable."
fi
