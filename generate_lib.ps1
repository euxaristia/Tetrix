# PowerShell script to help generate SDL3.lib from SDL3.dll
# This script provides instructions and attempts to generate the import library

Write-Host "Generating SDL3.lib from SDL3.dll..."
Write-Host ""

# Check if SDL3.dll exists
if (-not (Test-Path "SDL3.dll")) {
    Write-Host "Error: SDL3.dll not found in current directory"
    exit 1
}

Write-Host "SDL3.dll found"
Write-Host ""

# Method 1: Try to find Visual Studio's lib.exe
$vsPaths = @(
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional\VC\Tools\MSVC",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\VC\Tools\MSVC",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional\VC\Tools\MSVC"
)

$libExe = $null
foreach ($vsPath in $vsPaths) {
    if (Test-Path $vsPath) {
        $msvcDirs = Get-ChildItem $vsPath -Directory | Sort-Object Name -Descending | Select-Object -First 1
        if ($msvcDirs) {
            $libPath = Join-Path $msvcDirs.FullName "bin\Hostx64\x64\lib.exe"
            if (Test-Path $libPath) {
                $libExe = $libPath
                break
            }
        }
    }
}

if ($libExe) {
    Write-Host "Found lib.exe at: $libExe"
    Write-Host ""
    Write-Host "To generate SDL3.lib, you need to:"
    Write-Host "1. Create a .def file with SDL3 exports (or use dumpbin to extract them)"
    Write-Host "2. Run: `"$libExe`" /DEF:SDL3.def /OUT:SDL3.lib /MACHINE:X64"
    Write-Host ""
    Write-Host "Alternatively, you can download the SDL3 development package which includes the .lib file"
    Write-Host "from: https://github.com/libsdl-org/SDL/releases"
} else {
    Write-Host "Visual Studio lib.exe not found."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "1. Install Visual Studio Build Tools or Visual Studio Community"
    Write-Host "2. Download SDL3 development package from: https://github.com/libsdl-org/SDL/releases"
    Write-Host "3. Use MinGW's dlltool if you have MinGW installed"
    Write-Host ""
    Write-Host "For now, the build will fail at linking. You need SDL3.lib to link successfully."
}
