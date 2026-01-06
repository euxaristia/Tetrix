# Build SDL3 as a static library for Windows
# This script builds SDL3 from source and creates SDL3.lib in the project root

Write-Host "Building SDL3 as a static library..." -ForegroundColor Cyan

# Check if CMake is available
if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    Write-Host "Error: CMake not found in PATH" -ForegroundColor Red
    Write-Host "Please install CMake or add it to your PATH" -ForegroundColor Yellow
    Write-Host "You can install it via Chocolatey: choco install cmake" -ForegroundColor Yellow
    exit 1
}

# Clone SDL3 source (or use existing if already cloned)
$sdl3Dir = "$env:TEMP\sdl3-build-tetrix"
if (-not (Test-Path $sdl3Dir)) {
    Write-Host "Cloning SDL3 source..." -ForegroundColor Yellow
    git clone --depth 1 https://github.com/libsdl-org/SDL.git $sdl3Dir
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to clone SDL3 source" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "SDL3 source already exists, updating..." -ForegroundColor Yellow
    Push-Location $sdl3Dir
    git pull --depth 1
    Pop-Location
}

# Build SDL3 as static library
$buildDir = Join-Path $sdl3Dir "build"
if (Test-Path $buildDir) {
    Remove-Item $buildDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
Push-Location $buildDir

Write-Host "Configuring CMake for static build..." -ForegroundColor Yellow

# Auto-detect Visual Studio version
$vsGenerator = $null

# Try to find Visual Studio via vswhere (if available)
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) {
    $vswhere = "${env:ProgramFiles}\Microsoft Visual Studio\Installer\vswhere.exe"
}

if (Test-Path $vswhere) {
    Write-Host "Detecting Visual Studio installation..." -ForegroundColor Yellow
    $vsInstallPath = & $vswhere -latest -property installationPath 2>$null
    if ($vsInstallPath -and (Test-Path $vsInstallPath)) {
        # Get the actual version from vswhere
        $vsVersion = & $vswhere -latest -property installationVersion 2>$null
        
        # Map to CMake generator names based on version number
        # VS 2026 = version 18.x, VS 2022 = version 17.x, VS 2019 = version 16.x, VS 2017 = version 15.x
        if ($vsVersion -match "^18\.") {
            $vsGenerator = "Visual Studio 18 2026"
        } elseif ($vsVersion -match "^17\.") {
            $vsGenerator = "Visual Studio 17 2022"
        } elseif ($vsVersion -match "^16\.") {
            $vsGenerator = "Visual Studio 16 2019"
        } elseif ($vsVersion -match "^15\.") {
            $vsGenerator = "Visual Studio 15 2017"
        }
        
        if ($vsGenerator) {
            Write-Host "Found Visual Studio: $vsGenerator ($vsVersion)" -ForegroundColor Green
        } else {
            Write-Host "Warning: Visual Studio version $vsVersion detected but generator name not mapped" -ForegroundColor Yellow
        }
    }
}

# Fallback: Try to test which generators are available via CMake
if (-not $vsGenerator) {
    Write-Host "Testing available CMake generators..." -ForegroundColor Yellow
    $cmakeHelp = cmake --help 2>&1 | Out-String
    # Check for newer versions first
    $vsVersions = @("Visual Studio 18 2026", "Visual Studio 17 2022", "Visual Studio 16 2019", "Visual Studio 15 2017")
    foreach ($version in $vsVersions) {
        if ($cmakeHelp -match [regex]::Escape($version)) {
            # Test if we can actually use this generator
            Write-Host "Testing generator: $version" -ForegroundColor Yellow
            $vsGenerator = $version
            break
        }
    }
}

# Variable to track if we're using Ninja (library location differs)
$usingNinja = $false
$cmakeConfigured = $false

# Try Visual Studio generator first if detected
if ($vsGenerator) {
    Write-Host "Using generator: $vsGenerator" -ForegroundColor Cyan
    # Configure CMake for static build with detected Visual Studio
    cmake .. `
        -DCMAKE_BUILD_TYPE=Release `
        -DSDL_SHARED=OFF `
        -DSDL_STATIC=ON `
        -DSDL_STATIC_PIC=ON `
        -DSDL_TESTS=OFF `
        -DSDL_EXAMPLES=OFF `
        -G $vsGenerator `
        -A x64 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        $cmakeConfigured = $true
        Write-Host "CMake configuration succeeded" -ForegroundColor Green
    } else {
        Write-Host "Visual Studio generator failed, trying alternatives..." -ForegroundColor Yellow
    }
}

