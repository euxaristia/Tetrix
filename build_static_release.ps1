# Build statically linked release executable with Tenebris obfuscation for Windows

Write-Host "Building statically linked release executable with Tenebris obfuscation..." -ForegroundColor Cyan

# Clean previous build
Write-Host "Cleaning previous build..." -ForegroundColor Yellow
swift package clean

# Build release with maximum optimization and static linking
Write-Host "Building release executable with static linking..." -ForegroundColor Yellow
# Use --static-swift-stdlib to statically link Swift standard library where possible
# Note: Some Swift runtime components may still require dynamic linking on Windows
# Using -c release ensures Tenebris obfuscation is applied (configured in Package.swift)
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

# Get file info before stripping
$fileInfo = Get-Item $exePath
$sizeBeforeMB = [math]::Round($fileInfo.Length / 1MB, 2)

Write-Host "`nBuild successful!" -ForegroundColor Green
Write-Host "  Executable: $exePath" -ForegroundColor Cyan
Write-Host "  Size before stripping: $sizeBeforeMB MB" -ForegroundColor Cyan
Write-Host "`nStatic Linking Status:" -ForegroundColor Cyan
Write-Host "  ✓ Swift Standard Library: Statically linked (--static-swift-stdlib)" -ForegroundColor Green
Write-Host "  ✓ SDL3: Statically linked (SDL3.lib)" -ForegroundColor Green
Write-Host "  ✓ Tenebris: Compile-time obfuscation enabled" -ForegroundColor Green
Write-Host "  ⚠ Note: Some Swift runtime components may still require dynamic DLLs on Windows" -ForegroundColor Yellow
Write-Host "    (BlocksRuntime.dll, Dispatch.dll may still be needed)" -ForegroundColor Yellow

# Strip symbols in place using llvm-strip if available
$stripTool = "llvm-strip"
if (Get-Command $stripTool -ErrorAction SilentlyContinue) {
    Write-Host "`nStripping symbols..." -ForegroundColor Yellow
    & $stripTool --strip-all $exePath
    $strippedInfo = Get-Item $exePath
    $strippedMB = [math]::Round($strippedInfo.Length / 1MB, 2)
    Write-Host "  Size after stripping: $strippedMB MB" -ForegroundColor Cyan
} else {
    Write-Host "`nNote: llvm-strip not found, skipping symbol stripping" -ForegroundColor Yellow
}

Write-Host "`nDone! Static release build complete." -ForegroundColor Green
Write-Host "`nFinal executable location:" -ForegroundColor Cyan
Write-Host "  $exePath" -ForegroundColor White