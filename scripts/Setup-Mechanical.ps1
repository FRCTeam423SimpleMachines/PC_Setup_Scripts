#Requires -RunAsAdministrator
<#
    .SYNOPSIS
    Mechanical/CAD team setup: OnShape shortcut + any CAM software listed in
    config\mechanical.yaml.
#>

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'common\Install-Helpers.ps1')

Write-Log 'Starting Mechanical/CAD team setup...'

# --- Install team software -----------------------------------------------------
$config = Get-YamlConfig -Path (Join-Path $repoRoot 'config\mechanical.yaml')
if (-not $config.apps -or $config.apps.Count -eq 0) {
    Write-Log -Level WARN -Message 'No apps listed in mechanical.yaml yet (CAM software still TBD).'
} else {
    foreach ($app in $config.apps) {
        Install-WingetApp -Id $app.id -Name $app.name
    }
}

# --- Reference shortcuts --------------------------------------------------------
New-DesktopShortcutsForScope -ShortcutsYamlPath (Join-Path $repoRoot 'config\shortcuts.yaml') -Scope 'mechanical' -FolderName 'Mechanical'

Write-Log 'Mechanical/CAD setup complete.'
