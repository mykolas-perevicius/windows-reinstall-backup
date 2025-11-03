<#
.SYNOPSIS
    Windows Reinstall Restore Script - Restore backed up data to new Windows installation

.DESCRIPTION
    This script restores user data, configurations, and settings from a backup created by backup.ps1.
    It intelligently restores files to appropriate locations, fixes permissions, and provides guidance
    for manual steps like reinstalling programs.

.PARAMETER BackupPath
    Path to the backup folder (e.g., C:\WindowsBackup_20241103_153000)

.PARAMETER TargetUser
    The username to restore files to (default: current user)

.PARAMETER SelectiveRestore
    Show interactive menu to choose what to restore

.PARAMETER SkipUserFiles
    Don't restore user folders (Documents, Desktop, etc.)

.PARAMETER SkipConfigs
    Don't restore configuration files (SSH, Git, VS Code, etc.)

.PARAMETER WhatIf
    Preview what would be restored without actually copying files

.EXAMPLE
    .\restore.ps1 -BackupPath "C:\WindowsBackup_20241103_153000"

.EXAMPLE
    .\restore.ps1 -BackupPath "D:\WindowsBackup_20241103_153000" -TargetUser "NewUser"

.EXAMPLE
    .\restore.ps1 -BackupPath "C:\WindowsBackup_20241103_153000" -SelectiveRestore

.EXAMPLE
    .\restore.ps1 -BackupPath "C:\WindowsBackup_20241103_153000" -WhatIf
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [string]$BackupPath,

    [Parameter(Mandatory=$false)]
    [string]$TargetUser,

    [switch]$SelectiveRestore,

    [switch]$SkipUserFiles,

    [switch]$SkipConfigs
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
║        Windows Reinstall Restore Script v1.0                ║
║        Restore your backed up data and configurations       ║
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

# Get backup path if not specified
if (-not $BackupPath) {
    Write-ColorOutput "Looking for backup folders..." "Info"

    # Search common locations
    $possibleBackups = @()

    # Search all drives
    Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        $driveLetter = $_.Name
        $backupFolders = Get-ChildItem "$driveLetter`:\" -Filter "WindowsBackup_*" -Directory -ErrorAction SilentlyContinue
        foreach ($folder in $backupFolders) {
            $possibleBackups += $folder.FullName
        }
    }

    if ($possibleBackups.Count -eq 0) {
        Write-ColorOutput "No backup folders found!" "Error"
        Write-ColorOutput "Please specify the backup path manually:" "Info"
        Write-Host "  Example: .\restore.ps1 -BackupPath `"C:\WindowsBackup_20241103_153000`"" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "`nFound backup folders:" -ForegroundColor Green
    for ($i = 0; $i -lt $possibleBackups.Count; $i++) {
        Write-Host "  [$($i + 1)] $($possibleBackups[$i])" -ForegroundColor White
    }

    if ($possibleBackups.Count -eq 1) {
        $BackupPath = $possibleBackups[0]
        Write-ColorOutput "Using: $BackupPath" "Info"
    } else {
        do {
            $selection = Read-Host "`nSelect backup folder (1-$($possibleBackups.Count))"
            $selectionNum = [int]$selection - 1
        } while ($selectionNum -lt 0 -or $selectionNum -ge $possibleBackups.Count)

        $BackupPath = $possibleBackups[$selectionNum]
    }
}

# Verify backup path exists
if (-not (Test-Path $BackupPath)) {
    Write-ColorOutput "Backup path does not exist: $BackupPath" "Error"
    exit 1
}

# Verify it's a valid backup folder
if (-not (Test-Path "$BackupPath\RESTORATION_GUIDE.md") -and -not (Test-Path "$BackupPath\BackupLog.txt")) {
    Write-ColorOutput "This doesn't appear to be a valid backup folder!" "Error"
    Write-ColorOutput "Expected to find RESTORATION_GUIDE.md or BackupLog.txt" "Warning"
    $response = Read-Host "Continue anyway? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        exit 1
    }
}

