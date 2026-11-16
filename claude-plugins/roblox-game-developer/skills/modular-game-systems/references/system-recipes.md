# System Recipes

Outlines, not drop-in code. Each lists state ownership, public API, remotes and the validation the server must perform. Adapt to the existing project.

## Inventory

- **State (server)**: `data.Inventory: { [itemId]: count }` in PlayerDataService; equipped item per player in memory.
- **API**: `InventoryService.add(player, id, n)`, `remove(player, id, n) -> boolean`, `has(player, id, n) -> boolean`, `equip(player, id)`.
- **Remotes**: `RequestEquip(itemId)` client to server; `InventoryChanged(inventory)` server to client (only to the owner).
- **Validation**: itemId in config allowlist; player owns it; equip cooldown; rate limit.

## Combat

- **State (server)**: health (Humanoid or attribute), cooldowns per player per ability, last hit times.
- **API**: `CombatService.applyDamage(target, amount, source)`, signal `Died`.
- **Remotes**: `RequestAttack(abilityId, aimDirection: Vector3)`.
- **Validation**: ability owned and off cooldown (server clock), character alive, aim direction is a unit-ish finite Vector3, hit detection done on the server (raycast/overlap from the server-side character position) with latency tolerance. The client never reports "I hit X for Y".
- **Client**: plays animation and effects immediately (optimistic), shows hit markers when the server confirms.

## Round / match

- **State (server)**: state machine `Intermission -> Starting -> InProgress -> Ending`, participants, round end time from `workspace:GetServerTimeNow()`.
- **Replication**: attributes on a `RoundState` folder in ReplicatedStorage: `State`, `EndsAt`. Clients render countdowns locally.
- **Edge cases**: players joining mid-round, leaving mid-round, zero players, server shutdown.

## Quests

- **State (server)**: `data.Quests: { [questId]: { progress: number, claimed: boolean } }`.
- **API**: `QuestService.increment(player, eventName, amount)` called by other services (not by clients), `claim(player, questId)`.
- **Remotes**: `RequestClaimQuest(questId)`.
- **Validation**: quest exists, progress >= goal, not already claimed (atomic check-and-set).

## Shop and developer products

- **State (server)**: price table in a server module; purchases recorded in `data.GrantedPurchases` by `PurchaseId`.
- **Soft currency**: `RequestPurchase(itemId)`; server checks price and balance, then mutates without yielding in between.
- **Robux**: `MarketplaceService:PromptProductPurchase` from the client is fine; granting happens only in the server's `ProcessReceipt` callback, idempotently, returning `PurchaseGranted` only after a successful save.

## Trading (high risk)

- Server-side trade session object holding both offers; both players confirm; server re-validates ownership of every item at commit time; commit is a single non-yielding mutation on both players' data followed by saves. Consider gating with Device Trust and account age.
