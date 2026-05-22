# agent-config

My personal AI coding rules and a tiny env-discovery script, wired into every tool I use with one install command.

`AGENTS.md` is the single source of truth (the cross-tool standard stewarded by the [Agentic AI Foundation](https://agents.md/)). `install.sh` symlinks it into each tool's expected location so I never maintain rules in more than one place. Nothing in this repo hardcodes machine-specific details — `bin/agent-env` discovers those at runtime so the same files work on any host.

## Install

```sh
git clone https://github.com/elleryfamilia/agent-config ~/_git/agent-config
cd ~/_git/agent-config
./install.sh --dry-run    # preview
./install.sh              # do it
```

The installer is idempotent. Re-run it any time. Existing non-symlink files at target paths are backed up to `*.bak.<timestamp>` before being replaced.

## What it wires up

| Tool | Path it reads | Handled by |
|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` | symlink |
| Codex | `~/.codex/AGENTS.md` | symlink |
| OpenCode | `~/.config/opencode/AGENTS.md` | symlink |
| Gemini CLI | `~/.gemini/GEMINI.md` | symlink |
| GitHub Copilot (JetBrains plugin) | `~/.config/github-copilot/global-copilot-instructions.md` | symlink |
| Convenience entry point | `~/AGENTS.md` | symlink |
| `agent-env` discovery script | `~/.local/bin/agent-env` | symlink |

## Tools the installer can't fully automate

- **Cursor** — global "User Rules" live in Cursor's settings DB, not on disk. After install, open Cursor → Settings → Rules and paste the contents of `AGENTS.md`. (Project-level `AGENTS.md` files at repo root work natively.)
- **GitHub Copilot CLI** — reads `AGENTS.md` from directories listed in `COPILOT_CUSTOM_INSTRUCTIONS_DIRS`. Add to your shell rc:
  ```sh
  export COPILOT_CUSTOM_INSTRUCTIONS_DIRS="$HOME"
  ```
  Then Copilot CLI picks up `~/AGENTS.md` (which is symlinked to this repo).
- **GitHub Copilot in VS Code** — VS Code's Copilot plugin doesn't reliably honor a global instructions file on disk; it uses Settings Sync instead. The repo-level `AGENTS.md` and `.github/copilot-instructions.md` are still respected per project.

## `agent-env`

A small shell script that probes the current machine and prints a markdown snapshot — host identity, Tailscale peers (if installed), Docker/Podman containers, systemd services on Linux, and detected toolchain versions. The agent runs this on demand when it needs ground truth about the environment.

Safe to run anywhere. Every probe is gated on tool availability; absent tools are skipped silently. Add it to PATH (the installer drops a symlink in `~/.local/bin/`) and invoke it directly:

```sh
agent-env
```

## Uninstall

```sh
./install.sh --uninstall
```

Removes only symlinks that point at this repo. Files backed up during install (`*.bak.<timestamp>`) are left in place — restore them by hand if you want the prior state.

## Customizing for yourself

If you fork or copy this repo, the only file you need to edit is `AGENTS.md`. Tweak the bullets to match how you work. `bin/agent-env` is environment-agnostic by design — extend the probes if you want extra context (`brew services`, listening ports, k8s contexts, etc.), but keep them gated on tool availability so it remains portable.

## Why a dedicated repo (and not dotfiles)

Agent rules and shell config have different audiences: dotfiles are for *your* machines, agent rules are for *any* AI tool a friend might use. Keeping them in a single-purpose repo means others can adopt this without taking my whole dotfiles ecosystem along.
