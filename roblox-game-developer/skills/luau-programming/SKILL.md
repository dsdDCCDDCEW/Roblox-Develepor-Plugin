---
name: luau-programming
description: This skill should be used when the user asks to "write Luau", "add types to this script", "use --!strict", "fix a type error", "write a generic function", "use type functions", "convert Lua to Luau", "make this module typed", or asks about Luau syntax (string interpolation, if-expressions, generalized iteration, const, attributes like @native), the task library, buffers, or the Luau standard library in a Roblox context.
version: 1.0.0
---

# Advanced Luau Programming

Write idiomatic, typed, maintainable Luau for Roblox. Luau is Roblox's Lua 5.1-derived language with gradual typing, extra syntax, a sandboxed standard library and native code generation.

## Ground rules

1. **Never invent API.** Use only Luau globals, library functions and Roblox members that are documented. When unsure whether something exists, check before writing it:
   - Luau language: `https://luau.org/` (syntax, typecheck, library pages).
   - Roblox engine: `https://create.roblox.com/docs/reference/engine/classes/<ClassName>.md` (markdown endpoint, easiest to read).
   - With the Roblox Studio MCP connected, probe in Edit mode with `execute_luau`, for example `return typeof(buffer.create)`.
   If verification is impossible, say so explicitly in the answer rather than guessing.
2. **Analyze before editing.** Read the surrounding module, its callers, and project conventions (type mode headers, naming, folder layout, formatter config) before changing code. Match existing style.
3. **Prefer the smallest correct change.** Do not add scripts, wrappers or abstractions the task does not need.

## Type mode

- Start new modules with `--!strict`. Use `--!nonstrict` only when migrating legacy code incrementally; avoid `--!nocheck` except for generated code.
- The **new type solver** is generally released in Roblox Studio (Studio beta removed January 2026). Write code that typechecks under it: precise refinements, `unknown` instead of `any` where callers must refine, and user-defined **type functions** only when a plain generic cannot express the type.
- Type exports: `export type Inventory = { [string]: number }`. Consumers access it as `Module.Inventory` after `local Module = require(path)`.

## Syntax that matters (all documented on luau.org)

| Feature | Form | Note |
|---|---|---|
| String interpolation | `` `Hello {player.Name}` `` | Prefer over `..` chains and `string.format` for readability |
| If-expression | `local x = if cond then a else b` | Replaces `cond and a or b` (which breaks when `a` is falsy) |
| Generalized iteration | `for k, v in t do` | Prefer over `pairs`/`ipairs` in new code; respects `__iter` |
| Compound assignment | `n += 1`, `s ..= "x"` | Evaluates the left side once |
| `continue` | inside loops | Contextual keyword |
| Floor division | `a // b` | |
| `const` bindings | `const MAX = 10` | Prevents rebinding; does not freeze tables (use `table.freeze`). Confirm the target toolchain (StyLua, Selene, luau-lsp versions) supports it before introducing it in a codebase |
| Function attributes | `@native function f() end`, `@deprecated function f() end` | `@native` opts one function into native codegen; whole-script `--!native` exists too |

## Typing patterns

- Annotate module boundaries (parameters, return types, exported tables). Let inference handle locals.
- Model state with tagged unions plus refinement:
  ```lua
  type Result<T> = { ok: true, value: T } | { ok: false, err: string }
  ```
- Classes: use the metatable pattern with an explicit type, see `references/type-system.md` for a strict-safe class template.
- Use `typeof(x) == "Instance" and x:IsA("BasePart")` to refine Roblox values; `typeof` (not `type`) distinguishes Roblox datatypes such as `Vector3`, `CFrame`, `EnumItem`.
- Cast with `::` only when the type system cannot prove a fact you have verified; leave a comment saying why.

## Concurrency: the task library

- `task.spawn(fn, ...)` runs immediately in a new thread; `task.defer` runs at the end of the current resumption cycle; `task.delay(t, fn)` schedules; `task.wait(t)` yields; `task.cancel(thread)` stops a scheduled or suspended thread.
- Never use the deprecated globals `wait`, `spawn`, `delay`. Replace them on contact.
- `coroutine.resume` returns errors as values, which are easy to drop silently. Prefer `task.spawn` for fire-and-forget work so errors reach the output with a traceback.
- Parallel Luau (`task.desynchronize`/`task.synchronize`, `Actor`, `SharedTable`, `ConnectParallel`) is covered in the performance-optimization skill.

## Error handling

- Wrap every yielding network or service call that can fail (DataStores, `HttpService`, `MarketplaceService`, `TeleportService`, `MessagingService`) in `pcall`. Use `xpcall(fn, debug.traceback)` when the traceback matters.
- Do not wrap pure logic in `pcall` to hide bugs. Let programmer errors surface.
- Use `error(msg, 2)` in validation helpers so the reported line is the caller's.

## Data and memory

- `table.clone` (shallow), `table.freeze`/`table.isfrozen` for constants, `table.create(n, v)` to preallocate, `table.clear` to reuse.
- `buffer` library for compact binary data (networking payloads, serialization). Buffers replicate through remotes.
- Disconnect `RBXScriptConnection`s and destroy Instances you create; leaked connections are the most common memory leak. Instance `:Destroy()` disconnects that instance's own connections.

## Style

- Services at the top: `local Players = game:GetService("Players")`.
- `PascalCase` for modules, classes, types and Roblox-facing members; `camelCase` for locals and functions; `SCREAMING_SNAKE_CASE` for constants. Follow the project's existing convention if it differs.
- One responsibility per ModuleScript. Return a single table or class.
- Run the project's formatter and linter when present (StyLua, Selene, luau-lsp). Do not reformat untouched code.

## Additional resources

- **`references/type-system.md`** - strict-safe class template, generics, refinements, type functions, common type-error fixes.
- **`references/stdlib-cheatsheet.md`** - Luau standard library and Roblox globals quick reference with deprecated-to-modern replacements.