# Fallback to Ninja if Visual Studio failed or wasn't found
if (-not $cmakeConfigured) {
    if (Get-Command ninja -ErrorAction SilentlyContinue) {
        Write-Host "Using Ninja generator..." -ForegroundColor Yellow
        $usingNinja = $true
        # Configure CMake for static build with Ninja
        cmake .. `
            -DCMAKE_BUILD_TYPE=Release `
            -DSDL_SHARED=OFF `
            -DSDL_STATIC=ON `
            -DSDL_STATIC_PIC=ON `
            -DSDL_TESTS=OFF `
            -DSDL_EXAMPLES=OFF `
            -G "Ninja" 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            $cmakeConfigured = $true
            Write-Host "CMake configuration with Ninja succeeded" -ForegroundColor Green
        }
    }
}

# If still not configured, provide helpful error message
if (-not $cmakeConfigured) {
    Write-Host "`nError: CMake configuration failed - no suitable build system found" -ForegroundColor Red
    Write-Host "`nTo build SDL3, you need one of the following:" -ForegroundColor Yellow
    Write-Host "`nOption 1: Visual Studio Build Tools (Recommended)" -ForegroundColor Cyan
    Write-Host "  1. Download from: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022" -ForegroundColor White
    Write-Host "  2. Install 'Desktop development with C++' workload" -ForegroundColor White
    Write-Host "  3. Run this script again" -ForegroundColor White
    Write-Host "`nOption 2: Ninja + Clang/MSVC" -ForegroundColor Cyan
    Write-Host "  1. Install Ninja: choco install ninja" -ForegroundColor White
    Write-Host "  2. Ensure you have a C++ compiler (Clang or MSVC) in PATH" -ForegroundColor White
    Write-Host "  3. Run this script again" -ForegroundColor White
    Write-Host "`nOption 3: Use the CI-built SDL3.lib" -ForegroundColor Cyan
    Write-Host "  If you have SDL3.lib from CI, just place it in the project root" -ForegroundColor White
    Write-Host "  The build will use it automatically" -ForegroundColor White
    Pop-Location
    exit 1
}

# Build SDL3
if ($usingNinja) {
    Write-Host "Building SDL3 static library with Ninja..." -ForegroundColor Yellow
    cmake --build . --config Release -j 2>&1 | Out-Null
} else {
    Write-Host "Building SDL3 static library..." -ForegroundColor Yellow
    cmake --build . --config Release -j 2>&1 | Out-Null
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: SDL3 build failed" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Find the static library (location differs between Visual Studio and Ninja)
$libSearchPath = if ($usingNinja) { $buildDir } else { "$buildDir\Release" }
$sdl3Lib = Get-ChildItem -Path $libSearchPath -Filter "SDL3-static.lib" -ErrorAction SilentlyContinue
if (-not $sdl3Lib) {
    $sdl3Lib = Get-ChildItem -Path $libSearchPath -Filter "SDL3.lib" -ErrorAction SilentlyContinue
}
if (-not $sdl3Lib) {
    $sdl3Lib = Get-ChildItem -Path $libSearchPath -Filter "SDL3*.lib" | 
        Where-Object { $_.Name -match "^SDL3" -and $_.Name -notmatch "\.dll\.lib$" } | 
        Select-Object -First 1
}

if ($sdl3Lib) {
    # Copy to project root as SDL3.lib
    $projectRoot = Split-Path -Parent $PSCommandPath
    $targetLib = Join-Path $projectRoot "SDL3.lib"
    Copy-Item $sdl3Lib.FullName $targetLib -Force
    Write-Host "`nSuccessfully built and copied SDL3 static library!" -ForegroundColor Green
    Write-Host "  Library: $targetLib" -ForegroundColor Cyan
    Write-Host "  Size: $([math]::Round((Get-Item $targetLib).Length / 1MB, 2)) MB" -ForegroundColor Cyan
} else {
    Write-Host "Error: SDL3 static library not found after build" -ForegroundColor Red
    Write-Host "Contents of ${libSearchPath}:" -ForegroundColor Yellow
    if (Test-Path $libSearchPath) {
        Get-ChildItem $libSearchPath | ForEach-Object { Write-Host "  $($_.Name)" }
    } else {
        Write-Host "  Directory does not exist"
    }
    Pop-Location
    exit 1
}

# Headers are not copied - using only rewritten headers from Sources/CSDL3/include/SDL3/

Pop-Location

Write-Host "`nSDL3 static library build complete!" -ForegroundColor Green
Write-Host "You can now build Tetrix with: swift build -c release" -ForegroundColor Cyan
