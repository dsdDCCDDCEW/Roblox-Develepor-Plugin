---
name: audit
description: Run a combined security and performance audit of a Roblox project or path, using the roblox-security-reviewer and roblox-performance-engineer agents, and return a severity-ranked report. Read-only.
argument-hint: "[path or scope] [--security-only | --performance-only]"
allowed-tools: Read, Grep, Glob, Agent
disable-model-invocation: true
---

# Audit Roblox Project

Audit the scope in `$ARGUMENTS` (whole project when empty) for exploitable vulnerabilities and performance problems. This command is **read-only**: report findings and proposed fixes; do not edit files or the Studio place.

## Steps

1. **Scope**: parse `$ARGUMENTS`. If it contains `--security-only` or `--performance-only`, run only that half. Otherwise run both.
2. **Orient** quickly: detect workflow (Rojo files or Studio MCP), list entry scripts, remotes and DataStore usage. Reuse an existing project map from this conversation if `/roblox-game-developer:analyze-project` already ran.
3. **Dispatch in parallel**:
   - `roblox-security-reviewer` agent with the scope, the list of remotes and handlers found, and the instruction to use the anti-exploit-security skill's audit checklist.
   - `roblox-performance-engineer` agent with the scope and the instruction to perform static analysis (polling loops, per-frame work, leaks, network volume, physics settings) and to say which findings need profiler confirmation.
4. **Verify** each reported finding by reading the cited code before including it. Drop findings that do not hold up; mark uncertain ones as "needs confirmation".
5. **Merge** into one report ranked by severity.

## Report format

```
## Roblox Audit: <scope>
Workflow: <Rojo / Studio> | Files/scripts reviewed: <n>
Summary: Security <c/h/m/l> | Performance <h/m/l>

### Security
#### [CRITICAL] <title>
Location: <file:line or Instance path>
Exploit: ...
Impact: ...
Fix: ...

### Performance
#### [HIGH] <title>
Location: ...
Cost: <measured, or "static estimate">
Fix: ...

### Not covered
<what was out of scope or could not be verified (for example, runtime profiling not performed)>
```

End by asking which findings to fix. Apply fixes only after the user chooses.
