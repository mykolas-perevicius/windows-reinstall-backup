<#
.SYNOPSIS
    Windows Reinstall Backup Script - Comprehensive user data backup before clean Windows reinstall

.DESCRIPTION
    This script creates a complete backup of user data, configurations, and settings before a Windows reinstall.
    It intelligently copies only safe, necessary files while excluding system files that would break on a fresh install.

.PARAMETER TargetDrive
    The drive letter where the backup will be stored (e.g., 'D', 'E')

.PARAMETER SourceDrive
    The drive letter to backup FROM (default: 'C'). Use this if backing up from a different drive.

.PARAMETER Username
    The Windows username to backup. If not specified, will use current user or prompt.

.PARAMETER ExcludeDownloads
    Skip backing up the Downloads folder

.PARAMETER WhatIf
    Perform a dry run without actually copying files

.PARAMETER Compress
    Compress the backup into a ZIP file after completion

.EXAMPLE
    .\backup.ps1 -TargetDrive D

.EXAMPLE
    .\backup.ps1 -TargetDrive D -WhatIf

.EXAMPLE
    .\backup.ps1 -TargetDrive E -ExcludeDownloads -Compress

.EXAMPLE
    .\backup.ps1 -SourceDrive E -TargetDrive C -Username "OldUser"
    Backup from E: drive (old Windows) to C: drive (new Windows)
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^[A-Z]$')]
    [string]$TargetDrive,

    [Parameter(Mandatory=$false)]
    [ValidatePattern('^[A-Z]$')]
    [string]$SourceDrive = "C",

    [Parameter(Mandatory=$false)]
    [string]$Username,

    [switch]$ExcludeDownloads,

    [switch]$Compress
)

#Requires -RunAsAdministrator

# Script configuration
$ErrorActionPreference = "Continue"
$WarningPreference = "Continue"

# Color output functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Type) {
        "Success" { Write-Host "[$timestamp] [✓] $Message" -ForegroundColor Green }
        "Error"   { Write-Host "[$timestamp] [✗] $Message" -ForegroundColor Red }
        "Warning" { Write-Host "[$timestamp] [!] $Message" -ForegroundColor Yellow }
        "Info"    { Write-Host "[$timestamp] [i] $Message" -ForegroundColor Cyan }
        "Header"  { Write-Host "`n=== $Message ===" -ForegroundColor Magenta }
        default   { Write-Host "[$timestamp] $Message" }
    }
}

# Banner
Clear-Host
Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║        Windows Reinstall Backup Script v1.0                 ║
║        Safe backup of user data and configurations          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-ColorOutput "This script must be run as Administrator!" "Error"
    Write-ColorOutput "Please right-click and select 'Run as Administrator'" "Warning"
    exit 1
}

# Get target drive if not specified
if (-not $TargetDrive) {
    Write-ColorOutput "Available drives:" "Info"
    Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -gt 0 -and $_.Name -ne 'C' } | ForEach-Object {
        $freeGB = [math]::Round($_.Free / 1GB, 2)
        Write-Host "  $($_.Name): - $freeGB GB free" -ForegroundColor White
    }

    do {
        $TargetDrive = (Read-Host "`nEnter target drive letter (e.g., D, E)").ToUpper()
    } while ($TargetDrive -notmatch '^[A-Z]$')
}

# Verify target drive exists
if (-not (Test-Path "$TargetDrive`:\")) {
    Write-ColorOutput "Drive $TargetDrive`: does not exist!" "Error"
    exit 1
}

# Get username if not specified
if (-not $Username) {
    $currentUser = $env:USERNAME
    $response = Read-Host "Backup user profile for '$currentUser'? (Y/n)"
    if ($response -eq '' -or $response -eq 'Y' -or $response -eq 'y') {
        $Username = $currentUser
    } else {
        $Username = Read-Host "Enter username to backup"
    }
}

# Verify source drive exists
if (-not (Test-Path "$SourceDrive`:\")) {
    Write-ColorOutput "Source drive $SourceDrive`: does not exist!" "Error"
    exit 1
}

# Verify user profile exists
$userProfilePath = "$SourceDrive`:\Users\$Username"
if (-not (Test-Path $userProfilePath)) {
    Write-ColorOutput "User profile path does not exist: $userProfilePath" "Error"
    Write-ColorOutput "Make sure the username is correct for drive $SourceDrive`:" "Warning"
    exit 1
}

# Create timestamped backup directory
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupRoot = "$TargetDrive`:\WindowsBackup_$timestamp"

Write-ColorOutput "Backup will be created at: $backupRoot" "Info"

# Check available space
$targetDrive = Get-PSDrive $TargetDrive
$targetFreeGB = [math]::Round($targetDrive.Free / 1GB, 2)

Write-ColorOutput "Available space on $TargetDrive`: $targetFreeGB GB" "Info"

if ($targetFreeGB -lt 10) {
    Write-ColorOutput "Warning: Less than 10GB free space available!" "Warning"
    $response = Read-Host "Continue anyway? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-ColorOutput "Backup cancelled by user" "Warning"
        exit 0
    }
}

# Confirm before proceeding
if (-not $WhatIfPreference) {
    Write-Host "`nBackup Configuration:" -ForegroundColor Yellow
    Write-Host "  Source Drive:      $SourceDrive`: ($userProfilePath)"
    Write-Host "  Target Drive:      $TargetDrive`: ($backupRoot)"
    Write-Host "  Username:          $Username"
    Write-Host "  Exclude Downloads: $ExcludeDownloads"
    Write-Host "  Compress:          $Compress"
    Write-Host ""

    $response = Read-Host "Proceed with backup? (Y/n)"
    if ($response -eq 'n' -or $response -eq 'N') {
        Write-ColorOutput "Backup cancelled by user" "Warning"
        exit 0
    }
}

# Initialize logging
$logFile = "$backupRoot\BackupLog.txt"
$script:totalFilesCopied = 0
$script:totalBytesCopied = 0
$script:errors = @()
$script:skipped = @()
$startTime = Get-Date

function Write-Log {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Type] $Message"

    # Only write to file if not in WhatIf mode
    if (-not $WhatIfPreference) {
        Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    }
}

