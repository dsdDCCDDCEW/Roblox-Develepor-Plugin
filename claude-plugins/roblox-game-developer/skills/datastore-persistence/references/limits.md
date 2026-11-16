# DataStore Limits and Error Codes

Source: https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits (retrieved 2026-11-16). Re-check before relying on numbers.

## Data limits

| Component | Max characters |
|---|---|
| Data store name | 50 |
| Key name | 50 |
| Scope | 50 |
| Value | 4,194,304 per key |

Values are stored as JSON-encoded strings. Measure with `#HttpService:JSONEncode(value)`. Only JSON-safe data persists: no Instances, functions, metatables, mixed tables, or non-string dictionary keys. Convert `Vector3`/`CFrame`/`Color3` to arrays.

## Metadata limits

| Component | Max characters |
|---|---|
| Metadata key name | 50 |
| Metadata value | 250 |
| All key-value pairs combined | 300 |

## Per-key throughput (rolling 60 s, all servers)

| Type | Limit |
|---|---|
| Read (`GetAsync`, `GetVersionAsync`, `GetVersionAtTimeAsync`, `ListVersionsAsync`, `UpdateAsync`) | 25 MB/min |
| Write (`SetAsync`, `IncrementAsync`, `UpdateAsync`, `RemoveAsync`) | 4 MB/min |

Each request is rounded up to the next KB. Exceeding gives `KeyThrottled`; store-level partition throttling gives `DatastoreThrottled`.

## Storage

`500 MB + 1 MB x lifetime user count`, measured on compressed latest versions. Old versions and deleted keys (within retention) do not count. Stores deleted via Open Cloud `DeleteDataStore` count for 30 days.

## Experience-level request budgets (requests per minute, shared with Open Cloud)

| Type | Standard | Ordered |
|---|---|---|
| Read | 300 + CCU x 40 | 300 + CCU x 40 |
| Write | 300 + CCU x 20 | 300 + CCU x 20 |
| List | 300 + CCU x 2 | 300 + CCU x 2 |
| Remove | 300 + CCU x 40 | 300 + CCU x 40 |

`UpdateAsync` consumes both read and write budgets.

## Server-level default budgets (requests per minute)

| Type | Enum | Standard | Ordered |
|---|---|---|---|
| Read | `StandardRead` / `OrderedRead` | 60 + players x 40 | 60 + players x 40 |
| Write | `StandardWrite` / `OrderedWrite` | 60 + players x 40 | 30 + players x 5 |
| List | `StandardList` / `OrderedList` | 5 + players x 2 | 5 + players x 2 |
| Remove | `StandardRemove` / `OrderedRemove` | 60 + players x 40 | 30 + players x 5 |

Configure with `DataStoreService:SetRateLimitForRequestType()`; inspect with `DataStoreService:GetRequestBudgetForRequestType()`. Studio Run mode uses separate, possibly lower static limits; test rate limits with Team Create/Team Test.

## Queues

Throttled requests queue (Set, Ordered set, Get, Ordered get), 30 requests per queue. When full, requests fail with codes 301-306 (dropped).

## Error codes worth handling explicitly

| Code | Meaning | Handling |
|---|---|---|
| 101 | Key name empty | Programmer error: fix key construction |
| 102 | Key name over 50 characters | Fix key construction |
| 103 | `ValueNotAllowed`: update function returned a disallowed type | Sanitize data; do not retry unchanged |
| 104 | `CantStoreValue`: value did not serialize | Same as 103 |
| 105 | `ValueTooLarge`: serialized value exceeds limit | Shrink data or split by feature |
| 106-107 | OrderedDataStore `GetSortedAsync` argument errors | Fix MinValue/MaxValue/PageSize (1-100) |
| 301-306 | Request dropped, queue full | Back off, reduce request rate |
| 401-402 | DataModel / LuaWebService inaccessible during shutdown | Save earlier in `BindToClose`; cannot be retried after shutdown begins |
| 403 | `StudioAccessToApisNotAllowed` | Enable Studio API access on test universes only |
| 502 | `RequestRejected` by API services | Retry with backoff |
| 501, 503-505 | Internal / possible corruption | Retry later; log key for investigation |
| 509 | `OperationNotAllowed` on Personal RCC | Writes blocked in that environment |
| 511 | `AttributeSizeTooLarge`: metadata too large | Shrink metadata |

Consult the live page for the full table; codes are added over time.

## Versioning and recovery

- DataStores keep versions; `ListVersionsAsync`, `GetVersionAsync`, `GetVersionAtTimeAsync` allow rollback after a bad write or exploit.
- Keep a support tool (admin-only, server-side) that restores a player's key from a version timestamp, with audit logging.

## Right to erasure

Pass `{ userId }` as the user IDs argument on writes so Roblox can associate keys with users. When Roblox sends a right-to-erasure request, remove the user's keys (`RemoveAsync`) in every store holding their data, including backups.
