# Restoration Guide - restore.ps1

Complete guide for using the `restore.ps1` script to restore your backed up data to your new Windows installation.

## Quick Start

```powershell
# Navigate to the script directory
cd C:\windows-reinstall-backup

# Run the restore script (it will auto-detect backup folders)
.\restore.ps1

# Or specify the backup path explicitly
.\restore.ps1 -BackupPath "C:\WindowsBackup_20241103_153000"
```

## What restore.ps1 Does

The restore script **automates** the tedious parts of restoration:

✅ **Automatically restores:**
- Documents, Desktop, Pictures, Videos, Music
- SSH keys (with proper permissions fixed!)
- Git configuration
- VS Code settings, keybindings, snippets
- **VS Code extensions (automatically reinstalled!)**
- Windows Terminal settings
- Browser bookmarks
- Game configurations
- Dotfiles (.bashrc, .zshrc, etc.)

⚠️ **Requires manual steps** (script provides guidance):
- Reinstalling programs
- Re-creating environment variables
- Enabling Windows features

## Usage Examples

### Example 1: Full Automatic Restore

```powershell
# Run as Administrator
.\restore.ps1

# The script will:
# 1. Auto-detect backup folders
# 2. Restore to current user
# 3. Restore everything automatically
```

**Output:**
```
Found backup folders:
  [1] C:\WindowsBackup_20241103_153000

Using: C:\WindowsBackup_20241103_153000
Restore files for user 'NewUser'? (Y/n): Y

Will restore:
  ✓ Documents
  ✓ Desktop
  ✓ SSH
  ✓ Git
  ✓ VSCode
  ...

Proceed with restoration? (Y/n): Y

=== Restoring user folders... ===
[2024-11-03 16:00:00] [✓] Restored: Documents folder
[2024-11-03 16:02:30] [✓] Restored: Desktop folder
...
[2024-11-03 16:15:00] [i] Reinstalling VS Code extensions...
  [1/42] Installing ms-python.python...
  [2/42] Installing esbenp.prettier-vscode...
  ...
[2024-11-03 16:18:00] [✓] VS Code extensions reinstalled (42 extensions)

========================================
  RESTORATION COMPLETED!
========================================
```

### Example 2: Selective Restore (Interactive Menu)

```powershell
# Only restore what you choose
.\restore.ps1 -SelectiveRestore
```

**Output:**
```
Select what to restore:

User Folders:
  [1] Documents
  [2] Desktop
  [3] Pictures
  [4] Videos
  [5] Music
  [6] Downloads

Configurations:
  [7] SSH Keys
  [8] Git Config
  [9] VS Code Settings & Extensions
  [10] Windows Terminal
  [11] Browser Bookmarks
  [12] Game Configurations

  [A] All
  [N] None (I'll manually restore)

Enter your choices (comma-separated, e.g., 1,2,7,9 or A for all): 1,2,7,8,9
```

This lets you pick exactly what to restore!

### Example 3: Restore to Different User

```powershell
# Restore backup to a specific user
.\restore.ps1 -BackupPath "C:\WindowsBackup_20241103_153000" -TargetUser "NewUsername"
```

### Example 4: Skip User Files (Configs Only)

```powershell
# Only restore configurations, skip Documents/Desktop/etc.
.\restore.ps1 -SkipUserFiles
```

Useful if you've already manually copied your documents.

### Example 5: Dry Run (Preview)

```powershell
# See what would be restored without actually restoring
.\restore.ps1 -WhatIf
```

**Output:**
```
[WhatIf] Would restore: C:\WindowsBackup_...\Documents -> C:\Users\NewUser\Documents
[WhatIf] Would restore: C:\WindowsBackup_...\Desktop -> C:\Users\NewUser\Desktop
[WhatIf] Would copy: C:\WindowsBackup_...\GitConfig\.gitconfig -> C:\Users\NewUser\.gitconfig
...
```

## Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `-BackupPath` | String | Path to backup folder | `"C:\WindowsBackup_20241103_153000"` |
| `-TargetUser` | String | User to restore to (default: current) | `"NewUser"` |
| `-SelectiveRestore` | Switch | Show interactive menu | `-SelectiveRestore` |
| `-SkipUserFiles` | Switch | Don't restore Documents/Desktop/etc. | `-SkipUserFiles` |
| `-SkipConfigs` | Switch | Don't restore SSH/Git/VS Code/etc. | `-SkipConfigs` |
| `-WhatIf` | Switch | Preview without restoring | `-WhatIf` |

## Step-by-Step Restoration Process

### Step 1: Ensure You're on Fresh Windows

The restore script should be run on your **new** Windows installation.

```powershell
# Verify you're on the fresh install
echo $env:COMPUTERNAME
echo $env:USERNAME
```

### Step 2: Locate Your Backup