# Create backup directory structure
Write-ColorOutput "Creating backup directory structure..." "Header"

$directories = @(
    "Projects",
    "Documents",
    "Desktop",
    "Pictures",
    "Videos",
    "Music",
    "Downloads",
    "SSHKeys",
    "GitConfig",
    "VSCodeSettings",
    "TerminalSettings",
    "GameConfigs",
    "AppDataRoaming_Selected",
    "AppDataLocal_Selected",
    "BrowserData",
    "SystemConfig"
)

if ($PSCmdlet.ShouldProcess($backupRoot, "Create directory structure")) {
    try {
        New-Item -Path $backupRoot -ItemType Directory -Force | Out-Null
        foreach ($dir in $directories) {
            New-Item -Path "$backupRoot\$dir" -ItemType Directory -Force | Out-Null
        }
        Write-ColorOutput "Directory structure created successfully" "Success"
        Write-Log "Backup directory structure created at $backupRoot"
    } catch {
        Write-ColorOutput "Failed to create directory structure: $_" "Error"
        exit 1
    }
}

# Helper function for robocopy with progress
function Invoke-BackupCopy {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Description,
        [string[]]$ExcludeDirs = @(),
        [string[]]$ExcludeFiles = @(),
        [switch]$SkipIfNotExist
    )

    if (-not (Test-Path $Source)) {
        if ($SkipIfNotExist) {
            Write-ColorOutput "Skipping $Description (source not found)" "Warning"
            Write-Log "Skipped $Description - source not found: $Source" "WARNING"
            $script:skipped += $Description
            return
        } else {
            Write-ColorOutput "Source not found: $Source" "Error"
            Write-Log "ERROR: Source not found: $Source" "ERROR"
            $script:errors += "Source not found: $Source"
            return
        }
    }

    Write-ColorOutput "Backing up: $Description" "Info"
    Write-Log "Starting backup: $Description from $Source to $Destination"

    if ($WhatIfPreference) {
        Write-Host "  [WhatIf] Would copy: $Source -> $Destination" -ForegroundColor DarkGray
        return
    }

    # Build robocopy command
    $robocopyArgs = @(
        $Source,
        $Destination,
        "/E",           # Copy subdirectories, including empty ones
        "/Z",           # Copy files in restartable mode
        "/R:3",         # Retry 3 times on failed copies
        "/W:5",         # Wait 5 seconds between retries
        "/MT:8",        # Multi-threaded (8 threads)
        "/NP",          # No progress percentage
        "/NDL",         # No directory list
        "/NFL",         # No file list (reduces log size)
        "/TEE",         # Output to console and log
        "/LOG+:$backupRoot\robocopy_log.txt"
    )

    # Add exclusions
    if ($ExcludeDirs.Count -gt 0) {
        $robocopyArgs += "/XD"
        $robocopyArgs += $ExcludeDirs
    }

    if ($ExcludeFiles.Count -gt 0) {
        $robocopyArgs += "/XF"
        $robocopyArgs += $ExcludeFiles
    }

    try {
        $result = & robocopy @robocopyArgs

        # Robocopy exit codes: 0-7 are success, 8+ are errors
        $exitCode = $LASTEXITCODE

        if ($exitCode -lt 8) {
            Write-ColorOutput "✓ Completed: $Description" "Success"
            Write-Log "Successfully backed up: $Description" "SUCCESS"
            $script:totalFilesCopied++
        } else {
            Write-ColorOutput "Warning: Some files may not have been copied for $Description (Exit code: $exitCode)" "Warning"
            Write-Log "Partial backup: $Description (Exit code: $exitCode)" "WARNING"
            $script:errors += "Partial backup of $Description (Exit code: $exitCode)"
        }
    } catch {
        Write-ColorOutput "Error backing up $Description`: $_" "Error"
        Write-Log "ERROR backing up $Description`: $_" "ERROR"
        $script:errors += "Failed to backup $Description`: $_"
    }
}

# Backup user folders
Write-ColorOutput "Backing up user folders..." "Header"

# Documents
Invoke-BackupCopy -Source "$userProfilePath\Documents" -Destination "$backupRoot\Documents" -Description "Documents folder" `
    -ExcludeDirs @("node_modules", "__pycache__", ".venv", "venv", "env")

# Desktop
Invoke-BackupCopy -Source "$userProfilePath\Desktop" -Destination "$backupRoot\Desktop" -Description "Desktop folder" `
    -ExcludeDirs @("node_modules", "__pycache__", ".venv", "venv", "env")

# Pictures
Invoke-BackupCopy -Source "$userProfilePath\Pictures" -Destination "$backupRoot\Pictures" -Description "Pictures folder"

# Videos
Invoke-BackupCopy -Source "$userProfilePath\Videos" -Destination "$backupRoot\Videos" -Description "Videos folder"

