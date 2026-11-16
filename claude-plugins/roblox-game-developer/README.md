# roblox-game-developer

A production-oriented Claude Code plugin for Roblox development: Luau, game architecture, Roblox Studio and Rojo workflows, debugging, performance, DataStores, networking, server-client design, anti-exploit security and modular game systems.

It works with **file-based projects** (Rojo, Rokit, Wally, Selene, StyLua, luau-lsp) and with **live Roblox Studio** through the Roblox Studio MCP server when that server is connected. Every component detects which workflow applies before it reads or changes anything.

## Principles built into every component

- Analyze the existing project before modifying it.
- Never invent Roblox API methods or properties: verify uncertain APIs against the official reference (or a read-only Studio probe) and flag anything unverified.
- Server-side validation and server authority over all important state.
- Clean, modular, typed (`--!strict`) Luau; no unnecessary scripts or duplicated systems.
- Explain important architectural decisions.
- Never overwrite important project files (project configs, toolchain files, place files, existing scripts) without permission.
- Test and validate whenever possible, and say clearly when something was not executed.

## Components

### Knowledge skills (load automatically by topic)

| Skill | Covers |
|---|---|
| `luau-programming` | Strict typing, new type solver, modern syntax (interpolation, if-expressions, `const`, attributes), `task` library, buffers, deprecated-API replacements |
| `game-architecture` | Container responsibilities, single entry script per side, authority, multi-place universes, anti-patterns, reference Rojo layout |
| `studio-development` | Workflow detection, Rojo toolchain, Roblox Studio MCP usage, safety rules, testing options |
| `debugging-error-analysis` | Evidence-first debugging process, error classification, common error catalog |
| `performance-optimization` | Profiling workflow, CPU/memory/network/physics/rendering fixes, Parallel Luau, native codegen |
| `datastore-persistence` | Session locking, UpdateAsync, BindToClose, current limits and error codes, receipts, `PlayerDataService` example |
| `remote-networking` | RemoteEvent / UnreliableRemoteEvent / RemoteFunction design, validation, rate limiting, `Net` and `RemoteGuard` examples |
| `server-client-architecture` | Ownership matrix, replication channels, server authority model, network ownership, StreamingEnabled |
| `anti-exploit-security` | Threat model, vulnerability classes, audit checklist and severity rubric |
| `modular-game-systems` | Service/controller contract, `ServiceLoader` two-phase bootstrap, signals, tags, lifetimes, system recipes |

### Commands (user-invoked)

| Command | Does |
|---|---|
| `/roblox-game-developer:analyze-project [path]` | Read-only architecture map: workflow, systems, remotes, persistence, risks |
| `/roblox-game-developer:audit [path] [--security-only \| --performance-only]` | Read-only combined security and performance audit using the reviewer agents |
| `/roblox-game-developer:scaffold-system <Name> [purpose]` | Designs a new modular system, waits for approval, then creates it following project conventions |

### Agents

| Agent | Use for |
|---|---|
| `luau-expert` | Writing, typing, refactoring and modernizing Luau |
| `roblox-systems-architect` | Designing features and restructuring projects; plans first, edits only after approval |
| `roblox-debugging-expert` | Root-cause analysis of errors and unexpected behavior |
| `roblox-performance-engineer` | Measured optimization, Parallel Luau, native codegen |
| `roblox-security-reviewer` | Read-only exploitability review of remotes, economy, purchases and exposure |

Agents do not restrict their tool list so they can use Roblox Studio MCP tools, whose names depend on your MCP configuration. The security reviewer and the audit/analyze commands are instructed to stay read-only.

## Installation

Test locally:

```bash
claude --plugin-dir ./claude-plugins/roblox-game-developer
```

Or add the folder to a local marketplace and install it with `/plugin install`.

## Prerequisites (optional, used when present)

- **File-based**: [Rokit](https://github.com/rojo-rbx/rokit) with Rojo, and optionally Wally, Selene, StyLua, luau-lsp, Lune pinned in `rokit.toml`.
- **Live Studio**: Roblox Studio with the Roblox Studio MCP server connected to Claude Code.
- **DataStores in Studio**: enable "Enable Studio Access to API Services" only on test universes.

No API keys or environment variables are required by the plugin itself.

## Examples included

- `skills/datastore-persistence/examples/PlayerDataService.luau` - session-locked player data with retries, autosave, BindToClose, userIds.
- `skills/remote-networking/examples/Net.luau` - central remote definitions.
- `skills/remote-networking/examples/RemoteGuard.luau` - validators and per-player token-bucket rate limiting.
- `skills/modular-game-systems/examples/ServiceLoader.luau`, `Main.server.luau`, `Main.client.luau` - two-phase bootstrap.

The examples are reference implementations. They have not been executed inside Roblox as part of building this plugin; test them in a Studio test place before production use.

## Sources

Built from the official Roblox Creator Documentation (create.roblox.com: engine reference, data store limits, security tactics, server authority model, Parallel Luau, external tools), the Luau documentation (luau.org), and established community tools (Rojo, Rokit, Wally, ProfileStore, Jest Lua). Limits and beta features change: the skills point to the live pages to re-check before quoting numbers.

## License

MIT
