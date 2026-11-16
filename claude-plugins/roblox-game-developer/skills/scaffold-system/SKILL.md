---
name: scaffold-system
description: Scaffold a new modular Roblox gameplay system (server service, optional client controller, remotes, config) that fits the project's existing structure, after checking for duplicates.
argument-hint: "<SystemName> [short description of what it does]"
allowed-tools: Read, Grep, Glob
disable-model-invocation: true
---

# Scaffold a Roblox System

Create a new system named from the first word of `$ARGUMENTS` (for example `Inventory`), with the remaining text as its purpose. If `$ARGUMENTS` is empty, ask the user for the system name and purpose before doing anything.

## Steps

1. **Analyze first.** Detect the workflow (Rojo files or Studio MCP) and the project's conventions: bootstrap pattern, folder names (`Services`/`Controllers` or others), naming style, type mode, remote definition module, data service. Read one existing service as a style reference.
2. **Check for duplicates.** Grep (or `script_grep` in Studio) for the system name and related terms, remotes, tags and DataStore keys. If a system with the same responsibility exists, stop and propose extending it instead.
3. **Design** using the modular-game-systems, server-client-architecture and remote-networking skills. Present to the user, before writing:
   - Files to create (exact paths) and any existing file to modify (for example adding remotes to `Net`).
   - State ownership, public API, remotes with argument types and validation, persistence needs.
   - Why each decision was made.
4. **Wait for approval.** Do not create or modify files until the user agrees. Never overwrite an existing file; if a target path exists, stop and ask.
5. **Create** the files following the project's conventions:
   - Server service with `init`/`start` (or the project's equivalent), `--!strict`, typed public API.
   - Client controller only if the system has client presentation.
   - Remotes added to the central definition module, handlers wired through the project's validation helper (or `RemoteGuard` from the remote-networking skill if none exists and the user agreed to add it).
   - Config module for tunables.
6. **Validate**: run the project's formatter/linter/type checker if present (`stylua --check`, `selene`, `luau-lsp analyze`). With Studio MCP, optionally start a playtest and read `get_console_output` for load errors, then stop the playtest. Report exact results.
7. **Summarize** created/modified files, how to use the API, and what was not tested.

Writes need tool permission beyond this command's pre-approved read tools; the user approves each write.