# Music
Invoke-BackupCopy -Source "$userProfilePath\Music" -Destination "$backupRoot\Music" -Description "Music folder"

# Downloads (conditional)
if (-not $ExcludeDownloads) {
    $downloadsPath = "$userProfilePath\Downloads"
    if (Test-Path $downloadsPath) {
        $downloadsSize = (Get-ChildItem $downloadsPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $downloadsSizeGB = [math]::Round($downloadsSize / 1GB, 2)

        if ($downloadsSizeGB -gt 50) {
            Write-ColorOutput "Downloads folder is $downloadsSizeGB GB" "Warning"
            $response = Read-Host "This is quite large. Continue backing up Downloads? (y/N)"
            if ($response -eq 'y' -or $response -eq 'Y') {
                Invoke-BackupCopy -Source $downloadsPath -Destination "$backupRoot\Downloads" -Description "Downloads folder"
            } else {
                Write-ColorOutput "Skipping Downloads folder" "Warning"
                $script:skipped += "Downloads folder (user choice)"
            }
        } else {
            Invoke-BackupCopy -Source $downloadsPath -Destination "$backupRoot\Downloads" -Description "Downloads folder"
        }
    }
}

# Development & Config Files
Write-ColorOutput "Backing up development configurations..." "Header"

# SSH Keys
if (Test-Path "$userProfilePath\.ssh") {
    Invoke-BackupCopy -Source "$userProfilePath\.ssh" -Destination "$backupRoot\SSHKeys" -Description "SSH keys"
    Write-ColorOutput "IMPORTANT: SSH keys backed up - keep this backup secure!" "Warning"
}

# Git config
if (Test-Path "$userProfilePath\.gitconfig") {
    if ($PSCmdlet.ShouldProcess("$userProfilePath\.gitconfig", "Copy .gitconfig")) {
        Copy-Item "$userProfilePath\.gitconfig" "$backupRoot\GitConfig\.gitconfig" -Force
        Write-ColorOutput "✓ Git config backed up" "Success"
    }
}

# Git global ignore
if (Test-Path "$userProfilePath\.gitignore_global") {
    if ($PSCmdlet.ShouldProcess("$userProfilePath\.gitignore_global", "Copy .gitignore_global")) {
        Copy-Item "$userProfilePath\.gitignore_global" "$backupRoot\GitConfig\.gitignore_global" -Force
    }
}

# AWS config
Invoke-BackupCopy -Source "$userProfilePath\.aws" -Destination "$backupRoot\GitConfig\.aws" -Description "AWS configuration" -SkipIfNotExist

# Kubernetes config
Invoke-BackupCopy -Source "$userProfilePath\.kube" -Destination "$backupRoot\GitConfig\.kube" -Description "Kubernetes configuration" -SkipIfNotExist

# Docker config
Invoke-BackupCopy -Source "$userProfilePath\.docker" -Destination "$backupRoot\GitConfig\.docker" -Description "Docker configuration" -SkipIfNotExist

# Other common dotfiles
$dotfiles = @(".bashrc", ".zshrc", ".bash_profile", ".profile", ".vimrc", ".npmrc", ".yarnrc")
foreach ($dotfile in $dotfiles) {
    $dotfilePath = "$userProfilePath\$dotfile"
    if (Test-Path $dotfilePath) {
        if ($PSCmdlet.ShouldProcess($dotfilePath, "Copy $dotfile")) {
            Copy-Item $dotfilePath "$backupRoot\GitConfig\$dotfile" -Force
            Write-ColorOutput "✓ Backed up $dotfile" "Success"
        }
    }
}

# VS Code Settings
Write-ColorOutput "Backing up VS Code settings..." "Header"

$vscodeUserPath = "$env:APPDATA\Code\User"
if (Test-Path $vscodeUserPath) {
    # Settings and keybindings
    if (Test-Path "$vscodeUserPath\settings.json") {
        if ($PSCmdlet.ShouldProcess("$vscodeUserPath\settings.json", "Copy VS Code settings")) {
            Copy-Item "$vscodeUserPath\settings.json" "$backupRoot\VSCodeSettings\settings.json" -Force
        }
    }

    if (Test-Path "$vscodeUserPath\keybindings.json") {
        if ($PSCmdlet.ShouldProcess("$vscodeUserPath\keybindings.json", "Copy VS Code keybindings")) {
            Copy-Item "$vscodeUserPath\keybindings.json" "$backupRoot\VSCodeSettings\keybindings.json" -Force
        }
    }

    # Snippets
    if (Test-Path "$vscodeUserPath\snippets") {
        Invoke-BackupCopy -Source "$vscodeUserPath\snippets" -Destination "$backupRoot\VSCodeSettings\snippets" -Description "VS Code snippets"
    }

    # Export installed extensions
    if (Get-Command code -ErrorAction SilentlyContinue) {
        if ($PSCmdlet.ShouldProcess("VS Code extensions", "Export list")) {
            Write-ColorOutput "Exporting VS Code extensions list..." "Info"
            code --list-extensions | Out-File "$backupRoot\VSCodeSettings\extensions.txt"
            Write-ColorOutput "✓ VS Code extensions list exported" "Success"
        }
    } else {
        Write-ColorOutput "VS Code CLI not found - skipping extension export" "Warning"
    }

    Write-ColorOutput "✓ VS Code settings backed up" "Success"
} else {
    Write-ColorOutput "VS Code settings not found" "Warning"
    $script:skipped += "VS Code settings"
}

# Windows Terminal Settings
Write-ColorOutput "Backing up Windows Terminal settings..." "Header"

$terminalPaths = Get-ChildItem "$env:LOCALAPPDATA\Packages" -Filter "Microsoft.WindowsTerminal*" -ErrorAction SilentlyContinue

foreach ($terminalPath in $terminalPaths) {
    $settingsPath = "$($terminalPath.FullName)\LocalState\settings.json"
    if (Test-Path $settingsPath) {
        if ($PSCmdlet.ShouldProcess($settingsPath, "Copy Windows Terminal settings")) {
            Copy-Item $settingsPath "$backupRoot\TerminalSettings\settings.json" -Force
            Write-ColorOutput "✓ Windows Terminal settings backed up" "Success"
            break
        }
    }
}

# Browser Data
Write-ColorOutput "Backing up browser data..." "Header"

# Chrome bookmarks
$chromeBookmarks = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Bookmarks"
if (Test-Path $chromeBookmarks) {
    if ($PSCmdlet.ShouldProcess($chromeBookmarks, "Copy Chrome bookmarks")) {
        Copy-Item $chromeBookmarks "$backupRoot\BrowserData\Chrome_Bookmarks.json" -Force
        Write-ColorOutput "✓ Chrome bookmarks backed up" "Success"
    }
}

# Firefox profiles
$firefoxProfiles = "$env:APPDATA\Mozilla\Firefox\Profiles"
if (Test-Path $firefoxProfiles) {
    Invoke-BackupCopy -Source $firefoxProfiles -Destination "$backupRoot\BrowserData\Firefox_Profiles" -Description "Firefox profiles"
}

# Game Configurations
Write-ColorOutput "Scanning for game configurations..." "Header"

$gameConfigPaths = @(
    "$userProfilePath\Documents\My Games",
    "$env:LOCALAPPDATA"
)

$gameConfigs = @()

# Scan Documents\My Games
if (Test-Path "$userProfilePath\Documents\My Games") {
    $myGamesPath = "$userProfilePath\Documents\My Games"
    if ($PSCmdlet.ShouldProcess($myGamesPath, "Copy My Games folder")) {
        Invoke-BackupCopy -Source $myGamesPath -Destination "$backupRoot\GameConfigs\My Games" -Description "My Games folder"
        $gameConfigs += "My Games folder"
    }
}

# Common game config locations in AppData\Local
$commonGameDirs = @(
    "Blizzard Entertainment",
    "Activision",
    "Epic",
    "NVIDIA Corporation",
    "Steam"
)

foreach ($gameDir in $commonGameDirs) {
    $gamePath = "$env:LOCALAPPDATA\$gameDir"
    if (Test-Path $gamePath) {
        $destPath = "$backupRoot\GameConfigs\AppDataLocal_$gameDir"
        if ($PSCmdlet.ShouldProcess($gamePath, "Copy $gameDir configs")) {
            # Only copy config files, not entire game installations
            try {
                New-Item -Path $destPath -ItemType Directory -Force | Out-Null
                Get-ChildItem $gamePath -Recurse -Include "*.cfg", "*.ini", "*.json", "*.xml" -File -ErrorAction SilentlyContinue |
                    ForEach-Object {
                        $relativePath = $_.FullName.Substring($gamePath.Length + 1)
                        $destFile = Join-Path $destPath $relativePath
                        $destFileDir = Split-Path $destFile -Parent
                        if (-not (Test-Path $destFileDir)) {
                            New-Item -Path $destFileDir -ItemType Directory -Force | Out-Null
                        }
                        Copy-Item $_.FullName $destFile -Force
                    }
                Write-ColorOutput "✓ Backed up $gameDir configs" "Success"
                $gameConfigs += $gameDir
            } catch {
                Write-ColorOutput "Error backing up $gameDir configs: $_" "Warning"
            }
        }
    }
}

# Selected AppData folders
Write-ColorOutput "Backing up selected AppData folders..." "Header"

# Common application data to backup
$roamingApps = @(
    "Spotify",
    "Discord",
    "Slack",
    "obs-studio",
    "vlc"
)

foreach ($app in $roamingApps) {
    $appPath = "$env:APPDATA\$app"
    if (Test-Path $appPath) {
        Invoke-BackupCopy -Source $appPath -Destination "$backupRoot\AppDataRoaming_Selected\$app" -Description "$app settings" -SkipIfNotExist
    }
}

# System Configuration Exports
Write-ColorOutput "Exporting system configuration..." "Header"

if ($PSCmdlet.ShouldProcess("System configuration", "Export")) {
    try {
        # Environment variables
        Write-ColorOutput "Exporting environment variables..." "Info"
        Get-ChildItem Env: | Sort-Object Name | ForEach-Object {
            "$($_.Name)=$($_.Value)"
        } | Out-File "$backupRoot\SystemConfig\EnvironmentVariables.txt"

        # User-specific environment variables
        $userEnvVars = [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::User)
        "=== USER ENVIRONMENT VARIABLES ===" | Out-File "$backupRoot\SystemConfig\EnvironmentVariables_User.txt"
        $userEnvVars.GetEnumerator() | Sort-Object Name | ForEach-Object {
            "$($_.Key)=$($_.Value)"
        } | Out-File "$backupRoot\SystemConfig\EnvironmentVariables_User.txt" -Append

        # System environment variables (requires admin)
        $systemEnvVars = [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Machine)
        "=== SYSTEM ENVIRONMENT VARIABLES ===" | Out-File "$backupRoot\SystemConfig\EnvironmentVariables_System.txt"
        $systemEnvVars.GetEnumerator() | Sort-Object Name | ForEach-Object {
            "$($_.Key)=$($_.Value)"
        } | Out-File "$backupRoot\SystemConfig\EnvironmentVariables_System.txt" -Append

        Write-ColorOutput "✓ Environment variables exported" "Success"

        # Installed programs
        Write-ColorOutput "Exporting installed programs list..." "Info"
        $installedPrograms = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
                                              HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName } |
            Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
            Sort-Object DisplayName

        $installedPrograms | Format-Table -AutoSize | Out-File "$backupRoot\SystemConfig\InstalledPrograms.txt"
        $installedPrograms | Export-Csv "$backupRoot\SystemConfig\InstalledPrograms.csv" -NoTypeInformation
        Write-ColorOutput "✓ Installed programs list exported ($($installedPrograms.Count) programs)" "Success"

        # Windows features
        Write-ColorOutput "Exporting Windows optional features..." "Info"
        $enabledFeatures = Get-WindowsOptionalFeature -Online -ErrorAction SilentlyContinue |
            Where-Object { $_.State -eq "Enabled" } |
            Select-Object FeatureName, State

        $enabledFeatures | Format-Table -AutoSize | Out-File "$backupRoot\SystemConfig\WindowsFeatures.txt"
        $enabledFeatures | Export-Csv "$backupRoot\SystemConfig\WindowsFeatures.csv" -NoTypeInformation
        Write-ColorOutput "✓ Windows features exported ($($enabledFeatures.Count) enabled features)" "Success"

        # Installed Windows packages/apps
        Write-ColorOutput "Exporting Windows Store apps..." "Info"
        $winGetApps = Get-AppxPackage -ErrorAction SilentlyContinue |
            Select-Object Name, PackageFullName, Version |
            Sort-Object Name

        $winGetApps | Export-Csv "$backupRoot\SystemConfig\WindowsStoreApps.csv" -NoTypeInformation

        # Network adapters
        Write-ColorOutput "Exporting network configuration..." "Info"
        Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, MacAddress, LinkSpeed |
            Format-Table -AutoSize | Out-File "$backupRoot\SystemConfig\NetworkAdapters.txt"

        # PowerShell modules
        Write-ColorOutput "Exporting PowerShell modules..." "Info"
        Get-InstalledModule -ErrorAction SilentlyContinue |
            Select-Object Name, Version, Repository |
            Sort-Object Name |
            Export-Csv "$backupRoot\SystemConfig\PowerShellModules.csv" -NoTypeInformation

        # System information
        $computerInfo = Get-ComputerInfo -ErrorAction SilentlyContinue
        $computerInfo | Format-List | Out-File "$backupRoot\SystemConfig\SystemInfo.txt"

        Write-ColorOutput "✓ System configuration exported" "Success"

    } catch {
        Write-ColorOutput "Error exporting system configuration: $_" "Error"
        $script:errors += "Failed to export system configuration: $_"
    }
}

