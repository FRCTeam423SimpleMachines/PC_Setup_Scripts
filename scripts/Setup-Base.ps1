#Requires -RunAsAdministrator
<#
    .SYNOPSIS
    Base setup for a fresh Windows 11 FRC laptop image.
    Installs common software, configures Firefox, creates reference shortcuts,
    and leaves sub-team scripts on the Desktop for later use.
#>

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'common\Install-Helpers.ps1')

$desktopSetupDir = Join-Path $env:USERPROFILE 'Desktop\FRC_Setup'

Write-Log 'Starting FRC base laptop setup...'

# --- Install common software -------------------------------------------------
$baseConfig = Get-YamlConfig -Path (Join-Path $repoRoot 'config\base.yaml')
foreach ($app in $baseConfig.apps) {
    Install-WingetApp -Id $app.id -Name $app.name
}

# --- Reference shortcuts -------------------------------------------------------
New-DesktopShortcutsForScope -ShortcutsYamlPath (Join-Path $repoRoot 'config\shortcuts.yaml') -Scope 'base'

# --- Firefox: force-install uBlock Origin via Enterprise policy ---------------
$firefoxPolicy = $baseConfig.firefoxPolicies
if ($firefoxPolicy) {
    $distDir = 'C:\Program Files\Mozilla Firefox\distribution'
    if (-not (Test-Path $distDir)) {
        New-Item -ItemType Directory -Path $distDir -Force | Out-Null
    }

    $policy = @{
        policies = @{
            ExtensionSettings = @{
                $firefoxPolicy.extensionId = @{
                    installation_mode = $firefoxPolicy.installationMode
                    install_url       = $firefoxPolicy.installUrl
                }
            }
        }
    }

    $policyPath = Join-Path $distDir 'policies.json'
    $policy | ConvertTo-Json -Depth 6 | Set-Content -Path $policyPath -Encoding UTF8
    Write-Log "Wrote Firefox policy for $($firefoxPolicy.extensionId) to $policyPath"
} else {
    Write-Log -Level WARN -Message 'No firefoxPolicies section found in base.yaml; skipping uBlock Origin setup.'
}

# --- Copy sub-team scripts + configs to the Desktop for later use -------------
# Mirrors the repo's scripts\ + config\ layout so the copied scripts' relative paths still resolve.
Write-Log "Copying sub-team scripts and configs to $desktopSetupDir"
New-Item -ItemType Directory -Path (Join-Path $desktopSetupDir 'scripts\common') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $desktopSetupDir 'config') -Force | Out-Null

Copy-Item -Path (Join-Path $repoRoot 'scripts\Setup-Programming.ps1') -Destination (Join-Path $desktopSetupDir 'scripts') -Force
Copy-Item -Path (Join-Path $repoRoot 'scripts\Setup-Mechanical.ps1') -Destination (Join-Path $desktopSetupDir 'scripts') -Force
Copy-Item -Path (Join-Path $repoRoot 'scripts\common\Install-Helpers.ps1') -Destination (Join-Path $desktopSetupDir 'scripts\common') -Force
Copy-Item -Path (Join-Path $repoRoot 'config\programming.yaml') -Destination (Join-Path $desktopSetupDir 'config') -Force
Copy-Item -Path (Join-Path $repoRoot 'config\mechanical.yaml') -Destination (Join-Path $desktopSetupDir 'config') -Force
Copy-Item -Path (Join-Path $repoRoot 'config\shortcuts.yaml') -Destination (Join-Path $desktopSetupDir 'config') -Force

Write-Log 'Base setup complete.'
Write-Log "Sub-team scripts are available at $desktopSetupDir\scripts. Run Setup-Programming.ps1 or Setup-Mechanical.ps1 from there as needed."
