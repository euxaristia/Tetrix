# Copy SDL3 DLLs to build directory
$buildDir = ".build\x86_64-unknown-windows-msvc\debug"
if (Test-Path $buildDir) {
    if (Test-Path "SDL3.dll") {
        Copy-Item "SDL3.dll" -Destination "$buildDir\SDL3.dll" -Force
        Write-Host "Copied SDL3.dll to $buildDir"
    }
    if (Test-Path "SDL3_ttf.dll") {
        Copy-Item "SDL3_ttf.dll" -Destination "$buildDir\SDL3_ttf.dll" -Force
        Write-Host "Copied SDL3_ttf.dll to $buildDir"
    }
}

$releaseDir = ".build\x86_64-unknown-windows-msvc\release"
if (Test-Path $releaseDir) {
    if (Test-Path "SDL3.dll") {
        Copy-Item "SDL3.dll" -Destination "$releaseDir\SDL3.dll" -Force
        Write-Host "Copied SDL3.dll to $releaseDir"
    }
    if (Test-Path "SDL3_ttf.dll") {
        Copy-Item "SDL3_ttf.dll" -Destination "$releaseDir\SDL3_ttf.dll" -Force
        Write-Host "Copied SDL3_ttf.dll to $releaseDir"
    }
}
