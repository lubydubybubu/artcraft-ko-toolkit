param([string]$Repo,[string]$Log,[string]$Pkgs)
$ErrorActionPreference='Continue'; $T="$PSScriptRoot\tools"; $B=$PSScriptRoot
$env:CARGO_HOME="$T\cargo"; $env:RUSTUP_HOME="$T\rustup"; $env:PATH="$T\cargo\bin;$T\llvm-mingw\bin;$env:PATH"
$env:CARGO_TARGET_DIR="$B\target-shared"; $env:CRAFT_FONTS_DIR=$(if($env:CRAFT_FONTS_DIR){$env:CRAFT_FONTS_DIR}else{"$T\craft-fonts"}); $env:CRAFT_FONTS_REQUIRED="1"
$env:CARGO_PROFILE_RELEASE_LTO="false"; $env:CARGO_PROFILE_RELEASE_CODEGEN_UNITS="16"; $env:CARGO_BUILD_JOBS="5"
$env:RUSTFLAGS="-C target-feature=+crt-static"
Set-Location $Repo; $sw=[Diagnostics.Stopwatch]::StartNew()
$a=@('build','--release','--locked'); foreach($p in ($Pkgs -split ',')){$a+='-p';$a+=$p}
$p=Start-Process -FilePath cargo -ArgumentList $a -NoNewWindow -PassThru -RedirectStandardError $Log; try{$p.PriorityClass='BelowNormal'}catch{}; $p.WaitForExit()
"exit=$($p.ExitCode) seconds=$([int]$sw.Elapsed.TotalSeconds)" | Out-File "$Log.done" -Encoding utf8; Get-Content "$Log.done"
