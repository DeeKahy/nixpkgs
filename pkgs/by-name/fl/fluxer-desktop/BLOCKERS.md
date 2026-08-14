# fluxer-desktop source build: WIP, does not build

Status: **blocked**, not submittable. Kept for reference.

## Solved

- `fluxer_desktop` has a `workspace:*` dependency, so the April 2026 approach
  (`fetchFromGitHub` with `rootDir = "fluxer_desktop"`, used in nixpkgs#497870)
  no longer works. Must fetch the whole monorepo.
- Scoping the install with `pnpmWorkspaces = [ "fluxer_desktop" ]` (which becomes
  `pnpm --filter=fluxer_desktop`) keeps it tractable: 615 packages resolved
  instead of 1979 for the full workspace. This must be set BOTH on
  `fetchPnpmDeps` and on the derivation itself, or the FOD and the build phase
  disagree and the build fails with ERR_PNPM_NO_OFFLINE_TARBALL.
- Working pnpmDeps hash: sha256-PPlwVWt9nPNQ3ar+TpuN4MGCpDAir3JJxvNcxWFt/wo=
- pnpm install completes offline in both the FOD and the build phase.

## Blocked on

`pnpm build` runs `scripts/build.mjs`, whose `build()` does:

    ensureBuildChannelFile();   // cargo run --manifest-path ../tools/ci/Cargo.toml
    buildNativeAddons();        // builds 22 napi modules, Rust
    buildMain(); buildPreload();

1. `ensureBuildChannelFile()` is **codegen**, not a side effect. It generates
   `src/common/BuildChannel.tsx`. Patching the call out fails later with
   `Cannot read file: src/common/BuildChannel.tsx` from
   `src/common/DesktopIdentity.ts`. So cargo is load-bearing.
2. `buildNativeAddons()` builds 22 local `file:./native/*` napi modules, also
   Rust. There is a `FLUXER_SKIP_NATIVE=true` escape hatch, but skipping them
   drops webrtc-sender, screen capture, input hooks, portals and notifications,
   i.e. the voice/video features. A crippled build is not worth submitting.

## What finishing it requires

- Vendor the workspace Cargo.lock (581 crates) with `rustPlatform.fetchCargoVendor`
  and make cargo available offline in the build.
- Build the 22 napi modules, or generate `BuildChannel.tsx` by hand and accept a
  degraded package (not recommended).
- Combine pnpm + cargo vendoring + electron-builder in one derivation.

This is the "somewhat more complicated build requirements" that led @niklaskorz
to close nixpkgs#497870.
