---
name: studio-development
description: This skill should be used when the user asks to "work in Roblox Studio", "set up Rojo", "sync code with Studio", "use the Roblox Studio MCP", "run a playtest", "read the Studio output", "set up Wally/Selene/StyLua/luau-lsp", "install Rokit", "edit scripts in Studio", or asks how to inspect, modify or test a place file either through Studio directly or through a file-based toolchain.
version: 1.0.0
---

# Roblox Studio Development

Work safely on Roblox projects in either of two modes, and detect which one applies before touching anything.

## Step 1: detect the workflow

| Signal | Mode |
|---|---|
| `default.project.json` or `*.project.json` in the repo | **File-based (Rojo)**. Source of truth is on disk |
| `rokit.toml`, `aftman.toml` or `foreman.toml` | Toolchain manager present; read pinned versions |
| `wally.toml` / `pesde.toml` | Package manager in use |
| Roblox Studio MCP tools available (for example `get_studio_state`, `script_read`, `search_game_tree`, `execute_luau`) | **Live Studio** access is possible |
| Neither | Ask the user how the project is managed before editing |

Both can apply: a Rojo project open in Studio with the MCP connected. In that case **edit files on disk, never the synced scripts in Studio**, because Rojo overwrites Studio edits on the next sync. Use the MCP for inspection, playtesting and reading output only.

## File-based workflow (Rojo)

1. Read `default.project.json` to map files to Instances. Note any `$ignoreUnknownInstances` and non-script `.rbxm`/`.model.json` assets.
2. Read `rokit.toml` for tool versions; prefer the pinned tools (`rokit install` installs them).
3. Edit `.luau` files with the normal Read/Edit tools. Keep Rojo naming suffixes (`.server.luau`, `.client.luau`, `init.luau`).
4. After edits, run whatever the project already uses, in this order when present:
   - `stylua --check src` (format, do not rewrite untouched files without permission)
   - `selene src` (lint)
   - `luau-lsp analyze` with the project's sourcemap (`rojo sourcemap default.project.json -o sourcemap.json`) and Roblox type definitions
   - tests (see "Testing" below)
5. Report the exact commands run and their results. If a tool is missing, say so instead of claiming success.

Toolchain details and configuration examples: `references/toolchain.md`.

## Live Studio workflow (Roblox Studio MCP)

Tool names below are those exposed by Roblox's Studio MCP server; the exact prefix depends on the user's MCP configuration. Check which tools exist in the session before planning.

1. **Orient**: `get_studio_state` (edit vs play mode, open place), `search_game_tree` / `inspect_instance` for structure, `script_search` / `script_grep` / `script_read` for code.
2. **Verify APIs**: in Edit mode, use `execute_luau` for harmless probes such as `return Instance.new("UnreliableRemoteEvent").ClassName` before relying on an uncertain member. Never run code that mutates the place just to test an idea.
3. **Edit**: use `multi_edit` (or the server's script-edit tool) for script changes. Before editing, read the full script and confirm the target is not Rojo-managed. Summarize planned edits to the user first when a change touches more than one script or deletes code.
4. **Test**: `start_stop_play` to run a playtest, `get_console_output` to read errors and prints, `character_navigation` / `user_keyboard_input` / `user_mouse_input` for interaction when available, `screen_capture` to see results. Always stop the playtest afterward.
5. **Save**: only call `save_place` when the user asked to save, or after confirming. Never publish.

## Safety rules (both modes)

- **Analyze before modifying.** Read the relevant scripts, their callers and the container layout first.
- **Never overwrite important files without permission**: `default.project.json`, `rokit.toml`, `wally.toml`, CI configs, `.rbxl`/`.rbxlx` place files, `.rbxm` assets, and any existing script being replaced wholesale. Describe the change and ask.
- **Never delete Instances or scripts** in Studio without explicit confirmation.
- **No duplicate systems.** Search for an existing implementation (`script_grep` or Grep for the feature name, remote name, DataStore name) before creating a new one.
- **Never paste user secrets** (Open Cloud API keys, webhook URLs) into scripts. Use `HttpService:GetSecret()` with Studio/Creator Hub secrets for server-side HTTP secrets, and confirm that API in the reference docs first.

## Testing

- **Unit tests**: Jest Lua (`jsdotlua/jest-lua`) is the most widely used framework; TestEZ is legacy. Tests run inside a Roblox environment (Studio via run-in-roblox, or Open Cloud Luau Execution through community CLIs).
- **Pure-logic tests outside Roblox**: Lune can run Luau scripts that do not depend on the DataModel.
- **Playtest checks**: through the Studio MCP, start a play session, read console output for errors, and stop.
- If none of these are available, provide a manual test checklist and state that the code was not executed.

## Studio features worth recommending

- Script Profiler and MicroProfiler (performance-optimization skill).
- Luau Heap in the Developer Console for memory.
- Team Create with Collaborative Editing for teams; Drafts mode to avoid clobbering.
- Packages for shared assets across places.
- Studio secrets store for `HttpService:GetSecret()`.

## Additional resources

- **`references/toolchain.md`** - Rokit, Rojo, Wally, Selene, StyLua, luau-lsp, Lune setup and config snippets.
