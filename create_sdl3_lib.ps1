# Script to generate SDL3.lib from SDL3.dll
# Requires Visual Studio with C++ tools installed

$libExe = "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.50.35717\bin\Hostx64\x64\lib.exe"
$dumpbinExe = "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.50.35717\bin\Hostx64\x64\dumpbin.exe"

if (-not (Test-Path $libExe)) {
    Write-Host "Error: lib.exe not found at expected location"
    Write-Host "Please update the path in this script"
    exit 1
}

if (-not (Test-Path $dumpbinExe)) {
    Write-Host "Error: dumpbin.exe not found at expected location"
    Write-Host "Please update the path in this script"
    exit 1
}

if (-not (Test-Path "SDL3.dll")) {
    Write-Host "Error: SDL3.dll not found in current directory"
    exit 1
}

Write-Host "Extracting exports from SDL3.dll..."
& $dumpbinExe /EXPORTS SDL3.dll | Out-File -FilePath "SDL3_exports.txt" -Encoding utf8

Write-Host "Parsing exports and creating SDL3.def file..."

# Create .def file
$defContent = @"
EXPORTS
"@

# Parse dumpbin output to extract function names
$exports = Get-Content "SDL3_exports.txt" | Select-String -Pattern "^\s+\d+\s+[0-9A-F]+\s+[0-9A-F]+\s+(\w+)" | ForEach-Object {
    if ($_.Matches.Groups.Count -gt 1) {
        $_.Matches.Groups[1].Value
    }
} | Where-Object { $_ -and $_ -notmatch "^\d+$" -and $_ -ne "name" }

foreach ($export in $exports) {
    $defContent += "`n    $export"
}

$defContent | Out-File -FilePath "SDL3.def" -Encoding ASCII -NoNewline

Write-Host "Created SDL3.def with $($exports.Count) exports"
Write-Host ""
Write-Host "Generating SDL3.lib..."
& $libExe /DEF:SDL3.def /OUT:SDL3.lib /MACHINE:X64

if (Test-Path "SDL3.lib") {
    Write-Host ""
    Write-Host "Success! SDL3.lib has been created."
    Write-Host "You can now build your project."
} else {
    Write-Host ""
    Write-Host "Error: Failed to create SDL3.lib"
    Write-Host "Check the output above for errors"
}
