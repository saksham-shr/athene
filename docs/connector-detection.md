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

Precedence when the same server name appears in more than one scope: **Local → Project → User**
→ plugin-provided → claude.ai connectors. The whole entry from the highest-precedence source
wins; fields don't merge across scopes.

**Present:** the needed server name exists in any of these three locations.
**Missing:** it exists nowhere above.
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

Format: TOML, one table per server: `[mcp_servers.<name>]` (snake_case), with `command`/`args`
for a local process or `url` for a remote server. Secrets via `env_vars`/`bearer_token_env_var`,
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
- **Claude Code and Codex:** both have a documented CLI add command (`claude mcp add`,
  `codex mcp add`) that takes a transport type and command/URL — use it when the server's
  command/URL is already known from the stack decision, rather than hand-editing the config file.
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
   Cursor: the Output panel's MCP channel).

Hand this to the user directly in the conversation — don't just say "see the docs."