# Get target user if not specified
if (-not $TargetUser) {
    $currentUser = $env:USERNAME
    $response = Read-Host "Restore files for user '$currentUser'? (Y/n)"
    if ($response -eq '' -or $response -eq 'Y' -or $response -eq 'y') {
        $TargetUser = $currentUser
    } else {
        $TargetUser = Read-Host "Enter target username"
    }
}

# Verify target user profile exists
$targetUserPath = "C:\Users\$TargetUser"
if (-not (Test-Path $targetUserPath)) {
    Write-ColorOutput "User profile does not exist: $targetUserPath" "Error"
    exit 1
}

# Initialize tracking
$script:itemsRestored = 0
$script:errors = @()
$script:skipped = @()
$startTime = Get-Date

# Restoration options
$restoreOptions = @{
    RestoreDocuments = $true
    RestoreDesktop = $true
    RestorePictures = $true
    RestoreVideos = $true
    RestoreMusic = $true
    RestoreDownloads = $true
    RestoreSSH = $true
    RestoreGit = $true
    RestoreVSCode = $true
    RestoreTerminal = $true
    RestoreBrowser = $true
    RestoreGameConfigs = $true
}

# Selective restore menu
if ($SelectiveRestore) {
    Write-ColorOutput "Select what to restore:" "Header"
    Write-Host ""
    Write-Host "User Folders:" -ForegroundColor Yellow
    Write-Host "  [1] Documents"
    Write-Host "  [2] Desktop"
    Write-Host "  [3] Pictures"
    Write-Host "  [4] Videos"
    Write-Host "  [5] Music"
    Write-Host "  [6] Downloads"
    Write-Host ""
    Write-Host "Configurations:" -ForegroundColor Yellow
    Write-Host "  [7] SSH Keys"
    Write-Host "  [8] Git Config"
    Write-Host "  [9] VS Code Settings & Extensions"
    Write-Host "  [10] Windows Terminal"
    Write-Host "  [11] Browser Bookmarks"
    Write-Host "  [12] Game Configurations"
    Write-Host ""
    Write-Host "  [A] All"
    Write-Host "  [N] None (I'll manually restore)"
    Write-Host ""

    $selection = Read-Host "Enter your choices (comma-separated, e.g., 1,2,7,9 or A for all)"

    if ($selection -eq 'N' -or $selection -eq 'n') {
        Write-ColorOutput "No automatic restoration selected. Exiting." "Info"
        Write-ColorOutput "Tip: Check $BackupPath\RESTORATION_GUIDE.md for manual steps" "Info"
        exit 0
    }

    if ($selection -ne 'A' -and $selection -ne 'a') {
        # Disable all first
        $restoreOptions.Keys | ForEach-Object { $restoreOptions[$_] = $false }

        # Enable selected
        $choices = $selection -split ','
        foreach ($choice in $choices) {
            switch ($choice.Trim()) {
                '1' { $restoreOptions.RestoreDocuments = $true }
                '2' { $restoreOptions.RestoreDesktop = $true }
                '3' { $restoreOptions.RestorePictures = $true }
                '4' { $restoreOptions.RestoreVideos = $true }
                '5' { $restoreOptions.RestoreMusic = $true }
                '6' { $restoreOptions.RestoreDownloads = $true }
                '7' { $restoreOptions.RestoreSSH = $true }
                '8' { $restoreOptions.RestoreGit = $true }
                '9' { $restoreOptions.RestoreVSCode = $true }
                '10' { $restoreOptions.RestoreTerminal = $true }
                '11' { $restoreOptions.RestoreBrowser = $true }
                '12' { $restoreOptions.RestoreGameConfigs = $true }
            }
        }
    }
}

# Apply command-line switches
if ($SkipUserFiles) {
    $restoreOptions.RestoreDocuments = $false
    $restoreOptions.RestoreDesktop = $false
    $restoreOptions.RestorePictures = $false
    $restoreOptions.RestoreVideos = $false
    $restoreOptions.RestoreMusic = $false
    $restoreOptions.RestoreDownloads = $false
}

