# MCP/connector detection, setup, and manual-guide fallback

The format skill 2 (Athene build) uses once a stack decision (`docs/stack-decision-process.md`)
identifies a connector/MCP need — per the design doc's "MCP/connector setup" section. **Not yet
wired into any skill:** `athene`, the skill this feeds, doesn't exist in this repo yet. Same
pattern as `docs/stack-decision-process.md` and `docs/governance-doc-set-mapping.md` before they
were wired into Audit.

## Detection, per platform

Read the agent's own config, don't ask first — only fall back to asking the user when detection
is genuinely inconclusive (a malformed file, an ambiguous name match), not as a default first
step.

### Claude Code

Confirmed against Claude Code's own MCP docs (`code.claude.com/docs/en/mcp`).

| Scope | File | Key |
|---|---|---|
| Project (shared) | `.mcp.json` at project root | top-level `mcpServers` |
| User (all projects) | `~/.claude.json` | top-level `mcpServers` |
| Local (default, this project only) | `~/.claude.json` | `projects["<absolute project path>"].mcpServers` |

**Check for `managed-mcp.json` first, before anything else.** It's a system-level file an
organization admin deploys (not project- or user-scoped), at a fixed OS path:

| Platform | Path |
|---|---|
| macOS | `/Library/Application Support/ClaudeCode/managed-mcp.json` |
| Linux/WSL | `/etc/claude-code/managed-mcp.json` |
| Windows | `C:\Program Files\ClaudeCode\managed-mcp.json` |

