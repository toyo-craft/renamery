<# 
.SYNOPSIS
    ReNamery バージョンバンプスクリプト
.DESCRIPTION
    pubspec.yaml のバージョンを Semantic Versioning に従って更新し、
    関連ファイルのハードコードされたバージョンも同時に更新します。
.PARAMETER Level
    バンプするレベル: patch, minor, major
.EXAMPLE
    .\scripts\bump_version.ps1 -Level patch   # 0.1.0 → 0.1.1
    .\scripts\bump_version.ps1 -Level minor   # 0.1.0 → 0.2.0
    .\scripts\bump_version.ps1 -Level major   # 0.1.0 → 1.0.0
    .\scripts\bump_version.ps1                # 引数なしは patch
#>
param(
    [ValidateSet("patch", "minor", "major")]
    [string]$Level = "patch"
)

$ErrorActionPreference = "Stop"

# プロジェクトルートの特定
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$PubspecPath = Join-Path $ProjectRoot "pubspec.yaml"

if (-not (Test-Path $PubspecPath)) {
    Write-Error "pubspec.yaml が見つかりません: $PubspecPath"
    exit 1
}

# 現在のバージョンを読み取り
$PubspecContent = Get-Content $PubspecPath -Raw -Encoding UTF8
if ($PubspecContent -match 'version:\s*(\d+)\.(\d+)\.(\d+)') {
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    $patch = [int]$Matches[3]
    $oldVersion = "$major.$minor.$patch"
} else {
    Write-Error "pubspec.yaml から version を読み取れませんでした"
    exit 1
}

# バージョンバンプ
switch ($Level) {
    "major" { $major++; $minor = 0; $patch = 0 }
    "minor" { $minor++; $patch = 0 }
    "patch" { $patch++ }
}
$newVersion = "$major.$minor.$patch"
$newMsixVersion = "$major.$minor.$patch.0"

Write-Host "Version bump: $oldVersion -> $newVersion ($Level)" -ForegroundColor Cyan

# 1. pubspec.yaml を更新
$PubspecContent = $PubspecContent -replace "version:\s*$oldVersion", "version: $newVersion"
$PubspecContent = $PubspecContent -replace "msix_version:\s*[\d.]+", "msix_version: $newMsixVersion"
Set-Content -Path $PubspecPath -Value $PubspecContent -NoNewline -Encoding UTF8

Write-Host "  [OK] pubspec.yaml (version: $newVersion, msix_version: $newMsixVersion)" -ForegroundColor Green

# 2. CHANGELOG.md に日付エントリを追加
$ChangelogPath = Join-Path $ProjectRoot "CHANGELOG.md"
$DateStr = Get-Date -Format "yyyy-MM-dd"

if (Test-Path $ChangelogPath) {
    $ChangelogContent = Get-Content $ChangelogPath -Raw -Encoding UTF8
    $NewEntry = "## [$newVersion] - $DateStr`n`n- `n`n"
    $ChangelogContent = $NewEntry + $ChangelogContent
    Set-Content -Path $ChangelogPath -Value $ChangelogContent -NoNewline -Encoding UTF8
} else {
    $NewEntry = "# Changelog`n`n## [$newVersion] - $DateStr`n`n- `n"
    Set-Content -Path $ChangelogPath -Value $NewEntry -NoNewline -Encoding UTF8
}
Write-Host "  [OK] CHANGELOG.md" -ForegroundColor Green

# 3. 完了メッセージ
Write-Host ""
Write-Host "Done! Version bumped to $newVersion" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. CHANGELOG.md に変更内容を記載してください"
Write-Host "  2. flutter build windows --release"
Write-Host "  3. git commit -am 'v$newVersion'"
Write-Host "  4. git tag v$newVersion"
