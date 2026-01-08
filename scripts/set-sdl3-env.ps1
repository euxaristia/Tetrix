# Script to set SDL3 environment variables for the current PowerShell session
# Run this before using swift build/swift run
# Usage: . .\scripts\set-sdl3-env.ps1

# Get project root (parent of scripts directory)
$projectRoot = Split-Path -Parent $PSScriptRoot

$sdl3Source = "$env:TEMP\sdl3-build-tetrix"
$sdl3Include = Join-Path $sdl3Source "include"

if (Test-Path "$sdl3Include\SDL3\SDL.h") {
    Write-Host "⚠️  Warning: Cannot set INCLUDE as it breaks SwiftPM manifest compilation on Windows" -ForegroundColor Yellow
    Write-Host "   SDL3 headers found at: $sdl3Include" -ForegroundColor Green
    Write-Host "   But setting INCLUDE will cause 'msvcrt.lib not found' errors" -ForegroundColor Yellow
    Write-Host "   This is a known limitation that needs to be fixed in SwiftSDL" -ForegroundColor Yellow
} else {
    Write-Host "⚠️  SDL3 headers not found at $sdl3Include" -ForegroundColor Yellow
    Write-Host "   Please run: .\scripts\build_sdl3_static.ps1 first" -ForegroundColor Yellow
}

# Note: We don't set LIB here because:
# 1. SDL3.lib will be linked via .linkedLibrary("SDL3") in Package.swift
# 2. Setting LIB can interfere with SwiftPM's manifest compilation
# 3. SwiftPM finds SDL3.lib automatically from the project root

$sdl3Lib = Join-Path $projectRoot "SDL3.lib"
if (Test-Path $sdl3Lib) {
    Write-Host "✅ Found SDL3.lib at: $sdl3Lib" -ForegroundColor Green
    Write-Host "   (Will be linked automatically via Package.swift)" -ForegroundColor Gray
} else {
    Write-Host "⚠️  SDL3.lib not found in project root" -ForegroundColor Yellow
}

Write-Host "`nNow you can run: swift build or swift run" -ForegroundColor Cyan
