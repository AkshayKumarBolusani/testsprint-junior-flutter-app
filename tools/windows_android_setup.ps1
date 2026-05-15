#Requires -Version 5.1
<#
  Configure Windows user env vars for Android SDK + point Flutter at your SDK.
  Run in PowerShell AFTER installing "Android SDK Command-line Tools" from Android Studio SDK Manager.

  Usage (from Flutter Mobile App\testsprint_junior):
    powershell -ExecutionPolicy Bypass -File .\tools\windows_android_setup.ps1

  Optional:
    -SdkPath 'D:\Android\Sdk'

  If your Windows user folder has a space (e.g. ...\Users\JME MEDIA\...), Flutter will reject the
  default Android SDK path. Copy the SDK tree to e.g. C:\Android\Sdk (no spaces), point Android Studio
  at it, then run this script with -SdkPath.
#>

param(
    # Prefer a drive root path like C:\Android\Sdk — spaces in the path break NDK / flutter doctor.
    [string]$SdkPath = ''
)

$ErrorActionPreference = 'Stop'

if (-not $SdkPath.Trim()) {
    $noSpaceSdk = 'C:\Android\Sdk'
    $defaultLocal = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Android\Sdk'
    if (Test-Path -LiteralPath $noSpaceSdk) {
        $SdkPath = $noSpaceSdk
    }
    elseif (Test-Path -LiteralPath $defaultLocal) {
        $SdkPath = $defaultLocal
    }
    else {
        $SdkPath = $noSpaceSdk
    }
}

Write-Host ""
Write-Host "SDK path: $SdkPath" -ForegroundColor Cyan

if ($SdkPath -match '\s') {
    Write-Host ""
    Write-Host "STOP: Flutter and the Android NDK do not support spaces in ANDROID_SDK_ROOT." -ForegroundColor Red
    Write-Host "Your path contains a space (often from a username like `"JME MEDIA`")."
    Write-Host ""
    Write-Host "Fix (pick one):"
    Write-Host "  1. Close Android Studio."
    Write-Host "  2a. Copy everything from:" -ForegroundColor Cyan
    Write-Host "        $SdkPath"
    Write-Host "      To a new folder with NO spaces, e.g.:  C:\Android\Sdk"
    $src = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Android\Sdk'
    Write-Host "      Example (PowerShell; create C:\Android first; run as Admin if access denied):"
    Write-Host "        robocopy `"$src`" `"C:\Android\Sdk`" /E" -ForegroundColor DarkGray
    Write-Host "  2b. Android Studio → Settings → Android SDK → Android SDK Location → set to that folder"
    Write-Host ""
    Write-Host "  Then re-run:"
    Write-Host "    .\tools\windows_android_setup.ps1 -SdkPath C:\Android\Sdk" -ForegroundColor Green
    exit 3
}

if (-not (Test-Path -LiteralPath $SdkPath)) {
    Write-Host "ERROR: That folder does not exist. Fix -SdkPath." -ForegroundColor Red
    exit 1
}

$cmdlineLatestBin = Join-Path $SdkPath 'cmdline-tools\latest\bin'
if (-not (Test-Path -LiteralPath $cmdlineLatestBin)) {
    Write-Host ""
    Write-Host "MISSING: Android SDK Command-line Tools" -ForegroundColor Yellow
    Write-Host "Flutter needs this folder: $cmdlineLatestBin"
    Write-Host ""
    Write-Host "In Android Studio:"
    Write-Host "  Settings | Languages & Frameworks | Android SDK   (or Welcome > More Actions > SDK Manager)"
    Write-Host "  Open the [SDK Tools] tab"
    Write-Host "  Enable: Android SDK Command-line Tools (latest)"
    Write-Host "  Click Apply / OK and wait for the install to finish"
    Write-Host ""
    Write-Host "Then run this script again."
    exit 2
}

$flutterBat = $null
try {
    $cmd = Get-Command flutter.bat -ErrorAction Stop
    $flutterBat = $cmd.Source
}
catch {
    $candidates = @(
        (Join-Path $HOME 'Downloads\flutter_windows_3.41.9-stable\flutter\bin\flutter.bat'),
        'C:\src\flutter\bin\flutter.bat'
    )
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) {
            $flutterBat = $c
            break
        }
    }
}

[Environment]::SetEnvironmentVariable('ANDROID_HOME', $SdkPath, 'User')
[Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', $SdkPath, 'User')
Write-Host "Set ANDROID_HOME and ANDROID_SDK_ROOT (User)." -ForegroundColor Green

$toAdd = @(
    (Join-Path $SdkPath 'platform-tools')
    $cmdlineLatestBin
)
if ($flutterBat -and (Test-Path -LiteralPath $flutterBat)) {
    $flutterBinDir = Split-Path -Parent $flutterBat
    $toAdd = @($flutterBinDir) + $toAdd
}
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$parts = @()
if ($userPath) {
    $parts = $userPath.Split(';') | Where-Object { $_.Trim() -ne '' }
}
foreach ($p in $toAdd) {
    $normP = $p.TrimEnd('\')
    $found = $false
    foreach ($x in $parts) {
        if ($x.TrimEnd('\') -ieq $normP) {
            $found = $true
            break
        }
    }
    if (-not $found) {
        $parts = @($p) + $parts
    }
}
$newPath = ($parts | Select-Object -Unique) -join ';'
[Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
if ($flutterBat -and (Test-Path -LiteralPath $flutterBat)) {
    Write-Host "Updated User PATH (Flutter bin + platform-tools + cmdline-tools)." -ForegroundColor Green
}
else {
    Write-Host 'Updated User PATH (platform-tools + cmdline-tools). Flutter bin not found - add Flutter ...\bin to User PATH or see README.' -ForegroundColor Yellow
}

$env:ANDROID_HOME = $SdkPath
$env:ANDROID_SDK_ROOT = $SdkPath
$env:Path = ($toAdd -join ';') + ';' + $env:Path

Write-Host ""

if (-not $flutterBat -or -not (Test-Path -LiteralPath $flutterBat)) {
    Write-Host "Could not find flutter.bat. Close and reopen the terminal, then run:" -ForegroundColor Yellow
    Write-Host "  flutter config --android-sdk `"$SdkPath`""
    Write-Host "  flutter doctor"
    Write-Host "  flutter doctor --android-licenses"
    exit 0
}

Write-Host "Using Flutter: $flutterBat" -ForegroundColor DarkGray
& $flutterBat config --android-sdk $SdkPath
Write-Host ""
& $flutterBat doctor
Write-Host ""
Write-Host "Next: close this terminal and open a NEW one (or restart Cursor) so User PATH loads." -ForegroundColor Cyan
Write-Host "  flutter doctor" -ForegroundColor Cyan
Write-Host "If licenses are not done yet: flutter doctor --android-licenses" -ForegroundColor DarkGray
