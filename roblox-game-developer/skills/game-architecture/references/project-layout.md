# Reference Project Layout

A layout that scales from a small game to a team project. Adapt names to the existing project; never force a rename on an established codebase.

## Folder tree (Rojo)

```
my-game/
├── default.project.json
├── rokit.toml               # pinned toolchain (rojo, wally, selene, stylua, lune, luau-lsp)
├── wally.toml               # packages (optional)
├── selene.toml
├── stylua.toml
└── src/
    ├── server/              # -> ServerScriptService.Server
    │   ├── Main.server.luau
    │   └── Services/
    │       ├── PlayerDataService.luau
    │       ├── CombatService.luau
    │       └── ShopService.luau
    ├── client/              # -> StarterPlayer.StarterPlayerScripts.Client
    │   ├── Main.client.luau
    │   └── Controllers/
    │       ├── InputController.luau
    │       └── HudController.luau
    ├── shared/              # -> ReplicatedStorage.Shared
    │   ├── Config/
    │   │   └── Items.luau
    │   ├── Types.luau
    │   ├── Net.luau          # remote definitions
    │   └── Util/
    └── server-storage/      # -> ServerStorage.Assets (optional, models usually stay in .rbxm)
```

File suffixes Rojo understands: `.server.luau` -> `Script`, `.client.luau` -> `LocalScript`, `.luau` -> `ModuleScript`. A folder with `init.luau` becomes a ModuleScript whose children are the other files. Confirm against the Rojo docs for the pinned Rojo version (https://rojo.space/docs).

## default.project.json

```json
{
  "name": "my-game",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "Shared": { "$path": "src/shared" },
      "Packages": { "$path": "Packages" }
    },
    "ServerScriptService": {
      "Server": { "$path": "src/server" }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "Client": { "$path": "src/client" }
      }
    }
  }
}
```

Only include `Packages` when Wally is used. Server-only packages go under `ServerScriptService` (Wally `[server-dependencies]` -> `ServerPackages`).

## Naming conventions

- Services (server): `XService`. Controllers (client): `XController`. Pure shared modules: noun names (`Items`, `Types`, `Signal`).
- Remotes: `PascalCase` verbs describing intent, for example `RequestPurchase`, `RequestEquip`; server-to-client pushes as events, for example `InventoryChanged`.
- Attributes: `PascalCase`, documented in the owning service.
- Tags (CollectionService): `PascalCase` nouns, for example `KillBrick`, `Collectible`, one owning system per tag.

## Studio-only projects

Mirror the same structure as Instances: `ServerScriptService.Server.Services`, `StarterPlayerScripts.Client.Controllers`, `ReplicatedStorage.Shared`. The bootstrap and module patterns are identical.