if ($SkipConfigs) {
    $restoreOptions.RestoreSSH = $false
    $restoreOptions.RestoreGit = $false
    $restoreOptions.RestoreVSCode = $false
    $restoreOptions.RestoreTerminal = $false
    $restoreOptions.RestoreBrowser = $false
    $restoreOptions.RestoreGameConfigs = $false
}

# Show restore plan
Write-Host "`nRestore Plan:" -ForegroundColor Yellow
Write-Host "  Backup Location:  $BackupPath"
Write-Host "  Target User:      $TargetUser ($targetUserPath)"
Write-Host ""
Write-Host "Will restore:" -ForegroundColor Green
$restoreOptions.GetEnumerator() | Where-Object { $_.Value -eq $true } | ForEach-Object {
    $name = $_.Key -replace 'Restore', ''
    Write-Host "  ✓ $name" -ForegroundColor Green
}

if (-not $WhatIfPreference) {
    Write-Host ""
    $response = Read-Host "Proceed with restoration? (Y/n)"
    if ($response -eq 'n' -or $response -eq 'N') {
        Write-ColorOutput "Restoration cancelled by user" "Warning"
        exit 0
    }
}

# Helper function for restoring with robocopy
function Invoke-Restore {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Description,
        [switch]$SkipIfNotExist
    )

    if (-not (Test-Path $Source)) {
        if ($SkipIfNotExist) {
            Write-ColorOutput "Skipping $Description (not in backup)" "Warning"
            $script:skipped += $Description
            return
        } else {
            Write-ColorOutput "Source not found in backup: $Source" "Error"
            $script:errors += "Source not found: $Source"
            return
        }
    }

    Write-ColorOutput "Restoring: $Description" "Info"

    if ($WhatIfPreference) {
        Write-Host "  [WhatIf] Would restore: $Source -> $Destination" -ForegroundColor DarkGray
        return
    }

    # Create destination directory if needed
    if (-not (Test-Path $Destination)) {
        New-Item -Path $Destination -ItemType Directory -Force | Out-Null
    }

    # Use robocopy for efficient copying
    $robocopyArgs = @(
        $Source,
        $Destination,
        "/E",           # Copy subdirectories, including empty ones
        "/Z",           # Restartable mode
        "/R:3",         # Retry 3 times
        "/W:5",         # Wait 5 seconds between retries
        "/MT:8",        # Multi-threaded
        "/NP",          # No progress percentage
        "/NDL",         # No directory list
        "/NFL"          # No file list
    )

    try {
        $result = & robocopy @robocopyArgs 2>&1 | Out-Null
        $exitCode = $LASTEXITCODE

        if ($exitCode -lt 8) {
            Write-ColorOutput "✓ Restored: $Description" "Success"
            $script:itemsRestored++
        } else {
            Write-ColorOutput "Partial restore: $Description (Exit code: $exitCode)" "Warning"
            $script:errors += "Partial restore of $Description"
        }
    } catch {
        Write-ColorOutput "Error restoring $Description`: $_" "Error"
        $script:errors += "Failed to restore $Description`: $_"
    }
}

# Helper function for single file copy
function Copy-SingleFile {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Description,
        [switch]$SkipIfNotExist
    )

    if (-not (Test-Path $Source)) {
        if ($SkipIfNotExist) {
            Write-ColorOutput "Skipping $Description (not in backup)" "Warning"
            $script:skipped += $Description
            return
        } else {
            Write-ColorOutput "File not found in backup: $Source" "Error"
            $script:errors += "File not found: $Source"
            return
        }
    }

    Write-ColorOutput "Restoring: $Description" "Info"

    if ($WhatIfPreference) {
        Write-Host "  [WhatIf] Would copy: $Source -> $Destination" -ForegroundColor DarkGray
        return
    }

    # Create destination directory if needed
    $destDir = Split-Path $Destination -Parent
    if (-not (Test-Path $destDir)) {
        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
    }

    try {
        Copy-Item -Path $Source -Destination $Destination -Force
        Write-ColorOutput "✓ Restored: $Description" "Success"
        $script:itemsRestored++
    } catch {
        Write-ColorOutput "Error restoring $Description`: $_" "Error"
        $script:errors += "Failed to restore $Description`: $_"
    }
}

