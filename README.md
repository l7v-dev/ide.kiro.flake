# kiro.ide.flake

> Installs [Kiro IDE](https://kiro.dev) on NixOS. Nothing else.

Kiro is an agentic IDE by AWS built on VS Code. Spec-driven development, agent hooks,
steering files, MCP support. Powered by Claude via Amazon Bedrock.

---

## Install

**Option A — run without installing**

```bash
nix run github:l7v-dev/ide.kiro.flake
```

**Option B — add to your NixOS configuration**

```nix
# flake.nix
inputs.kiro.url = "github:l7v-dev/ide.kiro.flake";
```

```nix
# configuration.nix or home.nix
environment.systemPackages = [
  inputs.kiro.packages.${system}.kiro-ide
];
```

**Option C — one-shot profile install**

```bash
nix profile install github:l7v-dev/ide.kiro.flake
```

---

## Update

When a new Kiro version is released, fetch the new version and hash:

```bash
bash get-hashes.sh
```

The script fetches the latest metadata, computes the SRI hash, and optionally
patches `flake.nix` in place. Then commit and push.

---

## What's inside

```
flake.nix       # Nix derivation — downloads, patches, installs Kiro
get-hashes.sh   # Helper — fetches current version + SRI hash from upstream
```

The derivation:
- Downloads the official upstream tarball and verifies its hash
- Patches all ELF binaries via `autoPatchelfHook`
- Wraps the binary with GTK env via `wrapGAppsHook3`
- Installs a `.desktop` entry and a launcher script at `$out/bin/kiro`

---

## Requirements

| Requirement | Detail |
|-------------|--------|
| Platform    | `x86_64-linux` only |
| Nix         | Flakes enabled (`experimental-features = nix-command flakes`) |
| nixpkgs     | `nixos-unstable` |
| License     | Kiro is **unfree** — `allowUnfree = true` is set inside the flake |

---

## Current version

`0.12.333` — update with `bash get-hashes.sh`

---

## Why

NixOS has no official Kiro package. This flake is the smallest correct way to
get Kiro running on NixOS — no overlays, no wrapper scripts beyond what's
necessary, no hidden behavior.

---

> [l7v-dev](https://github.com/l7v-dev) · Simple by design. Composable by nature.
