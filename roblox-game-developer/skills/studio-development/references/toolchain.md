# File-based Roblox Toolchain

Roblox's own "Third-party tools" page (https://create.roblox.com/docs/projects/external-tools) recommends a toolchain manager such as Rokit, with Rojo for sync and Wally for packages. Versions below are examples from that page; always use what the project pins.

## Rokit (toolchain manager)

```toml
# rokit.toml
[tools]
rojo = "rojo-rbx/rojo@7.6.1"
wally = "UpliftGames/wally@0.3.2"
lune = "lune-org/lune@0.10.4"
selene = "Kampfkarren/selene@<pinned>"
stylua = "JohnnyMorganz/StyLua@<pinned>"
luau-lsp = "JohnnyMorganz/luau-lsp@<pinned>"
```

`rokit install` installs every tool. Rokit is a drop-in replacement for projects already using Aftman or Foreman.

## Rojo

- `rojo serve` syncs files into an open Studio session (Studio plugin required).
- `rojo build -o game.rbxl` builds a place file.
- `rojo sourcemap default.project.json -o sourcemap.json` produces the sourcemap luau-lsp needs for `require` resolution.

## Wally

```toml
# wally.toml
[package]
name = "studio/my-game"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"

[dependencies]
# Example: Promise = "evaera/promise@<version>"
```

`wally install` writes `Packages/` (and `ServerPackages/` for server deps). Generate type stubs for packages with `wally-package-types` when using luau-lsp strict analysis. Never invent package names or versions: look them up on the Wally index first. pesde is an alternative package manager; use whichever the project already uses.

## Selene (linter)

```toml
# selene.toml
std = "roblox"
```

Run `selene src`. Respect existing `-- selene: allow(...)` comments.

## StyLua (formatter)

```toml
# stylua.toml
column_width = 120
indent_type = "Tabs"
quote_style = "AutoPreferDouble"
```

Run `stylua --check src` to verify. Only run `stylua src` (rewrite) on files you changed, unless the user approves a full format.

## luau-lsp (type analysis)

```bash
luau-lsp analyze --sourcemap=sourcemap.json --definitions=globalTypes.d.luau src
```

The Roblox definitions file and flags differ by version; read the luau-lsp README for the pinned version rather than guessing flags.

## Lune

Standalone Luau runtime for scripts and pure-logic tests outside Roblox: `lune run script.luau`. It does not emulate the full DataModel.

## CI sketch

1. `rokit install`
2. `wally install` (if used)
3. `rojo sourcemap ...`
4. `stylua --check src`, `selene src`, `luau-lsp analyze ...`
5. Tests via Open Cloud Luau Execution or run-in-roblox (requires secrets configured in CI, never committed).
