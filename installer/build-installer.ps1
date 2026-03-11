$ErrorActionPreference = 'Stop'

Set-Location (Split-Path -Parent $PSScriptRoot)

flutter build windows --release

$candidates = @(
    "C:\Users\hp\Tools\Inno Setup 6\ISCC.exe",
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe"
)

$inno = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $inno) {
    throw "Inno Setup compiler not found in expected locations."
}

& $inno "installer\FocusTrack.iss"
Write-Host "Installer built at installer\dist\FocusTrack-Setup-1.1.1.exe"
