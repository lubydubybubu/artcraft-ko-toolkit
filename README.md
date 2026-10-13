# artcraft-ko-toolkit

Tools used to add a Korean (한국어) interface to the open-source **storytold ArtCraft** apps
(FilmCraft, LightCraft, WordCraft, …) and build unofficial Windows test builds.
This repository holds **tooling only**. Each app's Korean changes live in its own `<app>-ko-patch`
repository as a patch file; upstream ArtCraft source code is never copied here.

## Contents
- `linux-cross/` cross-compile Windows x64 builds on Linux with zig as C compiler/linker
  - `setup.sh` isolated Rust 1.95 + zig 0.17 in `$TOOLS`
  - `build-windows.sh` `cargo build --release --target x86_64-pc-windows-gnu` with the right env
    (`SHARED_TARGET=/dir` shares compiled crates between apps)
  - `wincc/` compiler wrappers. Lessons baked in: `-lgcc_eh` → `-lunwind` (SEH unwind symbols),
    `-lNAME` resolved to `libNAME.a` from `-L` dirs (crate-bundled Windows import libs), msvcrt/mingw/gcc
    and GNU-ld-only flags dropped; `dlltool` lives on PATH *without* the cc wrappers so host proc-macros
    still link with the host compiler.
- `windows-native/` build natively on a Windows PC (no admin, no MSVC): Rust 1.95 `x86_64-pc-windows-gnullvm`
  + llvm-mingw in `tools\`. `setup.ps1` once, then
  `build.ps1 -Repo C:\src\app -Log build.log -Pkgs app,app-cli` (BelowNormal priority, shared target dir
  so later apps reuse egui/wgpu builds). A clean WordCraft release build takes minutes on a desktop CPU
  instead of most of an hour on a small 2-vCPU VM.
- `export-patch.py` export a working tree's changes (tracked + new files) as one patch against the
  upstream tag and prove it applies to a pristine checkout.
- `publish.sh` gitleaks scan → commit → push to a private repo → verify remote SHA.

## Per-app workflow
1. Clone the upstream release tag; reuse an upstream Korean PR if one exists (credit its author).
2. Translate/fix with tests first (RED → GREEN); Korean font coverage checked against all 11,172 syllables.
3. `build-windows.sh` → package → hash-check on the Windows PC.
4. `export-patch.py` → `publish.sh` into `<app>-ko-patch`.

Builds are unofficial and unsigned; official releases use MSVC.
Licence of these scripts: MIT OR Apache-2.0 (same as the ArtCraft apps).