Your backup is in one of these locations:

- `C:\WindowsBackup_[timestamp]\` (if you backed up E: to C:)
- `D:\WindowsBackup_[timestamp]\` (if you backed up to external drive)
- `E:\WindowsBackup_[timestamp]\` (if stored on old drive)

```powershell
# Find all backup folders
Get-ChildItem C:\, D:\, E:\ -Filter "WindowsBackup_*" -Directory
```

### Step 3: Run the Restore Script

```powershell
# Open PowerShell as Administrator
# Navigate to script directory
cd C:\windows-reinstall-backup

# Run restore
.\restore.ps1
```

The script will:
1. Auto-detect backup folders
2. Verify backup is valid
3. Ask which user to restore to
4. Show restore plan
5. Ask for confirmation
6. Restore everything

### Step 4: Verify Restoration

After completion, verify:

```powershell
# Check documents restored
explorer C:\Users\YourName\Documents

# Check Desktop
explorer C:\Users\YourName\Desktop

# Test SSH keys
ssh -T git@github.com

# Check Git config
git config --list

# Launch VS Code and check extensions
code .
```

### Step 5: Manual Steps

The script will display what still needs manual attention:

```
Manual steps remaining:

📋 Programs to Reinstall:
  Check: C:\WindowsBackup_...\SystemConfig\InstalledPrograms.txt

🔧 Environment Variables:
  Review: C:\WindowsBackup_...\SystemConfig\EnvironmentVariables_User.txt

🪟 Windows Features:
  Check: C:\WindowsBackup_...\SystemConfig\WindowsFeatures.txt
```

## What Gets Restored Automatically

### ✅ User Files
- Documents folder → `C:\Users\[You]\Documents`
- Desktop folder → `C:\Users\[You]\Desktop`
- Pictures → `C:\Users\[You]\Pictures`
- Videos → `C:\Users\[You]\Videos`
- Music → `C:\Users\[You]\Music`
- Downloads → `C:\Users\[You]\Downloads`

### ✅ Development Configurations
- SSH keys → `C:\Users\[You]\.ssh` (permissions fixed automatically!)
- Git config → `C:\Users\[You]\.gitconfig`
- AWS credentials → `C:\Users\[You]\.aws`
- Kubernetes config → `C:\Users\[You]\.kube`
- Docker config → `C:\Users\[You]\.docker`
- Shell dotfiles → `.bashrc`, `.zshrc`, etc.

### ✅ Application Settings
- **VS Code settings** → `%APPDATA%\Code\User\settings.json`
- **VS Code keybindings** → `%APPDATA%\Code\User\keybindings.json`
- **VS Code snippets** → `%APPDATA%\Code\User\snippets\`
- **VS Code extensions** → Automatically reinstalled from list! 🎉
- Windows Terminal settings
- Chrome bookmarks
- Firefox profiles

### ✅ Game Configurations
- `Documents\My Games\`
- Game config files from AppData

## What Requires Manual Steps

### ⚠️ Programs
You need to **reinstall** programs. The script provides a list:

```powershell
# View programs to reinstall
notepad C:\WindowsBackup_...\SystemConfig\InstalledPrograms.txt
```

**Quick reinstall with winget:**

```powershell
# Example - install common programs
winget install Git.Git
winget install Microsoft.VisualStudioCode
winget install Google.Chrome
winget install Docker.DockerDesktop
winget install Python.Python.3.12
```

### ⚠️ Environment Variables

```powershell
# View backed up environment variables
notepad C:\WindowsBackup_...\SystemConfig\EnvironmentVariables_User.txt

# Manually re-create important ones
[System.Environment]::SetEnvironmentVariable("VARIABLE_NAME", "value", [System.EnvironmentVariableTarget]::User)
```

### ⚠️ Windows Features

```powershell
# View enabled features from old install
notepad C:\WindowsBackup_...\SystemConfig\WindowsFeatures.txt

# Enable features you need
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
```

## Troubleshooting

### "Backup path does not exist"

**Problem:** Can't find the backup folder

**Solution:**
```powershell
# Search all drives
Get-ChildItem C:\, D:\, E:\ -Filter "WindowsBackup_*" -Directory

# Use the correct path
.\restore.ps1 -BackupPath "D:\WindowsBackup_20241103_153000"
```

### "This doesn't appear to be a valid backup folder"

**Problem:** Missing expected backup files

**Solution:**
```powershell
# Verify backup contains expected files
Get-ChildItem C:\WindowsBackup_20241103_153000

# Should see: RESTORATION_GUIDE.md, BackupLog.txt, Documents, Desktop, etc.
# If present but script complains, choose "Continue anyway"
```

### SSH Keys Not Working After Restore

**Problem:** SSH authentication fails

**Solution:**
The script automatically fixes permissions, but if it fails:

```powershell
# Manually fix SSH permissions
$sshPath = "$env:USERPROFILE\.ssh"
icacls $sshPath /inheritance:r
icacls $sshPath /grant:r "${env:USERNAME}:(OI)(CI)F"

