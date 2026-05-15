#!/usr/bin/env pwsh
<#
SYNOPSIS
  Run Flutter CLI when flutter is not on your PATH.

INSTALL
  Official ZIP: https://docs.flutter.dev/get-started/install/windows
  You need: YOUR_FLUTTER_SDK_FOLDER\bin\flutter.bat

USAGE (from Flutter Mobile App\testsprint_junior)
  powershell -ExecutionPolicy Bypass -File .\tools\flutter_wrapper.ps1 doctor

Or set for this session only:
  $env:FLUTTER_ROOT = 'C:\Users\YOURNAME\Downloads\flutter_windows_3.41.9-stable\flutter'

Permanent: add YOUR_FLUTTER_SDK_FOLDER\bin to User PATH (see README).
#>

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs
)

$ErrorActionPreference = "Stop"

# Optional default if you do not use PATH (edit to match your PC)
$FLUTTER_ROOT_DEFAULT = "C:\src\flutter"

$candidates = @(
    $env:FLUTTER_ROOT
    # Official Windows ZIP extracted under Downloads (matches flutter_windows_*-stable\flutter)
    (Join-Path $HOME "Downloads\flutter_windows_3.41.9-stable\flutter")
    $FLUTTER_ROOT_DEFAULT
    (Join-Path $HOME "flutter")
    (Join-Path $HOME "sdk\flutter")
    "D:\flutter"
    "D:\src\flutter"
)

$flutterBat = $null
foreach ($root in ($candidates | Where-Object { $_ -and $_.Trim().Length -gt 0 } | Select-Object -Unique)) {
    $rootTrim = $root.TrimEnd('\')
    $bat = Join-Path $rootTrim "bin\flutter.bat"
    if (Test-Path -LiteralPath $bat) {
        $flutterBat = $bat
        break
    }
}

if (-not $flutterBat) {
    Write-Host ""
    Write-Host "Flutter SDK not found (no bin\flutter.bat in searched locations)." -ForegroundColor Red
    Write-Host ""
    Write-Host "Expected something like:"
    Write-Host "  ...\flutter\bin\flutter.bat"
    Write-Host ""
    Write-Host "Set the folder that CONTAINS bin, then retry, e.g.:"
    Write-Host '  $env:FLUTTER_ROOT = "C:\Users\JME MEDIA\Downloads\flutter_windows_3.41.9-stable\flutter"'
    Write-Host ""
    exit 1
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Write-Host ("Using: " + $flutterBat) -ForegroundColor DarkGray
Write-Host ("Cwd:   " + $projectRoot) -ForegroundColor DarkGray
Write-Host ""

Push-Location $projectRoot
try {
    & $flutterBat @FlutterArgs
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
