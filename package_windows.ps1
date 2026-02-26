# ReNamery Packaging Script (Windows)
# This script creates a ZIP package for distribution (e.g., for Vector or self-hosting).

$VERSION = "0.1.0"
$PROJECT_NAME = "renamery"
$STAGING_DIR = "build\windows\dist_staging"
$OUTPUT_ZIP = "renamery_v$($VERSION)_windows.zip"
$RELEASE_DIR = "build\windows\x64\runner\Release"

# 1. Check if release build exists
if (-not (Test-Path $RELEASE_DIR)) {
    Write-Error "Release build not found. Please run 'flutter build windows --release' first."
    exit 1
}

# 2. Cleanup old staging/zip
if (Test-Path $STAGING_DIR) { Remove-Item -Recurse -Force $STAGING_DIR }
if (Test-Path $OUTPUT_ZIP) { Remove-Item -Force $OUTPUT_ZIP }

Write-Host "Creating staging directory..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $STAGING_DIR | Out-Null

# 3. Copy build artifacts
Write-Host "Copying executable and dependencies..."
Copy-Item -Path "$RELEASE_DIR\*" -Destination $STAGING_DIR -Recurse

# 4. Copy and Rename Documentation
Write-Host "Adding README and LICENSE..."
# Convert MD to TXT conceptually (just copying/renaming for user readability in Windows)
Copy-Item -Path "README.md" -Destination "$STAGING_DIR\README.txt"
Copy-Item -Path "LICENSE" -Destination "$STAGING_DIR\LICENSE.txt"

Write-Host "Adding manuals..."
Copy-Item -Path "docs" -Destination "$STAGING_DIR\docs" -Recurse

# 5. Create ZIP
Write-Host "Compressing to $OUTPUT_ZIP..." -ForegroundColor Green
Compress-Archive -Path "$STAGING_DIR\*" -DestinationPath "$OUTPUT_ZIP" -Force

# 6. Final Cleanup
Write-Host "Cleaning up staging directory..."
Remove-Item -Recurse -Force $STAGING_DIR

Write-Host "`nSuccessfully created $OUTPUT_ZIP!" -ForegroundColor Green
Write-Host "You can now upload this file to Vector or your website."
