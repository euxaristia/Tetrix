# Build statically linked release executable with Tenebris obfuscation for Windows
# This is a LOCAL DEVELOPMENT convenience script - CI uses its own inline build process
# You can also run: swift build -c release --static-swift-stdlib
# For symbol stripping: llvm-strip --strip-all .build\x86_64-unknown-windows-msvc\release\Tetrix.exe

Write-Host "Building statically linked release executable..." -ForegroundColor Cyan

# Check if SDL3.lib exists, build it if missing
$sdl3LibPath = Join-Path $PSScriptRoot "SDL3.lib"
if (-not (Test-Path $sdl3LibPath)) {
    Write-Host "SDL3.lib not found. Building SDL3 as a static library..." -ForegroundColor Yellow
    & "$PSScriptRoot\build_sdl3_static.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to build SDL3 static library" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "SDL3.lib found" -ForegroundColor Green
}

# Build release with maximum optimization and static linking
Write-Host "Building release executable..." -ForegroundColor Yellow
# Tenebris obfuscation is automatically applied in release builds (configured in Package.swift)
$buildResult = swift build -c release --static-swift-stdlib 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    $buildResult | Write-Host
    exit 1
}

# Find the executable
$exePath = ".build\x86_64-unknown-windows-msvc\release\Tetrix.exe"
if (-not (Test-Path $exePath)) {
    Write-Host "Error: Executable not found at $exePath" -ForegroundColor Red
    exit 1
}

$fileInfo = Get-Item $exePath
Write-Host "`nBuild successful!" -ForegroundColor Green
Write-Host "  Executable: $exePath" -ForegroundColor Cyan
Write-Host "  Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Cyan
Write-Host "`nNote: For symbol stripping, run: llvm-strip --strip-all $exePath" -ForegroundColor Yellow
Write-Host "  (Symbol stripping is handled automatically in CI)" -ForegroundColor Yellow
