# Script to generate SDL3_ttf.lib from SDL3_ttf.dll
# Requires Visual Studio with C++ tools installed

# Try to find Visual Studio's lib.exe and dumpbin.exe
$vsPaths = @(
    "${env:ProgramFiles}\Microsoft Visual Studio\18\Community\VC\Tools\MSVC",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional\VC\Tools\MSVC",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\VC\Tools\MSVC",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional\VC\Tools\MSVC"
)

$libExe = $null
$dumpbinExe = $null

foreach ($vsPath in $vsPaths) {
    if (Test-Path $vsPath) {
        $msvcDirs = Get-ChildItem $vsPath -Directory | Sort-Object Name -Descending | Select-Object -First 1
        if ($msvcDirs) {
            $libPath = Join-Path $msvcDirs.FullName "bin\Hostx64\x64\lib.exe"
            $dumpbinPath = Join-Path $msvcDirs.FullName "bin\Hostx64\x64\dumpbin.exe"
            if (Test-Path $libPath) {
                $libExe = $libPath
            }
            if (Test-Path $dumpbinPath) {
                $dumpbinExe = $dumpbinPath
            }
            if ($libExe -and $dumpbinExe) {
                break
            }
        }
    }
}

if (-not $libExe) {
    Write-Host "Error: lib.exe not found"
    Write-Host "Please install Visual Studio with C++ desktop development tools"
    exit 1
}

if (-not $dumpbinExe) {
    Write-Host "Error: dumpbin.exe not found"
    Write-Host "Please install Visual Studio with C++ desktop development tools"
    exit 1
}

if (-not (Test-Path "SDL3_ttf.dll")) {
    Write-Host "Error: SDL3_ttf.dll not found in current directory"
    Write-Host "Please place SDL3_ttf.dll in: $PWD"
    exit 1
}

Write-Host "Extracting exports from SDL3_ttf.dll..."
& $dumpbinExe /EXPORTS SDL3_ttf.dll | Out-File -FilePath "SDL3_ttf_exports.txt" -Encoding utf8

Write-Host "Parsing exports and creating SDL3_ttf.def file..."

# Create .def file
$defContent = @"
EXPORTS
"@

# Parse dumpbin output to extract function names
$exports = Get-Content "SDL3_ttf_exports.txt" | Select-String -Pattern "^\s+\d+\s+[0-9A-F]+\s+[0-9A-F]+\s+(\w+)" | ForEach-Object {
    if ($_.Matches.Groups.Count -gt 1) {
        $_.Matches.Groups[1].Value
    }
} | Where-Object { $_ -and $_ -notmatch "^\d+$" -and $_ -ne "name" }

foreach ($export in $exports) {
    $defContent += "`n    $export"
}

$defContent | Out-File -FilePath "SDL3_ttf.def" -Encoding ASCII -NoNewline

Write-Host "Created SDL3_ttf.def with $($exports.Count) exports"
Write-Host ""
Write-Host "Generating SDL3_ttf.lib..."
& $libExe /DEF:SDL3_ttf.def /OUT:SDL3_ttf.lib /MACHINE:X64

if (Test-Path "SDL3_ttf.lib") {
    Write-Host ""
    Write-Host "Success! SDL3_ttf.lib has been created."
    Write-Host "You can now build your project with text rendering support."
} else {
    Write-Host ""
    Write-Host "Error: Failed to create SDL3_ttf.lib"
    Write-Host "Check the output above for errors"
}