# Restore User Folders
if (-not $SkipUserFiles) {
    Write-ColorOutput "Restoring user folders..." "Header"

    if ($restoreOptions.RestoreDocuments) {
        Invoke-Restore -Source "$BackupPath\Documents" -Destination "$targetUserPath\Documents" -Description "Documents folder" -SkipIfNotExist
    }

    if ($restoreOptions.RestoreDesktop) {
        Invoke-Restore -Source "$BackupPath\Desktop" -Destination "$targetUserPath\Desktop" -Description "Desktop folder" -SkipIfNotExist
    }

    if ($restoreOptions.RestorePictures) {
        Invoke-Restore -Source "$BackupPath\Pictures" -Destination "$targetUserPath\Pictures" -Description "Pictures folder" -SkipIfNotExist
    }

    if ($restoreOptions.RestoreVideos) {
        Invoke-Restore -Source "$BackupPath\Videos" -Destination "$targetUserPath\Videos" -Description "Videos folder" -SkipIfNotExist
    }

    if ($restoreOptions.RestoreMusic) {
        Invoke-Restore -Source "$BackupPath\Music" -Destination "$targetUserPath\Music" -Description "Music folder" -SkipIfNotExist
    }

    if ($restoreOptions.RestoreDownloads) {
        Invoke-Restore -Source "$BackupPath\Downloads" -Destination "$targetUserPath\Downloads" -Description "Downloads folder" -SkipIfNotExist
    }
}

# Restore Development Configs
if (-not $SkipConfigs) {
    Write-ColorOutput "Restoring development configurations..." "Header"

    if ($restoreOptions.RestoreSSH) {
        $sshSource = "$BackupPath\SSHKeys"
        $sshDest = "$targetUserPath\.ssh"

        if (Test-Path $sshSource) {
            if ($PSCmdlet.ShouldProcess("SSH keys", "Restore")) {
                Invoke-Restore -Source $sshSource -Destination $sshDest -Description "SSH keys" -SkipIfNotExist

                # Fix SSH key permissions
                if (Test-Path $sshDest -and -not $WhatIfPreference) {
                    Write-ColorOutput "Fixing SSH key permissions..." "Info"
                    try {
                        icacls $sshDest /inheritance:r 2>&1 | Out-Null
                        icacls $sshDest /grant:r "${env:USERNAME}:(OI)(CI)F" 2>&1 | Out-Null

                        Get-ChildItem $sshDest -File | ForEach-Object {
                            icacls $_.FullName /inheritance:r 2>&1 | Out-Null
                            icacls $_.FullName /grant:r "${env:USERNAME}:F" 2>&1 | Out-Null
                        }

                        Write-ColorOutput "✓ SSH key permissions fixed" "Success"
                    } catch {
                        Write-ColorOutput "Warning: Could not set SSH permissions: $_" "Warning"
                    }
                }

                Write-ColorOutput "IMPORTANT: SSH keys restored - test with: ssh -T git@github.com" "Warning"
            }
        }
    }

    if ($restoreOptions.RestoreGit) {
        Copy-SingleFile -Source "$BackupPath\GitConfig\.gitconfig" -Destination "$targetUserPath\.gitconfig" -Description "Git config" -SkipIfNotExist
        Copy-SingleFile -Source "$BackupPath\GitConfig\.gitignore_global" -Destination "$targetUserPath\.gitignore_global" -Description "Git global ignore" -SkipIfNotExist

        # Other dotfiles
        $dotfiles = @(".bashrc", ".zshrc", ".bash_profile", ".profile", ".vimrc", ".npmrc", ".yarnrc")
        foreach ($dotfile in $dotfiles) {
            Copy-SingleFile -Source "$BackupPath\GitConfig\$dotfile" -Destination "$targetUserPath\$dotfile" -Description $dotfile -SkipIfNotExist
        }

        # AWS, Kubernetes, Docker configs
        Invoke-Restore -Source "$BackupPath\GitConfig\.aws" -Destination "$targetUserPath\.aws" -Description "AWS credentials" -SkipIfNotExist
        Invoke-Restore -Source "$BackupPath\GitConfig\.kube" -Destination "$targetUserPath\.kube" -Description "Kubernetes config" -SkipIfNotExist
        Invoke-Restore -Source "$BackupPath\GitConfig\.docker" -Destination "$targetUserPath\.docker" -Description "Docker config" -SkipIfNotExist
    }
}

