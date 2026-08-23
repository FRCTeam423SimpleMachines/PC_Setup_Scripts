<#
    Shared helper functions dot-sourced by every FRC setup script.
#>

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')][string]$Level = 'INFO'
    )

    $logDir = 'C:\FRC_Setup_Logs'
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        'WARN' { Write-Warning $Message }
        'ERROR' { Write-Error $Message -ErrorAction Continue }
        default { Write-Information -MessageData $line -InformationAction Continue }
    }

    Add-Content -Path (Join-Path $logDir 'setup.log') -Value $line
}

function Test-WingetAvailable {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Log -Level ERROR -Message 'winget was not found. Install "App Installer" from the Microsoft Store, then re-run this script.'
        return $false
    }
    return $true
}

function Install-WingetApp {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name
    )

    if (-not (Test-WingetAvailable)) { return }
    if (-not $PSCmdlet.ShouldProcess($Name, 'winget install')) { return }

    Write-Log "Installing $Name ($Id)..."
    try {
        winget install --id $Id -e --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Log "$Name installed successfully."
        } else {
            # Non-zero can mean "already installed" -- don't treat as fatal.
            Write-Log -Level WARN -Message "winget exited with code $LASTEXITCODE while installing $Name."
        }
    } catch {
        Write-Log -Level ERROR -Message "Failed to install $Name : $_"
    }
}

function Initialize-PowerShellYaml {
    if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
        Write-Log 'Installing powershell-yaml module...'
        Install-Module -Name powershell-yaml -Scope CurrentUser -Force -Repository PSGallery
    }
    Import-Module powershell-yaml -ErrorAction Stop
}

function Get-YamlConfig {
    param([Parameter(Mandatory)][string]$Path)

    Initialize-PowerShellYaml
    if (-not (Test-Path $Path)) {
        throw "Config file not found: $Path"
    }
    return Get-Content -Path $Path -Raw | ConvertFrom-Yaml
}

function New-DesktopShortcut {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Url,
        [string]$FolderName
    )

    $baseDesktop = Join-Path $env:USERPROFILE 'Desktop'
    $targetDir = if ($FolderName) { Join-Path $baseDesktop "FRC_Setup\$FolderName" } else { $baseDesktop }

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    $safeName = ($Name -replace '[\\/:*?"<>|]', '')
    $shortcutPath = Join-Path $targetDir "$safeName.url"

    if (-not $PSCmdlet.ShouldProcess($shortcutPath, 'Create shortcut')) { return }
    "[InternetShortcut]`r`nURL=$Url`r`n" | Set-Content -Path $shortcutPath -Encoding ASCII

    Write-Log "Created shortcut '$Name' -> $shortcutPath"
}

function New-DesktopShortcutsForScope {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$ShortcutsYamlPath,
        [Parameter(Mandatory)][string]$Scope,
        [string]$FolderName
    )

    $config = Get-YamlConfig -Path $ShortcutsYamlPath
    $matchingEntries = $config.shortcuts | Where-Object { $_.scope -eq $Scope }
    foreach ($entry in $matchingEntries) {
        New-DesktopShortcut -Name $entry.name -Url $entry.url -FolderName $FolderName
    }
}
