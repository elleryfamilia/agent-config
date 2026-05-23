# Communication
- Default to terse: lead with the result and what changed; skip preamble and restating my question.
- For non-trivial decisions, briefly explain the reasoning, tradeoffs, and alternatives considered.

# Tools & stack
- JS/TS projects: use pnpm; prefer TypeScript over plain JS.
- Python projects: use uv for envs/deps and ruff for lint+format; pytest for tests.
- Rust projects: use cargo; lint with clippy and format with rustfmt.
- Go projects: stick to the standard toolchain (`go build`/`test`/`fmt`/`vet`); add golangci-lint for stricter linting.
- Prefer `rg` over grep, `fd` over find, and the `gh` CLI for GitHub operations.
- Deploy on Railway by default.
- Send/receive email via Resend.

# Guardrails

## Never
- Commit or push directly to main/master — always work on a branch.
- Print, log, or commit secrets, credentials, or `.env` files.
- Run destructive or hard-to-reverse actions (`rm -rf`, DB drops, bulk deletes, file overwrites) without confirmation.

## Ask first
- Before modifying files I didn't mention.
- After two failed attempts at the same problem — don't keep retrying blindly.
- Before installing new dependencies, changing schemas, or restructuring directories.

# Git
- Commit at logical checkpoints with clear messages — don't wait to be told.
- Use Conventional Commits (`feat:`, `fix:`, `refactor:`, `docs:`, etc.). Imperative subject ≤72 chars; body explains *why* when non-obvious.

# Environment discovery
- Before reasoning about deployment, networking, host targets, or anything machine-specific, run `agent-env` (installed at `~/.local/bin/agent-env`) and treat its output as ground truth for the current machine and any networked hosts it can see.
- Don't assume environment details. If `agent-env` isn't on PATH or returns nothing relevant, ask before guessing.

# Planning workflow
For non-trivial work, always create a plan before implementation.

Default planning workflow:
1. Use 3 parallel planning agents to explore different approaches.
2. Synthesize them into one candidate plan.
3. Run 1 critic agent against the candidate plan.
4. Revise the plan.
5. Ask Codex CLI to review the final candidate plan with full context before implementation.

Do not use the full workflow for trivial edits, typos, or obvious one-file fixes.

Also skip the full workflow when there's no real design decision to make — when the task is mechanically applying an obvious pattern across N touchpoints (e.g., "add a channel-gated indicator in 4 known places"). Multi-file is not the same as non-trivial. Use file count or LOC as a weak signal only; the real test is whether you'd be synthesizing between meaningfully different approaches, or just picking placements. If the latter, one exploration pass + direct implementation is enough.

A final plan should include: objective, relevant context, approach, assumptions, risks, validation steps, rollback notes, first implementation step.

# Validation
- For any non-trivial change, build the automated harness as part of the work. Match the harness to the change: web UI → Playwright tests for visuals and functionality; API/logic → unit/integration tests; data/scripts → assertions on output.
- If a harness would take significant effort (e.g. complex E2E setup), surface that and ask me to validate manually — don't skip silently.
- Before declaring work done, run the build, tests, and linter and report results honestly. If something failed or was skipped, say so plainly — don't claim success you didn't verify.
