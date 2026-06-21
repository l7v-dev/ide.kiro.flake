# L7V Git Conventions

## Commit Message Format

```
<type>: <what changed — one thing, present tense>
```

### Allowed types

| Type       | When to use                                      |
|------------|--------------------------------------------------|
| `add`      | New file, function, feature, or dependency       |
| `fix`      | Bug fix, wrong value, broken behavior            |
| `remove`   | Deleted code, file, or dependency                |
| `simplify` | Same behavior, less code or complexity           |

### Rules

- One commit = one thing. If you use "and" → split into two commits.
- No conventional commits (`feat:`, `refactor:`, `chore:` — these are not L7V).
- No ticket numbers, no emojis, no trailing punctuation.
- Present tense, lowercase after the colon.
- Message is documentation — write it like one.

### Examples

```
# ✅ correct
add: fetchSource and runtimeDeps as named let-bindings in flake.nix
add: set -euo pipefail and helper functions to get-hashes.sh
add: gitignore for binary Skill Map directory
fix: wrapGAppsHook → wrapGAppsHook3 for nixpkgs-unstable
remove: hardcoded URL from flake.nix derivation
simplify: flatten buildInputs list into runtimeDeps binding

# ❌ wrong
feat: init Kiro IDE v0.12.333 flake
refactor: restructure flake.nix and get-hashes.sh with L7V conventions
fix: complete dependencies, update package names and resolve GPU library issue
```

## Branch Strategy

- Default branch: `main`
- Push to a new branch, never directly to `main`, unless it is a solo repo with no CI gate.
- Branch names: `<type>/<short-description>` → `add/launcher-script`, `fix/sha256-hash`

## Tag / Version Convention

```
v0.1.0 — works
v0.2.0 — simplified
v1.0.0 — stable (only after used in at least one real project)
```
