# Build script for Tetrix that sets up SDL3 environment variables

param(
    [switch]$Release,
    [string]$Configuration = "debug"
)

if ($Release) {
    $Configuration = "release"
}

# Get project root (parent of scripts directory)
$projectRoot = Split-Path -Parent $PSScriptRoot

# Change to project root
Push-Location $projectRoot

# Resolve packages first WITHOUT setting INCLUDE (to avoid breaking manifest compilation)
Write-Host "Resolving packages..." -ForegroundColor Cyan
swift package resolve
$resolveExitCode = $LASTEXITCODE

if ($resolveExitCode -ne 0) {
    Write-Host "Package resolution failed!" -ForegroundColor Red
    exit $resolveExitCode
}

# Now set INCLUDE for the actual build (after manifest is compiled)
$sdl3Source = "$env:TEMP\sdl3-build-tetrix"
$sdl3Include = Join-Path $sdl3Source "include"

if (Test-Path "$sdl3Include\SDL3\SDL.h") {
    Write-Host "Found SDL3 headers at: $sdl3Include" -ForegroundColor Green
    $env:INCLUDE = "$sdl3Include;$env:INCLUDE"
    Write-Host "✅ Set INCLUDE for build phase" -ForegroundColor Green
} else {
    Write-Host "Warning: SDL3 headers not found at $sdl3Include" -ForegroundColor Yellow
    Write-Host "Please build SDL3 first using: .\scripts\build_sdl3_static.ps1" -ForegroundColor Yellow
}

# Note: We don't set LIB here because:
# 1. SDL3.lib will be linked via .linkedLibrary("SDL3") in Package.swift
# 2. Setting LIB can interfere with SwiftPM's manifest compilation which needs Windows SDK libraries
# 3. SwiftPM will find SDL3.lib automatically if it's in the project root or specified paths

$sdl3Lib = Join-Path $projectRoot "SDL3.lib"
if (Test-Path $sdl3Lib) {
    Write-Host "Found SDL3.lib at: $sdl3Lib" -ForegroundColor Green
    Write-Host "Note: SDL3.lib will be linked automatically via Package.swift settings" -ForegroundColor Gray
} else {
    Write-Host "Warning: SDL3.lib not found in project root" -ForegroundColor Yellow
    Write-Host "Please build SDL3 first using: .\scripts\build_sdl3_static.ps1" -ForegroundColor Yellow
}

# Build
# Note: We don't set INCLUDE/LIB to avoid interfering with SwiftPM's SDK detection
Write-Host "`nBuilding Tetrix (configuration: $Configuration)..." -ForegroundColor Cyan

if ($Configuration -eq "release") {
    swift build -c release
    $exitCode = $LASTEXITCODE
} else {
    swift build
    $exitCode = $LASTEXITCODE
}

Pop-Location

if ($exitCode -eq 0) {
    Write-Host "`nBuild succeeded!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nBuild failed!" -ForegroundColor Red
    exit $exitCode
}
