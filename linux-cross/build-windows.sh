#!/bin/bash
# Cross-build ArtCraft packages for Windows x64 from Linux.
# Usage: TOOLS=/abs/dir CRAFT_FONTS_DIR=/abs/craft-fonts ./build-windows.sh /path/to/app-repo pkg [pkg...]
# e.g.  ./build-windows.sh ~/projects/filmcraft-ko filmcraft filmcraft-cli
set -euo pipefail
TOOLS=${TOOLS:?}; : "${CRAFT_FONTS_DIR:?pin craft-fonts to the ref in the app's release.yml}"
REPO=$1; shift
HERE=$(cd "$(dirname "$0")" && pwd)
export ZIG=$TOOLS/zig/zig CARGO_HOME=$TOOLS/cargo RUSTUP_HOME=$TOOLS/rustup
export PATH=$TOOLS/wintools:$TOOLS/cargo/bin:$PATH
export CC_x86_64_pc_windows_gnu=$HERE/wincc/cc CXX_x86_64_pc_windows_gnu=$HERE/wincc/cxx AR_x86_64_pc_windows_gnu=$HERE/wincc/ar
export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER=$HERE/wincc/cc
export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS="-C target-feature=+crt-static ${EXTRA_RUSTFLAGS:-}"
export CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 CRAFT_FONTS_REQUIRED=1
export CARGO_BUILD_JOBS=${CARGO_BUILD_JOBS:-2}
# share one target dir across apps so common crates (egui, wgpu, ...) build once
[ -n "${SHARED_TARGET:-}" ] && export CARGO_TARGET_DIR=$SHARED_TARGET
args=(); for p in "$@"; do args+=(-p "$p"); done
cd "$REPO" && cargo build --release --locked "${args[@]}" --target x86_64-pc-windows-gnu
