# ReNamery Integration Release Script
# Usage: .\scripts\release_all.ps1 -Level <patch|minor|major>

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("patch", "minor", "major")]
    [string]$Level
)

$ErrorActionPreference = "Stop"

# 1. Version Bump
Write-Host "STEP 1: Updating version ($Level)..." -ForegroundColor Cyan
.\scripts\bump_version.ps1 -Level $Level

# Get new version
$pubspec = Get-Content pubspec.yaml
$versionLine = $pubspec | Select-String "^version: "
$version = $versionLine.ToString().Split(":")[1].Trim()
$tag = "v$version"
Write-Host "INFO: New version is $tag" -ForegroundColor Green

# 2. Prepare clean build directory
$tmpDir = "C:\renamery_release_tmp"
Write-Host "STEP 2: Creating clean environment ($tmpDir)..." -ForegroundColor Cyan
if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir }
New-Item -ItemType Directory -Force -Path $tmpDir

# Copy only essential source files (Skip platform folders to avoid symlink issues)
robocopy . $tmpDir /S /XD .git .dart_tool build .idea windows android ios macos linux /R:0 /W:0 /NFL /NDL /NJH /NJS

# 3. Build (inside temp directory)
Push-Location $tmpDir
try {
    Write-Host "STEP 3: Recreating platform projects..." -ForegroundColor Cyan
    flutter create --platforms=windows,android .

    Write-Host "STEP 4: Fetching dependencies..." -ForegroundColor Cyan
    flutter pub get

    # Windows Build
    Write-Host "STEP 5: Building Windows version..." -ForegroundColor Cyan
    flutter build windows --release
    
    $winBin = "build\windows\x64\runner\Release"
    if (Test-Path $winBin) {
        $winDist = "ReNamery_${tag}_Windows.zip"
        Compress-Archive -Path "$winBin\*" -DestinationPath $winDist -Force
        Write-Host "INFO: Windows ZIP created." -ForegroundColor Green
    } else {
        Write-Error "Windows build output not found."
    }

    # Android Build
    Write-Host "STEP 6: Building Android version..." -ForegroundColor Cyan
    flutter build apk --release
    $apkSrc = "build\app\outputs\flutter-apk\app-release.apk"
    if (Test-Path $apkSrc) {
        $apkDist = "ReNamery_${tag}_Android.apk"
        Copy-Item $apkSrc $apkDist
        Write-Host "INFO: Android APK created." -ForegroundColor Green
    } else {
        Write-Error "Android APK not found."
    }
}
finally {
    Pop-Location
}

# 4. Collect artifacts
Write-Host "STEP 7: Collecting artifacts..." -ForegroundColor Cyan
$currentDir = Get-Location
$releaseDir = Join-Path $currentDir "build\releases\$tag"
if (!(Test-Path $releaseDir)) { New-Item -ItemType Directory -Force -Path $releaseDir }
if (Test-Path "$tmpDir\*.zip") { Copy-Item "$tmpDir\*.zip" $releaseDir }
if (Test-Path "$tmpDir\*.apk") { Copy-Item "$tmpDir\*.apk" $releaseDir }

# 5. Git commit and tag
Write-Host "STEP 7: Committing changes and tagging..." -ForegroundColor Cyan
git add .
git commit -m "chore: release $tag"
git tag $tag

# 6. Push to GitHub
Write-Host "STEP 8: Pushing to GitHub (toyo-craft)..." -ForegroundColor Cyan
git push origin main --tags

Write-Host "SUCCESS: Release complete and pushed to GitHub!" -ForegroundColor Green
Write-Host "INFO: Release directory: $releaseDir" -ForegroundColor White
Write-Host "INFO: Linux build will start automatically on GitHub Actions." -ForegroundColor Yellow

