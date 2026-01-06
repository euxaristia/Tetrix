# Build statically linked release executable with Tenebris obfuscation for Windows
# This is a LOCAL DEVELOPMENT convenience script - CI uses its own inline build process
# You can also run: swift build -c release --static-swift-stdlib
# For symbol stripping: llvm-strip --strip-all .build\x86_64-unknown-windows-msvc\release\Tetrix.exe

Write-Host "Building statically linked release executable..." -ForegroundColor Cyan

# Get project root (parent of scripts directory)
$projectRoot = Split-Path -Parent $PSScriptRoot

# Check if SDL3.lib exists, build it if missing
$sdl3LibPath = Join-Path $projectRoot "SDL3.lib"
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
# Change to project root for build
Push-Location $projectRoot
# Tenebris obfuscation is automatically applied in release builds (configured in Package.swift)
$buildResult = swift build -c release --static-swift-stdlib 2>&1
$buildExitCode = $LASTEXITCODE
Pop-Location

if ($buildExitCode -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    $buildResult | Write-Host
    exit 1
}

# Find the executable
$exePath = Join-Path $projectRoot ".build\x86_64-unknown-windows-msvc\release\Tetrix.exe"
if (-not (Test-Path $exePath)) {
    Write-Host "Error: Executable not found at $exePath" -ForegroundColor Red
    exit 1
}

$fileInfo = Get-Item $exePath
Write-Host "`nBuild successful!" -ForegroundColor Green
Write-Host "  Executable: $exePath" -ForegroundColor Cyan
Write-Host "  Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Cyan

# Strip symbols in place using llvm-strip if available
Write-Host "`nStripping symbols with llvm-strip..." -ForegroundColor Yellow
$stripTool = "llvm-strip"
if (Get-Command $stripTool -ErrorAction SilentlyContinue) {
    $beforeSize = $fileInfo.Length
    & $stripTool --strip-all $exePath
    if ($LASTEXITCODE -eq 0) {
        $afterSize = (Get-Item $exePath).Length
        $saved = $beforeSize - $afterSize
        Write-Host "  Symbols stripped successfully" -ForegroundColor Green
        Write-Host "  Size reduction: $([math]::Round($saved / 1KB, 2)) KB" -ForegroundColor Cyan
    } else {
        Write-Host "  Warning: llvm-strip failed (exit code: $LASTEXITCODE)" -ForegroundColor Yellow
    }
} else {
    Write-Host "`nWarning: llvm-strip not found in PATH, trying common locations..." -ForegroundColor Yellow
    # Try common llvm-strip locations
    $possiblePaths = @(
        "$env:ProgramFiles\LLVM\bin\llvm-strip.exe",
        "${env:ProgramFiles(x86)}\LLVM\bin\llvm-strip.exe",
        "$env:LOCALAPPDATA\Programs\Swift\Toolchains\*\usr\bin\llvm-strip.exe"
    )

    $found = $false
    foreach ($pattern in $possiblePaths) {
        $tools = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($tools) {
            $tool = $tools.FullName
            Write-Host "  Found llvm-strip at: $tool" -ForegroundColor Cyan
            $beforeSize = (Get-Item $exePath).Length
            & $tool --strip-all $exePath
            if ($LASTEXITCODE -eq 0) {
                $afterSize = (Get-Item $exePath).Length
                $saved = $beforeSize - $afterSize
                Write-Host "  Symbols stripped successfully" -ForegroundColor Green
                Write-Host "  Size reduction: $([math]::Round($saved / 1KB, 2)) KB" -ForegroundColor Cyan
                $found = $true
                break
            }
        }
    }

    if (-not $found) {
        Write-Host "  Could not find llvm-strip, skipping symbol stripping" -ForegroundColor Yellow
        Write-Host "  Install LLVM tools or add llvm-strip to PATH for symbol stripping" -ForegroundColor Yellow
    }
}

# Final file info
$finalFileInfo = Get-Item $exePath
Write-Host "`nFinal executable:" -ForegroundColor Green
Write-Host "  Path: $exePath" -ForegroundColor Cyan
Write-Host "  Size: $([math]::Round($finalFileInfo.Length / 1MB, 2)) MB" -ForegroundColor Cyan
Write-Host "`n✅ Build complete! Executable is statically linked, obfuscated, and symbol-stripped." -ForegroundColor Green
