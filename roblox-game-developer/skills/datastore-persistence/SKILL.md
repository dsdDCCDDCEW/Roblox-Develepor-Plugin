---
name: datastore-persistence
description: This skill should be used when the user asks to "save player data", "use DataStoreService", "set up a DataStore", "prevent data loss", "session locking", "data is not saving", "use ProfileStore", "migrate player data", "build a leaderboard with OrderedDataStore", "use MemoryStoreService", "GDPR data deletion", or mentions UpdateAsync, SetAsync, GetAsync, BindToClose, DataStore limits or throttling.
version: 1.0.0
---

# DataStore and Data Persistence

Persist player and game data without loss, duplication or throttling. Data bugs destroy player trust and are expensive to repair, so treat every change here as high-risk and review it carefully.

## Core rules

1. **Server only.** DataStoreService is inaccessible from clients. Keep all persistence in one server-side service.
2. **One key per player** holding one table (`"u_" .. userId`). Do not spread one player's data across many keys or stores; it multiplies request cost and breaks atomicity.
3. **Use `UpdateAsync`, not `SetAsync`, for player data.** `UpdateAsync` reads and writes atomically and lets the transform reject stale writes. The transform function must not yield and may run more than once.
4. **Session-lock** player data so two servers never write the same profile (player rejoins fast, teleports, server hangs). Either use a proven library (ProfileStore by loleris, MadStudioRoblox) or implement the lock pattern in `examples/PlayerDataService.luau`.
5. **Retry with backoff** inside `pcall`. A failed write does not guarantee the write did not happen; re-read without cache when certainty matters.
6. **Save on leave, on interval, and on shutdown.** `Players.PlayerRemoving`, an autosave loop (60 to 300 s), and `game:BindToClose` that waits for all pending saves. The server allows only a limited time in `BindToClose` (documented as 30 seconds), so start saves in parallel.
7. **Never trust client data for persistence.** The server computes every value written.
8. **Version the schema** (`SchemaVersion` field) and migrate on load, never in place across the whole store.
9. **Pass `userIds`** when writing player data (`SetAsync`/`UpdateAsync` return value) to support right-to-erasure requests.
10. **Do not pre-compress** data; data stores compress automatically and storage is measured on the compressed size.

## Current limits (verified on create.roblox.com, November 2026)

| Limit | Value |
|---|---|
| Key name, store name, scope | 50 characters each |
| Value size | 4,194,304 characters per key |
| Per-key throughput | Read 25 MB/min, Write 4 MB/min (rounded up per request to the next KB) |
| Experience storage | 500 MB + 1 MB x lifetime users (latest versions, compressed) |
| Experience read / write budget (standard) | 300 + concurrentUsers x 40 / 300 + concurrentUsers x 20 per minute, shared with Open Cloud |
| Server default read / write budget (standard) | 60 + numPlayers x 40 per minute each, configurable with `SetRateLimitForRequestType` |
| Queue | 30 requests per queue; overflow fails with codes 301-306 |

Limits change. Re-check `https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits.md` before quoting numbers in production decisions. Details and error codes: `references/limits.md`.

## Choosing a storage service

| Need | Service |
|---|---|
| Durable per-player progress | DataStore (via session-locked wrapper) |
| Global leaderboard | `OrderedDataStore` (integers only), refreshed periodically, never per frame |
| Fast cross-server state that may expire (matchmaking queues, live server lists, short-lived trades) | `MemoryStoreService` (`SortedMap`, `Queue`, `HashMap`) |
| Cross-server notifications | `MessagingService` (best effort, may fail; never the only copy of data) |
| Purchases | `MarketplaceService.ProcessReceipt` with idempotent grant recorded in the player's data before returning `PurchaseGranted` |

## Developer product receipts

`ProcessReceipt` must be idempotent: check whether `receiptInfo.PurchaseId` was already granted (stored in the player's profile), grant, save successfully, then return `Enum.ProductPurchaseDecision.PurchaseGranted`. Return `NotProcessedYet` on any failure so Roblox retries. Only one `ProcessReceipt` callback may be set per server.

## Implementation workflow

1. Search the project for existing persistence (`GetDataStore`, `ProfileStore`, `ProfileService`, `DataStore2`). Extend the existing system rather than adding a second one.
2. Define the data schema as an exported type plus a frozen default table.
3. Implement or reuse the session-locked service. Expose a narrow API (`Get`, `Update(player, fn)`), not raw tables, to other services.
4. Add reconcile-on-load (fill missing fields from defaults) and schema migration.
5. Test in Studio with API access enabled on a **test** universe: join, change data, leave, rejoin; force `BindToClose` by stopping the server; simulate failure by temporarily erroring the save.
6. Report what was tested and what was not.

## Additional resources

- **`examples/PlayerDataService.luau`** - complete session-locked player data service with retries, autosave, BindToClose and userIds.
- **`references/limits.md`** - full limits tables, error code meanings, versioning and metadata notes.
