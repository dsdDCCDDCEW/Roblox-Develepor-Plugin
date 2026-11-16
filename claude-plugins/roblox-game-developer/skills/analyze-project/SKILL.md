---
name: analyze-project
description: Map a Roblox project's architecture (workflow, containers, entry scripts, systems, remotes, DataStores, frameworks, risks) before making changes. Read-only.
argument-hint: "[path or focus area, e.g. src/server or combat]"
allowed-tools: Read, Grep, Glob, Bash(rojo sourcemap:*), Bash(ls:*), Bash(git status:*), Bash(git log:*)
disable-model-invocation: true
---

# Analyze Roblox Project

Produce an accurate map of the Roblox project at `$ARGUMENTS` (or the whole project when empty) so later changes fit what exists. This command is **read-only**: do not edit, create, delete or format any file, and do not modify the Studio place.

## Steps

1. **Detect workflow** (see the studio-development skill):
   - Look for `*.project.json`, `rokit.toml`/`aftman.toml`/`foreman.toml`, `wally.toml`/`pesde.toml`, `selene.toml`, `stylua.toml`, `.luaurc`, CI configs.
   - Check whether Roblox Studio MCP tools are available; if so, call `get_studio_state` and use `search_game_tree` to read the live hierarchy.
2. **Map containers to code**: from the Rojo project tree, or from the Studio hierarchy. List entry scripts (`*.server.luau`, `*.client.luau`, `Script`/`LocalScript` instances) and their `RunContext` if set.
3. **Inventory systems**: each ModuleScript service/controller, its responsibility, and what it requires. Identify the bootstrap pattern (single entry, many scripts, framework such as Knit, ECS).
4. **Inventory networking**: every remote (Grep `RemoteEvent|UnreliableRemoteEvent|RemoteFunction|OnServerEvent|OnServerInvoke|FireServer|InvokeServer`), where it is created, who listens, and whether arguments are validated.
5. **Inventory persistence**: DataStore names (`GetDataStore`, `GetOrderedDataStore`), wrapper libraries (ProfileStore, ProfileService, DataStore2), `BindToClose`, `ProcessReceipt`.
6. **Dependencies**: Wally/pesde packages and vendored libraries with versions.
7. **Quality signals**: type mode headers (`--!strict` coverage), deprecated APIs (`wait(`, `spawn(`, `delay(`, `tick()`), `_G`/`shared` use, duplicated systems.
8. **Risks**: server logic or secrets in replicated containers, unvalidated remotes, missing session locking, polling loops. Flag only; deeper review belongs to `/roblox-game-developer:audit`.

## Output

```
## Project Map: <name>
Workflow: <Rojo / Studio-only / both>; tools: <pinned versions>
Bootstrap: <pattern>

### Containers
| Container | Contents | Notes |

### Systems
| System | Side | Responsibility | Depends on |

### Remotes
| Remote | Type | Direction | Handler | Validated? |

### Persistence
<stores, wrapper, save triggers>

### Risks and observations
- <severity> <finding> (<file:line>)

### Recommended next steps
1. ...
```

Cite `file:line` (or Instance path) for every claim. Mark anything inferred rather than read as "(inferred)".
