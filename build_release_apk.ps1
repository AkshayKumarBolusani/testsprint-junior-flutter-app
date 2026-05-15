#Requires -Version 5.1
<#
  Windows: build release APK when your user/project path has SPACES (e.g. "JME MEDIA").
  - Stages a copy to C:\dev\testsprint_junior_build (no spaces)
  - Sets PUB_CACHE to C:\pub-cache for this run + your user env (persistent)
  - Tries Windows 8.3 short paths for flutter.bat / FLUTTER_ROOT when the SDK path has spaces
  - If short paths are unavailable: suggests C:\flutter or a directory junction (mklink /J)
  - Runs: flutter pub get && flutter build apk --release
  - Copies app-release.apk back under this repo's build\...

  Usage (from repo root):
    powershell -ExecutionPolicy Bypass -File .\build_release_apk.ps1

  First-time: creating C:\dev may require an elevated PowerShell once, or create C:\dev manually.
#>
$ErrorActionPreference = 'Stop'

$ProjectRoot = $PSScriptRoot
$StageRoot = 'C:\dev'
$StageDir = Join-Path $StageRoot 'testsprint_junior_build'
$PubCache = 'C:\pub-cache'

function Test-PathHasSpace([string] $p) { return ($null -ne $p) -and ($p.Contains(' ')) }

# Windows 8.3 "short" path (no spaces) — works when NTFS 8.3 names are enabled for the volume.
function Get-Dos8ShortPath {
  param([Parameter(Mandatory)][string] $LiteralPath)
  try {
    if (-not (Test-Path -LiteralPath $LiteralPath)) { return $null }
    $fso = New-Object -ComObject Scripting.FileSystemObject
    if (Test-Path -LiteralPath $LiteralPath -PathType Container) {
      return $fso.GetFolder($LiteralPath).ShortPath
    }
    return $fso.GetFile($LiteralPath).ShortPath
  } catch {
    return $null
  }
}

Write-Host "== TestSprint Junior: staged Android release build ==" -ForegroundColor Cyan
Write-Host "Project (source): $ProjectRoot"

# --- C:\dev (no spaces) ---
try {
  if (-not (Test-Path $StageRoot)) {
    New-Item -ItemType Directory -Force -Path $StageRoot | Out-Null
  }
} catch {
  Write-Host "Could not create $StageRoot. Create it manually or run PowerShell as Administrator once." -ForegroundColor Red
  throw
}
New-Item -ItemType Directory -Force -Path $StageDir | Out-Null
New-Item -ItemType Directory -Force -Path $PubCache | Out-Null

# Persistent PUB_CACHE (user scope) — new terminals pick this up
$existingPub = [System.Environment]::GetEnvironmentVariable('PUB_CACHE', 'User')
if ($existingPub -ne $PubCache) {
  [System.Environment]::SetEnvironmentVariable('PUB_CACHE', $PubCache, 'User')
  Write-Host "Set user PUB_CACHE=$PubCache (restart terminals later so all tools see it)." -ForegroundColor Yellow
}
$env:PUB_CACHE = $PubCache

# --- Sync sources into stage (exclude heavy / regenerable dirs) ---
# Use call operator (&) so paths with spaces are ONE argument each. Start-Process -ArgumentList breaks them.
Write-Host "Staging -> $StageDir ..."
$excludes = @(
  '.dart_tool', 'build',
  'android\.gradle', 'android\app\build', 'android\.cxx',
  '.git'
)
$rcArgs = @(
  $ProjectRoot,
  $StageDir,
  '/E', '/MT:8', '/NFL', '/NDL', '/NJH', '/NJS', '/NP'
)
foreach ($xd in $excludes) {
  $rcArgs += '/XD'
  $rcArgs += $xd
}
& robocopy.exe @rcArgs
$rc = $LASTEXITCODE
if ($rc -ge 8) {
  throw "robocopy failed with exit code $rc"
}

# --- Flutter (prefer 8.3 short paths when SDK lives under "JME MEDIA\...") ---
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
  throw "flutter not found on PATH. Add Flutter\bin, then re-run this script."
}
$flutterBat = $flutterCmd.Source
Write-Host "Flutter on PATH: $flutterBat"

if (Test-PathHasSpace $flutterBat) {
  $shortBat = Get-Dos8ShortPath $flutterBat
  if ($shortBat -and -not (Test-PathHasSpace $shortBat)) {
    $flutterBat = $shortBat
    Write-Host "Using 8.3 short path for flutter.bat: $flutterBat" -ForegroundColor Green
  } else {
    Write-Host ""
    Write-Host "Your Flutter SDK path has spaces and no usable 8.3 short name was returned." -ForegroundColor Red
    Write-Host "Do one of the following, then run this script again:" -ForegroundColor Yellow
    Write-Host "  1) Move/reinstall Flutter to C:\flutter and put C:\flutter\bin on PATH" -ForegroundColor Yellow
    Write-Host "  2) Admin CMD: mklink /J C:\flutter `"<your long flutter SDK folder>`"" -ForegroundColor Yellow
    Write-Host "     then prepend C:\flutter\bin to PATH for this session." -ForegroundColor Yellow
    exit 1
  }
}

# FLUTTER_ROOT must be space-free for child tools; derive SDK root from the *original* PATH entry (long path),
# then prefer its 8.3 short path — not from Resolve-Path(shortBat) which may re-expand to a long path.
$flutterLong = $flutterCmd.Source
$binLong = Split-Path -Parent $flutterLong
$sdkLong = (Resolve-Path (Join-Path $binLong '..')).Path
if (Test-PathHasSpace $sdkLong) {
  $shortRoot = Get-Dos8ShortPath $sdkLong
  if ($shortRoot -and -not (Test-PathHasSpace $shortRoot)) {
    $env:FLUTTER_ROOT = $shortRoot
    Write-Host "FLUTTER_ROOT=$shortRoot" -ForegroundColor Green
  } else {
    Write-Host ""
    Write-Host "Flutter SDK folder has spaces and no usable 8.3 short name: $sdkLong" -ForegroundColor Red
    Write-Host "Do one of the following, then run this script again:" -ForegroundColor Yellow
    Write-Host "  1) Move/reinstall Flutter to C:\flutter and put C:\flutter\bin on PATH" -ForegroundColor Yellow
    Write-Host "  2) Admin CMD: mklink /J C:\flutter `"<your long flutter SDK folder>`"" -ForegroundColor Yellow
    Write-Host "     then prepend C:\flutter\bin to PATH for this session." -ForegroundColor Yellow
    exit 1
  }
}

Push-Location $StageDir
try {
  Write-Host "`nflutter pub get" -ForegroundColor Cyan
  & $flutterBat pub get
  if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed ($LASTEXITCODE)" }

  Write-Host "`nflutter build apk --release" -ForegroundColor Cyan
  & $flutterBat build apk --release
  if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed ($LASTEXITCODE)" }
} finally {
  Pop-Location
}

$built = Join-Path $StageDir 'build\app\outputs\flutter-apk\app-release.apk'
if (Test-Path $built) {
  $destDir = Join-Path $ProjectRoot 'build\app\outputs\flutter-apk'
  New-Item -ItemType Directory -Force -Path $destDir | Out-Null
  $dest = Join-Path $destDir 'app-release.apk'
  Copy-Item -Path $built -Destination $dest -Force
  Write-Host "`nOK: APK copied to:`n  $dest" -ForegroundColor Green
} else {
  Write-Host "`nBuild reported success but APK not found at:`n  $built" -ForegroundColor Yellow
}