Get-ChildItem $sshPath -File | ForEach-Object {
    icacls $_.FullName /inheritance:r
    icacls $_.FullName /grant:r "${env:USERNAME}:F"
}

# Test
ssh -T git@github.com
```

### VS Code Extensions Not Installing

**Problem:** Extensions fail to install

**Solution:**
```powershell
# Make sure VS Code is installed first
winget install Microsoft.VisualStudioCode

# Manually reinstall extensions
$backupPath = "C:\WindowsBackup_20241103_153000"
Get-Content "$backupPath\VSCodeSettings\extensions.txt" | ForEach-Object {
    Write-Host "Installing $_..."
    code --install-extension $_ --force
}
```

### "Script must be run as Administrator"

**Problem:** Missing admin rights

**Solution:**
- Right-click PowerShell
- Select "Run as Administrator"
- Navigate to script and run again

### Files Already Exist - Overwrite?

**Problem:** Target folders already have files

**Solution:**
Robocopy will merge folders and skip identical files. New files from backup will be added, existing files won't be overwritten unless different.

To force overwrite, manually delete target folders first (be careful!):

```powershell
# DANGER: This deletes existing files!
# Only if you're sure you want to replace everything
Remove-Item "C:\Users\YourName\Documents" -Recurse -Force
Remove-Item "C:\Users\YourName\Desktop" -Recurse -Force

# Then run restore
.\restore.ps1
```

## Advanced Scenarios

### Restore to Different Drive

If your user profile is on a different drive:

```powershell
# This won't work - script assumes C:\Users\[Username]
# You'll need to manually copy files or modify the script

# Manual alternative:
$backupPath = "D:\WindowsBackup_20241103_153000"
$targetPath = "E:\Users\YourName"

Copy-Item "$backupPath\Documents\*" "$targetPath\Documents" -Recurse -Force
Copy-Item "$backupPath\Desktop\*" "$targetPath\Desktop" -Recurse -Force
# etc...
```

### Restore Only Specific Items

```powershell
# Use selective restore
.\restore.ps1 -SelectiveRestore

# Or use switches
.\restore.ps1 -SkipUserFiles  # Only configs, no Documents/Desktop
.\restore.ps1 -SkipConfigs    # Only user files, no SSH/Git/VS Code
```

### Multiple Backups - Which One?

```powershell
# List all backups with creation time
Get-ChildItem C:\, D:\ -Filter "WindowsBackup_*" -Directory |
    Select-Object FullName, CreationTime |
    Sort-Object CreationTime -Descending

# Use the most recent or specific one
.\restore.ps1 -BackupPath "C:\WindowsBackup_20241103_183000"
```

## Post-Restoration Checklist

After running `restore.ps1`, go through this checklist:

### ✅ Files & Folders
- [ ] Documents accessible and correct
- [ ] Desktop items visible
- [ ] Pictures, Videos, Music present
- [ ] Project files intact

### ✅ Development Environment
- [ ] SSH keys work: `ssh -T git@github.com`
- [ ] Git configured: `git config --list`
- [ ] VS Code opens with settings
- [ ] VS Code extensions installed
- [ ] Terminal theme/profile correct

### ✅ Programs (Manual)
- [ ] Check `InstalledPrograms.txt`
- [ ] Reinstall essential programs
- [ ] Verify programs launch correctly

### ✅ System Configuration (Manual)
- [ ] Review `EnvironmentVariables_User.txt`
- [ ] Re-create important environment variables
- [ ] Enable required Windows features
- [ ] Test: WSL, Docker, Hyper-V, etc.

### ✅ Browser & Apps
- [ ] Sign in to browser (for full sync)
- [ ] Bookmarks restored
- [ ] Check saved passwords synced
- [ ] Reinstall: Spotify, Discord, etc.

### ✅ Games
- [ ] Game configs restored
- [ ] Reinstall games via Steam/Epic/etc.
- [ ] Verify save files recognized

## Summary

The `restore.ps1` script automates ~80% of the restoration work:

✅ **Automated:**
- All user files copied
- All configs restored
- SSH permissions fixed
- VS Code extensions reinstalled
- Everything ready to use

⚠️ **Manual (5-10 minutes):**
- Reinstall programs (use winget for speed)
- Re-create environment variables
- Enable Windows features
- Sign in to apps/browsers

---

**Total time:**
- Script: 15-30 minutes (depending on data size)
- Manual steps: 10-20 minutes
- **Much faster than manual restoration!** 🚀

Enjoy your restored Windows installation!
