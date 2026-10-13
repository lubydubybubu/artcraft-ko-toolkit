#!/bin/bash
# Isolated Rust + zig toolchain for cross-building ArtCraft apps to x86_64-pc-windows-gnu on Linux.
# Usage: TOOLS=/abs/dir ./setup.sh   (nothing is written outside $TOOLS)
set -euo pipefail
TOOLS=${TOOLS:?set TOOLS to an absolute directory}
RUST=${RUST:-1.95.0}; ZIGV=${ZIGV:-0.17.0}
mkdir -p "$TOOLS"; cd "$TOOLS"
export CARGO_HOME=$TOOLS/cargo RUSTUP_HOME=$TOOLS/rustup
if [ ! -x cargo/bin/cargo ]; then
  curl -fsSLo rustup-init https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init
  chmod +x rustup-init; ./rustup-init -y --no-modify-path --profile minimal --default-toolchain "$RUST"; rm rustup-init
fi
cargo/bin/rustup target add x86_64-pc-windows-gnu
if [ ! -x zig/zig ]; then
  curl -fsSLo zig.tar.xz "https://ziglang.org/download/$ZIGV/zig-x86_64-linux-$ZIGV.tar.xz"
  sha256sum zig.tar.xz; mkdir zig; tar -xf zig.tar.xz -C zig --strip-components=1; rm zig.tar.xz
fi
# dlltool must be on PATH WITHOUT the cc wrappers (host proc-macros would otherwise link with them)
HERE=$(cd "$(dirname "$0")" && pwd)
mkdir -p wintools; ln -sf "$HERE/wincc/dlltool" wintools/x86_64-w64-mingw32-dlltool
echo "ready: TOOLS=$TOOLS"
