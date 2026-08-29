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
    # Wait for Firefox installation to complete
    $firefoxExe = 'C:\Program Files\Mozilla Firefox\firefox.exe'
    $maxWaitSeconds = 120
    $waited = 0

    Write-Log "Waiting for Firefox installation to complete..."
    while (-not (Test-Path $firefoxExe) -and $waited -lt $maxWaitSeconds) {
        Start-Sleep -Seconds 5
        $waited += 5
    }

    if (Test-Path $firefoxExe) {
        # Close any running Firefox instances so the policy will be picked up on next launch
        Write-Log "Checking for running Firefox processes..."
        $firefoxProcs = Get-Process -Name 'firefox' -ErrorAction SilentlyContinue
        if ($firefoxProcs) {
            Write-Log "Stopping Firefox processes to ensure policy is applied..."
            $firefoxProcs | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
        }

        $distDir = 'C:\Program Files\Mozilla Firefox\distribution'
        if (-not (Test-Path $distDir)) {
            Write-Log "Creating distribution directory: $distDir"
            New-Item -ItemType Directory -Path $distDir -Force | Out-Null
        }

        # Build the policy JSON structure carefully to match Mozilla's format exactly
        $policyJson = @"
{
  "policies": {
    "ExtensionSettings": {
      "$($firefoxPolicy.extensionId)": {
        "installation_mode": "$($firefoxPolicy.installationMode)",
        "install_url": "$($firefoxPolicy.installUrl)"
      }
    }
  }
}
"@

        $policyPath = Join-Path $distDir 'policies.json'
        # Write UTF-8 without BOM (Firefox requires this for JSON parsing)
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($policyPath, $policyJson, $utf8NoBom)

        Write-Log "Wrote Firefox policy to $policyPath (UTF-8 without BOM)"
        Write-Log "Policy content: $policyJson"

        # Verify the file was written
        if (Test-Path $policyPath) {
            Write-Log "Successfully created policies.json for $($firefoxPolicy.extensionId)"
            Write-Output ""
            Write-Output "=== IMPORTANT: Firefox Policy Applied ==="
            Write-Output "uBlock Origin will be installed when you LAUNCH Firefox."
            Write-Output "To verify: Open Firefox and go to about:addons"
            Write-Output "========================================"
            Write-Output ""
        } else {
            Write-Log -Level ERROR -Message "Failed to create policies.json file at $policyPath"
        }
    } else {
        Write-Log -Level WARN -Message "Firefox installation did not complete within $maxWaitSeconds seconds. Skipping policy setup."
    }
} else {
    Write-Log -Level WARN -Message 'No firefoxPolicies section found in base.yaml; skipping uBlock Origin setup.'
}

# --- Copy sub-team scripts + configs to the Desktop for later use -------------
# Mirrors the repo's scripts\ + config\ layout so the copied scripts' relative paths still resolve.
Write-Log "Copying sub-team scripts and configs to $desktopSetupDir"
New-Item -ItemType Directory -Path (Join-Path $desktopSetupDir 'scripts\common') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $desktopSetupDir 'config') -Force | Out-Null

Copy-Item -Path (Join-Path $repoRoot 'scripts\Setup-Programming.ps1') -Destination (Join-Path $desktopSetupDir 'scripts') -Force
Copy-Item -Path (Join-Path $repoRoot 'scripts\Setup-Programming.cmd') -Destination (Join-Path $desktopSetupDir 'scripts') -Force
Copy-Item -Path (Join-Path $repoRoot 'scripts\Setup-Mechanical.ps1') -Destination (Join-Path $desktopSetupDir 'scripts') -Force
Copy-Item -Path (Join-Path $repoRoot 'scripts\Setup-Mechanical.cmd') -Destination (Join-Path $desktopSetupDir 'scripts') -Force
Copy-Item -Path (Join-Path $repoRoot 'scripts\common\Install-Helpers.ps1') -Destination (Join-Path $desktopSetupDir 'scripts\common') -Force
Copy-Item -Path (Join-Path $repoRoot 'config\programming.yaml') -Destination (Join-Path $desktopSetupDir 'config') -Force
Copy-Item -Path (Join-Path $repoRoot 'config\mechanical.yaml') -Destination (Join-Path $desktopSetupDir 'config') -Force
Copy-Item -Path (Join-Path $repoRoot 'config\shortcuts.yaml') -Destination (Join-Path $desktopSetupDir 'config') -Force

Write-Log 'Base setup complete.'
Write-Log "Sub-team scripts are available at $desktopSetupDir\scripts."
Write-Log "Students can double-click Setup-Programming.cmd or Setup-Mechanical.cmd to install team-specific software."