# Restore VS Code
if ($restoreOptions.RestoreVSCode -and -not $SkipConfigs) {
    Write-ColorOutput "Restoring VS Code settings..." "Header"

    $vscodeBackup = "$BackupPath\VSCodeSettings"
    $vscodeUser = "$env:APPDATA\Code\User"

    if (Test-Path $vscodeBackup) {
        Copy-SingleFile -Source "$vscodeBackup\settings.json" -Destination "$vscodeUser\settings.json" -Description "VS Code settings" -SkipIfNotExist
        Copy-SingleFile -Source "$vscodeBackup\keybindings.json" -Destination "$vscodeUser\keybindings.json" -Description "VS Code keybindings" -SkipIfNotExist
        Invoke-Restore -Source "$vscodeBackup\snippets" -Destination "$vscodeUser\snippets" -Description "VS Code snippets" -SkipIfNotExist

        # Reinstall extensions
        if (Test-Path "$vscodeBackup\extensions.txt" -and -not $WhatIfPreference) {
            if (Get-Command code -ErrorAction SilentlyContinue) {
                Write-ColorOutput "Reinstalling VS Code extensions..." "Info"
                $extensions = Get-Content "$vscodeBackup\extensions.txt"
                $totalExtensions = $extensions.Count
                $currentExtension = 0

                foreach ($extension in $extensions) {
                    $currentExtension++
                    Write-Host "  [$currentExtension/$totalExtensions] Installing $extension..." -ForegroundColor Gray
                    code --install-extension $extension --force 2>&1 | Out-Null
                }

                Write-ColorOutput "✓ VS Code extensions reinstalled ($totalExtensions extensions)" "Success"
            } else {
                Write-ColorOutput "VS Code CLI not found - skipping extension installation" "Warning"
                Write-ColorOutput "Install VS Code first, then run: Get-Content '$vscodeBackup\extensions.txt' | ForEach-Object { code --install-extension `$_ }" "Info"
            }
        }
    }
}

# Restore Windows Terminal
if ($restoreOptions.RestoreTerminal -and -not $SkipConfigs) {
    Write-ColorOutput "Restoring Windows Terminal settings..." "Header"

    $terminalBackup = "$BackupPath\TerminalSettings\settings.json"
    if (Test-Path $terminalBackup) {
        $terminalPaths = Get-ChildItem "$env:LOCALAPPDATA\Packages" -Filter "Microsoft.WindowsTerminal*" -ErrorAction SilentlyContinue

        if ($terminalPaths) {
            foreach ($terminalPath in $terminalPaths) {
                $settingsDest = "$($terminalPath.FullName)\LocalState\settings.json"
                $settingsDir = Split-Path $settingsDest -Parent

                if (-not (Test-Path $settingsDir)) {
                    New-Item -Path $settingsDir -ItemType Directory -Force | Out-Null
                }

                Copy-SingleFile -Source $terminalBackup -Destination $settingsDest -Description "Windows Terminal settings"
                break
            }
        } else {
            Write-ColorOutput "Windows Terminal not installed - skipping" "Warning"
        }
    }
}