If this file can be read and parsed, it has **exclusive control**: Claude Code loads only the
servers it defines, plus `managedMcpServers` (below), in-process servers the launching app
registers (e.g. an IDE extension's own server), and specific built-ins (Claude in Chrome) when
explicitly allowed — every other user-added or plugin-provided server is blocked, and
`claude mcp add` is rejected outright with `Cannot add MCP server: enterprise MCP configuration
is active and has exclusive control over MCP servers`. **If this file is readable and parseable,
stop — don't attempt auto-setup at all**, regardless of what the project/user/local scopes below
say. Tell the user their organization controls MCP servers centrally and point them to their
admin, don't try `claude mcp add` and fail, or worse, silently report "missing" for a server the
org already provides or blocks on purpose.

If the path exists but the file can't be read or fails to parse, that's **Inconclusive**, not
exclusive control — a stale-but-valid file still activates the hard stop above, but a broken one
shouldn't block setup on a false premise.

Separately, `managedMcpServers` (organization-provided, additive — doesn't take exclusive
control the way `managed-mcp.json` does) ranks above Local/Project/User when present but doesn't
block adding other servers the way `managed-mcp.json` does. **Requires Claude Code v2.1.259 or
later** — an earlier client ignores the key entirely, so don't treat an entry there as effective
without confirming the Claude Code version in use.

Precedence (once `managed-mcp.json`'s exclusive-control case above doesn't apply):
`managedMcpServers` → **Local → Project → User** → plugin-provided → claude.ai connectors. The
whole entry from the highest-precedence source wins; fields don't merge across scopes. Duplicate
matching isn't uniform across sources, though — don't assume name-matching applies everywhere:
Local/Project/User/`managedMcpServers` are matched **by name**, but plugin-provided and
claude.ai-connector entries are matched **by endpoint** (same URL or command counts as a
duplicate even under a different name; a different endpoint under the same name is not a
duplicate and both can load).

Detection below only covers the three **file-backed** scopes (Local, Project, User) — a server
provided only by `managedMcpServers`, a plugin, or a claude.ai connector isn't visible to a file
scan, and this method can't see it.

**Present:** the needed server name exists in any of the three file-backed scopes above.
**Missing:** it exists in none of those three files. This is **not** proof no server exists at
all — `managedMcpServers`, a plugin, or a claude.ai connector could still provide it (and
`managed-mcp.json`, checked separately above, could mean "missing" here is moot anyway). Don't
claim "missing" with full
confidence or attempt setup that would create a duplicate; if a file-scan "missing" result
matters for a setup decision, confirm the effective server list inside a live session (`/mcp`)
before acting, not from the file scan alone.
**Inconclusive:** `.mcp.json` or `~/.claude.json` exists but fails to parse as JSON, or the
server name is ambiguous (e.g. matches a different provider under a similar name) — ask the user
in this case, not before.

### Codex CLI

Community-sourced (Tembo, policylayer, mcp.directory) — not confirmed against OpenAI's own docs;
verify against the current Codex docs before relying on exact field names.

| Scope | File |
|---|---|
| User | `~/.codex/config.toml` (`%USERPROFILE%\.codex\config.toml` on Windows) |
| Project (trusted projects only) | `.codex/config.toml` |

Format: TOML, one table per server: `[mcp_servers.<name>]` — `mcp_servers` itself is snake_case,
but `<name>` is whatever the server was actually added as (e.g. `openaiDeveloperDocs` in OpenAI's
own example is camelCase); match the exact table key, don't force-lowercase or re-case it when
looking for a match. Each table has `command`/`args` for a local process, or `url` for a remote
server. Secrets via `env_vars`/`bearer_token_env_var`,
not hardcoded into the file. Precedence: CLI flags → project config → profile → user config.

**Present/missing:** same logic as Claude Code, applied to this file's tables.
**Inconclusive:** invalid TOML syntax, or an untrusted project (Codex won't load its
`.codex/config.toml` at all in that case) — don't report "missing" when the real reason is
"can't be read here"; surface that distinction to the user instead of guessing.

### Cursor

Community-sourced (morphllm, octavehq, mcpplaygroundonline) — paths for the global scope
conflict across sources on Windows specifically; verify on the actual machine rather than
trusting one guide.

| Scope | File |
|---|---|
| Project | `.cursor/mcp.json` in the workspace root |
| Global | `~/.cursor/mcp.json` (reported Windows locations conflict — confirm locally, don't assume) |

Format: JSON, top-level `mcpServers` key, same shape as Claude Code's project file. Project
scope wins over global on a name collision.

**Inconclusive, specifically for Cursor:** when the global-scope path can't be confirmed for the
current OS/install, say so rather than asserting a location that might be wrong.

## Setup path — what v1 actually covers

Don't imply universal auto-setup. v1 covers exactly:
- **Claude Code and Codex:** both have a documented CLI add command, but the syntax differs —
  don't apply Claude Code's flags to Codex or vice versa:
  - Claude Code remote: `claude mcp add --transport http <name> <url>` (no `--` needed — no
    local command to separate from).
  - Claude Code stdio: `claude mcp add --transport stdio <name> -- <command> [args...]` — the
    `--` is required; it's what stops the server's own flags (e.g. `--port`) from being parsed
    as Claude Code's own options.
  - Codex: no `--transport` flag at all — the form implies the transport. Stdio:
    `codex mcp add <name> -- <command> [args...]`. Remote: `codex mcp add <name> --url <url>`
    (add `--oauth-client-id`/`--oauth-client-secret` if the server needs OAuth).
  Use whichever form matches the server's actual command/URL from the stack decision, rather
  than hand-editing the config file. **Claude Code specifically:** check `managed-mcp.json`
  first (see above) — only skip `claude mcp add` and point the user to their admin when that
  file is confirmed readable and parseable; if it exists but can't be read/parsed, that's
  Inconclusive, not exclusive control — report it and ask the user before acting, don't block
  setup on a file you couldn't actually verify.
- **Cursor:** no confirmed CLI add command across the sources checked — treat Cursor setup as
  manual-guide only for v1, not AI-configurable. Don't claim auto-setup capability that isn't
  verified.

If a connector isn't one of the above (not AI-setupable for the detected platform), go straight
to the manual guide below — don't attempt a config edit that hasn't been verified to work.

## Manual-guide fallback

A real guide, not a vague pointer. Minimum content:
1. The exact file path for the platform and scope being configured (from the tables above).
2. The exact JSON/TOML snippet to add, with the server's actual name/command/URL filled in —
   not a placeholder the user has to figure out themselves.
3. How to verify it worked (e.g. Claude Code: `/mcp` in a session; Codex: `codex mcp list`;
   Cursor: Output panel → MCP Logs).

Hand this to the user directly in the conversation — don't just say "see the docs."
