param(
    [string]$PluginSource = "narrrail-plugin",
    [string]$HostProject = "narr-rail-host-project",
    [string]$LinkRelative = "addons/narrrail"
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$SourcePath = Join-Path $RepoRoot $PluginSource
$HostPath = Join-Path $RepoRoot $HostProject
$LinkPath = Join-Path $HostPath $LinkRelative
$AddonsDir = Split-Path -Parent $LinkPath

Write-Host "[NarrRail] RepoRoot: $RepoRoot"
Write-Host "[NarrRail] Source : $SourcePath"
Write-Host "[NarrRail] Link   : $LinkPath"

if (-not (Test-Path $SourcePath)) {
    throw "Plugin source directory not found: $SourcePath`nCreate it first and include plugin files (at least plugin.cfg)."
}

if (-not (Test-Path $HostPath)) {
    throw "Host project directory not found: $HostPath"
}

if (-not (Test-Path $AddonsDir)) {
    New-Item -ItemType Directory -Path $AddonsDir | Out-Null
}

if (Test-Path $LinkPath) {
    $item = Get-Item $LinkPath -Force
    if ($item.LinkType -eq "Junction" -or $item.LinkType -eq "SymbolicLink") {
        Write-Host "[NarrRail] Existing link found, removing: $LinkPath"
        Remove-Item $LinkPath -Force
    }
    else {
        throw "Target path exists and is not a link: $LinkPath`nBackup/remove it manually, then rerun this script."
    }
}

# Prefer PowerShell native junction creation for better compatibility.
New-Item -ItemType Junction -Path $LinkPath -Target $SourcePath | Out-Null

if (-not (Test-Path $LinkPath)) {
    throw "Failed to create junction at: $LinkPath"
}

if (-not (Test-Path (Join-Path $LinkPath "plugin.cfg"))) {
    Write-Warning "Junction created, but plugin.cfg was not found at: $LinkPath\plugin.cfg"
    Write-Warning "Verify your plugin root structure."
}
else {
    Write-Host "[NarrRail] Junction created successfully. You can now enable the plugin in Godot."
}
