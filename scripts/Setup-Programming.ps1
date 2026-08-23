#Requires -RunAsAdministrator
<#
    .SYNOPSIS
    Programming/Electrical team setup: Git, GitHub Desktop, Python, and the
    latest WPILib installer.
#>

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'common\Install-Helpers.ps1')

Write-Log 'Starting Programming/Electrical team setup...'

# --- Install team software -----------------------------------------------------
$config = Get-YamlConfig -Path (Join-Path $repoRoot 'config\programming.yaml')
foreach ($app in $config.apps) {
    Install-WingetApp -Id $app.id -Name $app.name
}

# --- Reference shortcuts --------------------------------------------------------
New-DesktopShortcutsForScope -ShortcutsYamlPath (Join-Path $repoRoot 'config\shortcuts.yaml') -Scope 'programming' -FolderName 'Programming'

# --- WPILib: always fetch the latest release, leave installer for manual run --
Write-Log 'Checking for the latest WPILib release...'
$release = Invoke-RestMethod -Uri $config.wpilib.latestReleaseApiUrl -Headers @{ 'User-Agent' = 'FRC-Laptop-Setup' }

# The Windows download link isn't in the assets array -- it's embedded in the release body.
$isoUrlMatch = [regex]::Match($release.body, 'https://\S+Win64/WPILib_Windows-[\d.]+\.iso')
if (-not $isoUrlMatch.Success) {
    Write-Log -Level ERROR -Message "Could not find a Windows installer link in the latest WPILib release ($($release.tag_name))."
} else {
    $isoUrl = $isoUrlMatch.Value
    $installerDir = Join-Path $env:USERPROFILE 'Desktop\FRC_Setup\WPILibInstaller'
    New-Item -ItemType Directory -Path $installerDir -Force | Out-Null
    $isoPath = Join-Path $installerDir (Split-Path -Leaf $isoUrl)

    Write-Log "Downloading WPILib $($release.tag_name) installer to $isoPath..."
    Invoke-WebRequest -Uri $isoUrl -OutFile $isoPath

    Write-Log "WPILib installer downloaded. Double-click $isoPath to mount it, then run the installer inside (interactive/GUI setup)."
}

Write-Log 'Programming/Electrical setup complete.'
