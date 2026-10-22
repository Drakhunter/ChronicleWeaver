param(
    [ValidateSet("Package", "Link")]
    [string]$Action = "Package",
    [string]$WowPath = "C:\Program Files (x86)\World of Warcraft",
    [string]$Flavor = "_retail_"
)

$ErrorActionPreference = "Stop"
$AddonName = "ChronicleWeaver"
$Root = $PSScriptRoot
$TocPath = Join-Path $Root "$AddonName.toc"

$Version = "1.2.0"
if (Test-Path $TocPath) {
    $verMatch = Select-String -Path $TocPath -Pattern "^## Version:\s*(.+)$" | Select-Object -First 1
    if ($verMatch) {
        $Version = $verMatch.Matches[0].Groups[1].Value.Trim()
    }
}

if ($Action -eq "Link") {
    $TargetDir = Join-Path $WowPath "$Flavor\Interface\AddOns\$AddonName"
    if (Test-Path $TargetDir) {
        Write-Host "Already exists at: $TargetDir" -ForegroundColor Yellow
    } else {
        New-Item -ItemType SymbolicLink -Path $TargetDir -Target $Root | Out-Null
        Write-Host "Linked $AddonName -> $TargetDir" -ForegroundColor Green
    }
    exit 0
}

# Action == Package
$DistDir = Join-Path $Root "dist"
$StageDir = Join-Path $DistDir $AddonName
$ZipPath = Join-Path $DistDir "$AddonName-$Version.zip"

if (Test-Path $StageDir) { Remove-Item $StageDir -Recurse -Force }
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
New-Item -ItemType Directory -Path $StageDir -Force | Out-Null

# Copy TOC and runtime directories
Copy-Item $TocPath -Destination $StageDir
foreach ($dir in @("Core", "Data", "Engine", "UI")) {
    $srcDir = Join-Path $Root $dir
    if (Test-Path $srcDir) {
        Copy-Item $srcDir -Destination $StageDir -Recurse
    }
}

# Remove legacy/unreferenced files from staged Data & UI
$unreferenced = @(
    "Data\WoWForever_Zones_Dungeons.lua",
    "UI\CodexFrame.lua",
    "UI\Settings.lua",
    "UI\Templates.xml",
    "UI\Theme.lua",
    "UI\Toast.lua"
)
foreach ($rel in $unreferenced) {
    $p = Join-Path $StageDir $rel
    if (Test-Path $p) { Remove-Item $p -Force }
}

# Copy only runtime .tga textures in Media/
$StageMedia = Join-Path $StageDir "Media"
New-Item -ItemType Directory -Path $StageMedia -Force | Out-Null
Get-ChildItem -Path (Join-Path $Root "Media") -Filter "*.tga" -File | ForEach-Object {
    Copy-Item $_.FullName -Destination $StageMedia
}

Compress-Archive -Path $StageDir -DestinationPath $ZipPath -Force
Remove-Item $StageDir -Recurse -Force
Write-Host "Packaged release archive: $ZipPath" -ForegroundColor Green