# Restore Browser Data
if ($restoreOptions.RestoreBrowser -and -not $SkipConfigs) {
    Write-ColorOutput "Restoring browser data..." "Header"

    # Chrome bookmarks
    $chromeBackup = "$BackupPath\BrowserData\Chrome_Bookmarks.json"
    $chromeDest = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Bookmarks"

    if (Test-Path $chromeBackup) {
        Copy-SingleFile -Source $chromeBackup -Destination $chromeDest -Description "Chrome bookmarks" -SkipIfNotExist
    }

    # Firefox profiles
    $firefoxBackup = "$BackupPath\BrowserData\Firefox_Profiles"
    $firefoxDest = "$env:APPDATA\Mozilla\Firefox\Profiles"

    if (Test-Path $firefoxBackup) {
        Invoke-Restore -Source $firefoxBackup -Destination $firefoxDest -Description "Firefox profiles" -SkipIfNotExist
    }

    Write-ColorOutput "Note: Browser sync (sign-in) is recommended for complete restoration" "Info"
}

# Restore Game Configs
if ($restoreOptions.RestoreGameConfigs -and -not $SkipConfigs) {
    Write-ColorOutput "Restoring game configurations..." "Header"

    if (Test-Path "$BackupPath\GameConfigs\My Games") {
        Invoke-Restore -Source "$BackupPath\GameConfigs\My Games" -Destination "$targetUserPath\Documents\My Games" -Description "My Games folder" -SkipIfNotExist
    }

    # Restore AppData game configs
    Get-ChildItem "$BackupPath\GameConfigs" -Filter "AppDataLocal_*" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $gameName = $_.Name -replace 'AppDataLocal_', ''
        Invoke-Restore -Source $_.FullName -Destination "$env:LOCALAPPDATA\$gameName" -Description "$gameName configs" -SkipIfNotExist
    }
}

# Completion summary
$endTime = Get-Date
$duration = $endTime - $startTime

Write-ColorOutput "Restoration completed!" "Header"

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "                     RESTORATION SUMMARY" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Items Restored:      $script:itemsRestored"
Write-Host "Items Skipped:       $($script:skipped.Count)"
Write-Host "Errors:              $($script:errors.Count)"
Write-Host "Duration:            $($duration.ToString("hh\:mm\:ss"))"
Write-Host ""

if ($script:errors.Count -gt 0) {
    Write-Host "Errors encountered:" -ForegroundColor Yellow
    $script:errors | ForEach-Object {
        Write-Host "  • $_" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($script:skipped.Count -gt 0) {
    Write-Host "Items skipped (not in backup):" -ForegroundColor Gray
    $script:skipped | ForEach-Object {
        Write-Host "  • $_" -ForegroundColor Gray
    }
    Write-Host ""
}

# Manual steps reminder
Write-ColorOutput "Manual steps remaining:" "Header"
Write-Host ""
Write-Host "📋 Programs to Reinstall:" -ForegroundColor Yellow
Write-Host "  Check: $BackupPath\SystemConfig\InstalledPrograms.txt"
Write-Host "  Use winget, Chocolatey, or manual downloads"
Write-Host ""
Write-Host "🔧 Environment Variables:" -ForegroundColor Yellow
Write-Host "  Review: $BackupPath\SystemConfig\EnvironmentVariables_User.txt"
Write-Host "  Manually re-create important variables"
Write-Host ""
Write-Host "🪟 Windows Features:" -ForegroundColor Yellow
Write-Host "  Check: $BackupPath\SystemConfig\WindowsFeatures.txt"
Write-Host "  Enable required features (WSL, Hyper-V, etc.)"
Write-Host ""
Write-Host "🧪 Verify Restoration:" -ForegroundColor Yellow
Write-Host "  ✓ Open a few documents to verify"
Write-Host "  ✓ Test SSH keys: ssh -T git@github.com"
Write-Host "  ✓ Launch VS Code and check extensions"
Write-Host "  ✓ Open browser and verify bookmarks"
Write-Host ""

Write-ColorOutput "========================================" "Success"
Write-ColorOutput "  RESTORATION COMPLETED!" "Success"
Write-ColorOutput "========================================" "Success"
Write-Host ""
Write-ColorOutput "For detailed manual steps, see: $BackupPath\RESTORATION_GUIDE.md" "Info"
Write-Host ""
