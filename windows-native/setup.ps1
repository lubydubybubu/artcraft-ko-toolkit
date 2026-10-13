$ErrorActionPreference='Continue'; $ProgressPreference='SilentlyContinue'
$T="$PSScriptRoot\tools"; New-Item -ItemType Directory -Force $T | Out-Null; Set-Location $T
$env:CARGO_HOME="$T\cargo"; $env:RUSTUP_HOME="$T\rustup"
if(-not (Test-Path "$T\llvm-mingw")){
  Invoke-WebRequest https://github.com/mstorsjo/llvm-mingw/releases/download/20261006/llvm-mingw-20261006-ucrt-x86_64.zip -OutFile llvm-mingw.zip
  "llvm-mingw sha256 $((Get-FileHash llvm-mingw.zip).Hash)"
  tar -xf llvm-mingw.zip; Rename-Item llvm-mingw-20261006-ucrt-x86_64 llvm-mingw; Remove-Item llvm-mingw.zip }
if(-not (Test-Path "$T\cargo\bin\cargo.exe")){
  Invoke-WebRequest https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe -OutFile rustup-init.exe
  & .\rustup-init.exe -y --no-modify-path --profile minimal --default-host x86_64-pc-windows-gnullvm --default-toolchain 1.95.0 *> "$T\rustup-init.log"; "rustup-init exit=$LASTEXITCODE" }
$env:PATH="$T\cargo\bin;$T\llvm-mingw\bin;$env:PATH"
rustc -vV 2>&1 | Out-String; & x86_64-w64-mingw32-clang --version | Select-Object -First 1
# smoke: hello world with a C dependency-free binary + proc-macro
$s="$T\smoke"; if(Test-Path $s){Remove-Item -Recurse -Force $s}; cargo new -q --vcs none $s; Set-Location $s
cargo build -q *> "$T\smoke.log"; "smoke build exit=$LASTEXITCODE"; & "$s\target\debug\smoke.exe"
"SETUP_DONE"