# Generate Restoration Guide
Write-ColorOutput "Generating restoration guide..." "Header"

$restorationGuide = @"
# Windows Reinstall Restoration Guide

**Backup Created:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Backup Location:** $backupRoot
**Source User:** $Username
**Source Computer:** $env:COMPUTERNAME

---

## Table of Contents
1. [Pre-Restoration Checklist](#pre-restoration-checklist)
2. [Restore User Files](#restore-user-files)
3. [Restore Development Configurations](#restore-development-configurations)
4. [Restore Application Settings](#restore-application-settings)
5. [Reinstall Programs](#reinstall-programs)
6. [Restore System Configuration](#restore-system-configuration)
7. [Post-Restoration Verification](#post-restoration-verification)
8. [Troubleshooting](#troubleshooting)

---

## Pre-Restoration Checklist

Before you begin restoring, ensure:

- [ ] Fresh Windows installation is complete and updated
- [ ] You've created your user account (preferably with the same username: **$Username**)
- [ ] Windows is activated
- [ ] Basic drivers are installed (especially storage drivers to access backup drive)
- [ ] You're logged in as an Administrator
- [ ] The backup drive is connected and accessible at: **$TargetDrive`:\**

---

## Restore User Files

### 1. Documents, Pictures, Videos, Music

These can be safely copied back to their original locations:

``````powershell
# Option A: Copy all at once (recommended)
`$backupPath = "$backupRoot"
`$userPath = "C:\Users\$Username"

# Copy main folders
Copy-Item "`$backupPath\Documents\*" "`$userPath\Documents" -Recurse -Force
Copy-Item "`$backupPath\Desktop\*" "`$userPath\Desktop" -Recurse -Force
Copy-Item "`$backupPath\Pictures\*" "`$userPath\Pictures" -Recurse -Force
Copy-Item "`$backupPath\Videos\*" "`$userPath\Videos" -Recurse -Force
Copy-Item "`$backupPath\Music\*" "`$userPath\Music" -Recurse -Force
Copy-Item "`$backupPath\Downloads\*" "`$userPath\Downloads" -Recurse -Force
``````

**Or** manually copy the folders using File Explorer.

**Verification:**
- [ ] Documents folder restored
- [ ] Desktop items visible
- [ ] Pictures accessible
- [ ] Videos accessible
- [ ] Music accessible
- [ ] Downloads restored (if backed up)

---

## Restore Development Configurations

### 2. SSH Keys

**IMPORTANT:** SSH keys contain sensitive authentication data!

``````powershell
# Restore SSH keys
`$sshBackup = "$backupRoot\SSHKeys"
`$sshPath = "`$env:USERPROFILE\.ssh"

# Create .ssh directory if it doesn't exist
New-Item -Path `$sshPath -ItemType Directory -Force

# Copy SSH keys
Copy-Item "`$sshBackup\*" `$sshPath -Recurse -Force

# Set proper permissions (important for SSH to work!)
icacls `$sshPath /inheritance:r
icacls `$sshPath /grant:r "`${env:USERNAME}:(OI)(CI)F"
icacls "`$sshPath\*" /inheritance:r
icacls "`$sshPath\*" /grant:r "`${env:USERNAME}:F"
``````

**Verification:**
- [ ] SSH keys restored to ``~/.ssh/``
- [ ] Permissions set correctly
- [ ] Test SSH connection: ``ssh -T git@github.com`` (if using GitHub)

### 3. Git Configuration

``````powershell
# Restore Git config
Copy-Item "$backupRoot\GitConfig\.gitconfig" "`$env:USERPROFILE\.gitconfig" -Force
Copy-Item "$backupRoot\GitConfig\.gitignore_global" "`$env:USERPROFILE\.gitignore_global" -Force -ErrorAction SilentlyContinue

# Or set manually:
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
``````

**Verification:**
- [ ] Git configured: ``git config --list``
- [ ] Name and email are correct

### 4. AWS / Docker / Kubernetes Configs

``````powershell
# AWS
Copy-Item "$backupRoot\GitConfig\.aws" "`$env:USERPROFILE\.aws" -Recurse -Force -ErrorAction SilentlyContinue

# Docker
Copy-Item "$backupRoot\GitConfig\.docker" "`$env:USERPROFILE\.docker" -Recurse -Force -ErrorAction SilentlyContinue

# Kubernetes
Copy-Item "$backupRoot\GitConfig\.kube" "`$env:USERPROFILE\.kube" -Recurse -Force -ErrorAction SilentlyContinue
``````

---

## Restore Application Settings

### 5. VS Code

**Step 1: Install VS Code**

Download from: https://code.visualstudio.com/

**Step 2: Restore Settings**

``````powershell
`$vscodeBackup = "$backupRoot\VSCodeSettings"
`$vscodeUser = "`$env:APPDATA\Code\User"

# Copy settings
Copy-Item "`$vscodeBackup\settings.json" "`$vscodeUser\settings.json" -Force
Copy-Item "`$vscodeBackup\keybindings.json" "`$vscodeUser\keybindings.json" -Force
Copy-Item "`$vscodeBackup\snippets" "`$vscodeUser\snippets" -Recurse -Force
``````

**Step 3: Reinstall Extensions**

``````powershell
# Install all extensions from backup
Get-Content "$backupRoot\VSCodeSettings\extensions.txt" | ForEach-Object {
    code --install-extension `$_
}
``````

**Verification:**
- [ ] VS Code settings applied
- [ ] Keybindings restored
- [ ] Extensions installed
- [ ] Snippets available

### 6. Windows Terminal

**Step 1: Install Windows Terminal** (if not already installed)

``````powershell
winget install Microsoft.WindowsTerminal
``````

**Step 2: Restore Settings**

``````powershell
# Find Windows Terminal package directory
`$terminalPath = Get-ChildItem "`$env:LOCALAPPDATA\Packages" -Filter "Microsoft.WindowsTerminal*" | Select-Object -First 1

# Copy settings
Copy-Item "$backupRoot\TerminalSettings\settings.json" "`$terminalPath\LocalState\settings.json" -Force
``````

**Verification:**
- [ ] Terminal color scheme restored
- [ ] Custom profiles available

### 7. Browser Data

**Chrome:**

1. Install Chrome: https://www.google.com/chrome/
2. Sign in to Chrome to sync bookmarks, extensions, passwords
3. **Or** manually import bookmarks:
   - Chrome → Bookmarks → Bookmark Manager → ⋮ → Import bookmarks
   - Select: ``$backupRoot\BrowserData\Chrome_Bookmarks.json``

**Firefox:**

1. Install Firefox: https://www.mozilla.org/firefox/
2. Sign in to Firefox Account to sync
3. **Or** restore profile folder:
   - Navigate to: ``%APPDATA%\Mozilla\Firefox\Profiles``
   - Copy backed up profiles from: ``$backupRoot\BrowserData\Firefox_Profiles``

**Verification:**
- [ ] Browser bookmarks restored
- [ ] Browser signed in (for sync)

### 8. Game Configurations

Game configs are backed up in: ``$backupRoot\GameConfigs\``

Most games will need to be reinstalled through their respective platforms (Steam, Epic, etc.), but you can restore save files and configuration files afterward.

**Common locations:**
- ``Documents\My Games`` → Restore to ``C:\Users\$Username\Documents\My Games``
- Various AppData folders have been backed up as config files only

---

## Reinstall Programs

### 9. Reinstall Software

Reference the programs list at: ``$backupRoot\SystemConfig\InstalledPrograms.txt``

**Recommended Installation Methods:**

**Using winget (Windows Package Manager):**

``````powershell
# Example installations:
winget install Git.Git
winget install Microsoft.VisualStudioCode
winget install Google.Chrome
winget install Discord.Discord
winget install Spotify.Spotify
winget install Docker.DockerDesktop
winget install Microsoft.PowerShell
winget install Python.Python.3.12
winget install OpenJS.NodeJS

# Search for packages:
winget search "package name"
``````

**Using Chocolatey:**

``````powershell
# Install Chocolatey first:
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Then install packages:
choco install googlechrome firefox vscode git docker-desktop -y
``````

**Manual Downloads:**
- Steam: https://store.steampowered.com/
- Adobe Creative Cloud: https://www.adobe.com/
- Office: https://www.office.com/

**Verification Checklist:**

Review ``$backupRoot\SystemConfig\InstalledPrograms.csv`` and check off as you reinstall:

- [ ] Web browsers
- [ ] Development tools (IDEs, Git, Docker, etc.)
- [ ] Communication apps (Slack, Discord, Teams)
- [ ] Media apps (Spotify, VLC, OBS)
- [ ] Gaming platforms (Steam, Epic, Battle.net)
- [ ] Productivity software
- [ ] Other essential tools

---

## Restore System Configuration

### 10. Environment Variables

Review the backed up environment variables:

``````powershell
# View backed up variables
notepad "$backupRoot\SystemConfig\EnvironmentVariables_User.txt"
``````

**Restore User Environment Variables:**

Open PowerShell as Administrator and manually re-create important variables:

``````powershell
# Example - adjust to your needs:
[System.Environment]::SetEnvironmentVariable("VARIABLE_NAME", "value", [System.EnvironmentVariableTarget]::User)
``````

**Common variables to restore:**
- ``PATH`` additions (be careful not to overwrite the new system's PATH!)
- Development environment variables (``JAVA_HOME``, ``PYTHON_PATH``, etc.)
- Custom application variables

**Verification:**
- [ ] Critical user environment variables restored
- [ ] PATH includes necessary directories

### 11. Windows Features

Review enabled features:

``````powershell
# View backed up features
Import-Csv "$backupRoot\SystemConfig\WindowsFeatures.csv"
``````

**Enable required features:**

``````powershell
# Example - Windows Subsystem for Linux:
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart

# Example - Hyper-V:
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
``````

**Verification:**
- [ ] Required Windows features enabled

### 12. PowerShell Modules

``````powershell
# View backed up modules
Import-Csv "$backupRoot\SystemConfig\PowerShellModules.csv"

# Example - install common modules:
Install-Module -Name Az -AllowClobber -Scope CurrentUser
Install-Module -Name Posh-Git -Scope CurrentUser
``````

---

## Post-Restoration Verification

### Final Checklist

**Files & Folders:**
- [ ] All documents accessible
- [ ] Desktop restored
- [ ] Pictures, videos, music accessible
- [ ] Project files intact and can be opened

**Development Environment:**
- [ ] Git installed and configured
- [ ] SSH keys working
- [ ] IDE/editor installed with settings
- [ ] Programming languages installed (Python, Node.js, etc.)
- [ ] Development tools functional (Docker, WSL, etc.)

**Applications:**
- [ ] All essential programs installed
- [ ] Application settings restored where possible
- [ ] Browsers signed in and bookmarks available

**System Configuration:**
- [ ] Important environment variables set
- [ ] Windows features enabled
- [ ] System updates installed

**Security:**
- [ ] Windows Defender active
- [ ] Firewall enabled
- [ ] Windows activated
- [ ] Backup drive securely stored (contains SSH keys!)

---

## Troubleshooting

### Common Issues

**SSH Keys Not Working:**

``````powershell
# Ensure proper permissions:
icacls "`$env:USERPROFILE\.ssh\id_rsa" /inheritance:r
icacls "`$env:USERPROFILE\.ssh\id_rsa" /grant:r "`${env:USERNAME}:F"

# Start ssh-agent:
Start-Service ssh-agent
ssh-add ~\.ssh\id_rsa
``````

**VS Code Extensions Not Installing:**

- Check internet connection
- Try installing manually from the marketplace
- Verify VS Code is up to date

**Environment Variables Not Taking Effect:**

- Restart PowerShell/Terminal after setting
- For system-wide variables, restart Windows
- Verify with: ``[System.Environment]::GetEnvironmentVariable("NAME", "User")``

**Game Saves Not Recognized:**

- Ensure game is fully installed before copying saves
- Check game-specific cloud save sync
- Verify file paths match the new installation

---

## Notes

- **Backup Security:** The backup contains sensitive data (SSH keys, credentials). Keep it secure and delete it from the backup drive once restoration is complete.
- **Cloud Sync:** Many modern applications sync settings via cloud (Chrome, Firefox, VS Code with Settings Sync, Discord, Spotify). Consider enabling these for easier future migrations.
- **Incremental Approach:** You don't need to restore everything at once. Restore critical files first, then add applications and configurations as needed.

---

## Backup Statistics

**Backup Completed:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Backup Location:** ``$backupRoot``

For detailed backup information, see: ``$backupRoot\BackupLog.txt``

---

**Good luck with your fresh Windows installation!** 🚀
"@

if ($PSCmdlet.ShouldProcess("RESTORATION_GUIDE.md", "Create restoration guide")) {
    $restorationGuide | Out-File "$backupRoot\RESTORATION_GUIDE.md" -Encoding UTF8
    Write-ColorOutput "✓ Restoration guide created" "Success"
}

# Finalize and create summary
$endTime = Get-Date
$duration = $endTime - $startTime

Write-ColorOutput "Finalizing backup..." "Header"

# Calculate total size
if (-not $WhatIfPreference) {
    $totalSize = (Get-ChildItem $backupRoot -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $totalSizeGB = [math]::Round($totalSize / 1GB, 2)
} else {
    $totalSizeGB = 0
}

# Create summary
$summary = @"
=============================================================================
                     WINDOWS BACKUP SUMMARY
=============================================================================

Backup Date/Time:    $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Backup Location:     $backupRoot
Source User:         $Username
Source Computer:     $env:COMPUTERNAME
Duration:            $($duration.ToString("hh\:mm\:ss"))
Total Size:          $totalSizeGB GB

=============================================================================
                         BACKUP CONTENTS
=============================================================================

User Folders:
  • Documents
  • Desktop
  • Pictures
  • Videos
  • Music
$(if (-not $ExcludeDownloads) { "  • Downloads" })

Development Configs:
  • SSH Keys (.ssh directory)
  • Git configuration (.gitconfig)
  • AWS credentials (if present)
  • Kubernetes config (if present)
  • Docker config (if present)
  • Shell configs (.bashrc, .zshrc, etc.)

Application Settings:
  • VS Code settings, keybindings, snippets, extensions
  • Windows Terminal settings
  • Browser bookmarks (Chrome, Firefox)
  • Game configurations
  • Selected AppData folders

System Configuration:
  • Environment variables (User & System)
  • Installed programs list
  • Windows optional features
  • PowerShell modules
  • Network configuration
  • System information

=============================================================================
                            STATISTICS
=============================================================================

Files Backed Up:     $script:totalFilesCopied major categories
Errors Encountered:  $($script:errors.Count)
Items Skipped:       $($script:skipped.Count)

=============================================================================
                           NEXT STEPS
=============================================================================

1. Verify backup completed successfully
2. Check BackupLog.txt for detailed information
3. Keep this backup drive safe during Windows reinstall
4. After fresh install, open RESTORATION_GUIDE.md for step-by-step
   restoration instructions

=============================================================================
                        IMPORTANT REMINDERS
=============================================================================

⚠ This backup contains sensitive data (SSH keys, credentials)
⚠ Keep the backup drive secure
⚠ Test a few critical files before proceeding with reinstall
⚠ Consider additional backups of truly irreplaceable data

=============================================================================

"@

if (-not $WhatIfPreference) {
    $summary | Out-File "$backupRoot\BACKUP_SUMMARY.txt" -Encoding UTF8
}

# Display summary
Write-Host $summary -ForegroundColor Cyan

# Show errors if any
if ($script:errors.Count -gt 0) {
    Write-ColorOutput "Errors encountered during backup:" "Warning"
    $script:errors | ForEach-Object {
        Write-Host "  • $_" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Show skipped items
if ($script:skipped.Count -gt 0) {
    Write-ColorOutput "Items skipped:" "Info"
    $script:skipped | ForEach-Object {
        Write-Host "  • $_" -ForegroundColor Gray
    }
    Write-Host ""
}

# Compression option
$zipFile = $null
if ($Compress -and -not $WhatIfPreference) {
    Write-ColorOutput "Compressing backup..." "Header"

    $zipFile = "$TargetDrive`:\WindowsBackup_$timestamp.zip"

    try {
        Write-ColorOutput "Creating ZIP archive: $zipFile" "Info"
        Write-ColorOutput "This may take a while depending on backup size..." "Warning"

        Compress-Archive -Path $backupRoot -DestinationPath $zipFile -CompressionLevel Optimal

        $zipSize = (Get-Item $zipFile).Length
        $zipSizeGB = [math]::Round($zipSize / 1GB, 2)

        Write-ColorOutput "✓ Backup compressed successfully" "Success"
        Write-ColorOutput "Compressed size: $zipSizeGB GB" "Info"
        Write-ColorOutput "Original folder: $backupRoot" "Info"
        Write-ColorOutput "Compressed file: $zipFile" "Info"

        $deleteOriginal = Read-Host "`nDelete original backup folder to save space? (y/N)"
        if ($deleteOriginal -eq 'y' -or $deleteOriginal -eq 'Y') {
            Remove-Item $backupRoot -Recurse -Force
            Write-ColorOutput "✓ Original backup folder deleted" "Success"
        }
    } catch {
        Write-ColorOutput "Error compressing backup: $_" "Error"
        Write-ColorOutput "Original backup folder remains at: $backupRoot" "Info"
    }
}

# Final message
Write-Host ""
Write-ColorOutput "========================================" "Success"
Write-ColorOutput "  BACKUP COMPLETED SUCCESSFULLY!" "Success"
Write-ColorOutput "========================================" "Success"
Write-Host ""
Write-ColorOutput "Backup Location: $backupRoot" "Info"
if ($Compress -and -not $WhatIfPreference -and $zipFile -and (Test-Path $zipFile)) {
    Write-ColorOutput "Compressed File: $zipFile" "Info"
}
Write-Host ""
Write-ColorOutput "Next steps:" "Info"
Write-Host "  1. Review BACKUP_SUMMARY.txt for details"
Write-Host "  2. Check BackupLog.txt for comprehensive log"
Write-Host "  3. After Windows reinstall, open RESTORATION_GUIDE.md"
Write-Host ""
Write-ColorOutput "Keep this backup drive safe! 🔒" "Warning"
Write-Host ""

# Write final log entry
Write-Log "========================================" "INFO"
Write-Log "BACKUP COMPLETED" "SUCCESS"
Write-Log "Duration: $($duration.ToString())" "INFO"
Write-Log "Total Size: $totalSizeGB GB" "INFO"
Write-Log "Errors: $($script:errors.Count)" "INFO"
Write-Log "========================================" "INFO"
