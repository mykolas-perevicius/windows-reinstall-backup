# Windows Reinstall Backup Script

A comprehensive PowerShell script for backing up user data, configurations, and settings before a clean Windows reinstall. Intelligently copies only safe, necessary files while excluding system files that would break on a fresh install.

## Features

- **Smart Backup**: Automatically identifies and backs up user data, development configs, and application settings
- **System Config Export**: Captures environment variables, installed programs, and Windows features
- **Safety Checks**: Verifies space, detects existing backups, and warns about large folders
- **Progress Tracking**: Real-time progress indicators with detailed logging
- **Dry Run Mode**: Preview what will be backed up without copying files
- **Restoration Guide**: Auto-generates step-by-step instructions for restoring everything
- **Compression Support**: Optional ZIP compression to save space
- **Detailed Logging**: Complete audit trail of all backup operations

## Quick Start

```powershell
# Clone the repository
git clone https://github.com/[yourname]/windows-reinstall-backup
cd windows-reinstall-backup

# Run backup to drive D: (will prompt for confirmation)
.\backup.ps1 -TargetDrive D
```

## Prerequisites

- **Windows 10 or 11**
- **PowerShell 5.1 or later** (pre-installed on Windows 10/11)
- **Administrator privileges** (script will check and prompt)
- **External drive** with sufficient free space (10GB+ recommended)
- **Robocopy** (included with Windows)

## Installation

### Option 1: Clone via Git

```powershell
git clone https://github.com/[yourname]/windows-reinstall-backup
cd windows-reinstall-backup
```

### Option 2: Download ZIP

1. Download ZIP from [Releases](https://github.com/[yourname]/windows-reinstall-backup/releases)
2. Extract to a folder
3. Open PowerShell as Administrator
4. Navigate to the extracted folder

### Option 3: Direct Download

```powershell
# Download the script directly
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/[yourname]/windows-reinstall-backup/main/backup.ps1" -OutFile "backup.ps1"
```

## Usage

### Basic Usage

```powershell
# Standard backup to drive D:
.\backup.ps1 -TargetDrive D

# Backup specific user
.\backup.ps1 -TargetDrive D -Username "JohnDoe"

# Exclude Downloads folder
.\backup.ps1 -TargetDrive D -ExcludeDownloads

# Compress backup into ZIP
.\backup.ps1 -TargetDrive D -Compress
```

### Dry Run (Preview)

See what would be backed up without actually copying:

```powershell
.\backup.ps1 -TargetDrive D -WhatIf
```

### Advanced Options

```powershell
# Combine options
.\backup.ps1 -TargetDrive E -Username "JohnDoe" -ExcludeDownloads -Compress -Verbose
```

## Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `-TargetDrive` | String | Drive letter for backup destination | `D`, `E` |
| `-Username` | String | Windows username to backup (default: current user) | `JohnDoe` |
| `-ExcludeDownloads` | Switch | Skip backing up Downloads folder | `-ExcludeDownloads` |
| `-Compress` | Switch | Create ZIP archive after backup | `-Compress` |
| `-WhatIf` | Switch | Preview without copying files | `-WhatIf` |
| `-Verbose` | Switch | Show detailed output | `-Verbose` |

## What Gets Backed Up

### User Folders (Full Copy)
- ✅ Documents
- ✅ Desktop
- ✅ Pictures
- ✅ Videos
- ✅ Music
- ✅ Downloads (optional, with size warning if >50GB)

### Development & Config Files
- ✅ `.ssh/` directory (SSH keys)
- ✅ `.gitconfig` (Git configuration)
- ✅ `.aws/` (AWS credentials, if exists)
- ✅ `.kube/` (Kubernetes config, if exists)
- ✅ `.docker/` (Docker config, if exists)
- ✅ Dotfiles (`.bashrc`, `.zshrc`, `.npmrc`, etc.)

### VS Code Settings
- ✅ `settings.json`
- ✅ `keybindings.json`
- ✅ `snippets/` folder
- ✅ Installed extensions list (exported as text file)

### Windows Terminal
- ✅ `settings.json` (themes, profiles, keybindings)

### Browser Data (Selective)
- ✅ Chrome bookmarks
- ✅ Firefox profiles
- ℹ️ Note: Sync should be enabled for full browser data

### Game Configurations
- ✅ `Documents\My Games\` folder
- ✅ Game config files from AppData (`.cfg`, `.ini`, `.json`)
- ✅ Common game launchers configs (Steam, Epic, Blizzard, etc.)

### Application Settings
- ✅ Spotify, Discord, Slack, OBS, VLC (from AppData\Roaming)

### System Configuration Exports
- ✅ Environment variables (User & System)
- ✅ Installed programs list
- ✅ Windows optional features
- ✅ PowerShell modules
- ✅ Network adapter configuration
- ✅ System information

## What Gets Excluded

To ensure a clean restoration and avoid compatibility issues, the script **excludes**:

- ❌ `C:\Program Files\` and `C:\Program Files (x86)\`
- ❌ `C:\Windows\`
- ❌ `C:\ProgramData\`
- ❌ `.exe`, `.dll`, `.sys` files outside user directories
- ❌ `node_modules/` folders (too large, reinstall via `npm install`)
- ❌ Virtual environments (`venv/`, `.venv/`, `env/`)
- ❌ `__pycache__/` directories
- ❌ Temporary files and caches

**Why?** These files are system-specific and would cause conflicts or errors on a fresh Windows install. Applications should be reinstalled, not copied.

## Backup Directory Structure

```
D:\WindowsBackup_20240315_143022\
├── Projects\
├── Documents\
├── Desktop\
├── Pictures\
├── Videos\
├── Music\
├── Downloads\
├── SSHKeys\
├── GitConfig\
│   ├── .gitconfig
│   ├── .aws\
│   └── .kube\
├── VSCodeSettings\
│   ├── settings.json
│   ├── keybindings.json
│   ├── snippets\
│   └── extensions.txt
├── TerminalSettings\
│   └── settings.json
├── GameConfigs\
│   └── My Games\
├── AppDataRoaming_Selected\
│   ├── Spotify\
│   └── Discord\
├── AppDataLocal_Selected\
├── BrowserData\
│   ├── Chrome_Bookmarks.json
│   └── Firefox_Profiles\
├── SystemConfig\
│   ├── EnvironmentVariables_User.txt
│   ├── EnvironmentVariables_System.txt
│   ├── InstalledPrograms.txt
│   ├── InstalledPrograms.csv
│   ├── WindowsFeatures.csv
│   ├── PowerShellModules.csv
│   └── SystemInfo.txt
├── RESTORATION_GUIDE.md
├── BACKUP_SUMMARY.txt
├── BackupLog.txt
└── robocopy_log.txt
```

## Restoring After Fresh Install

After completing your fresh Windows installation:

1. **Connect backup drive** and verify backup folder exists
2. **Open PowerShell as Administrator**
3. **Navigate to backup folder**:
   ```powershell
   cd D:\WindowsBackup_20240315_143022
   ```
4. **Open the restoration guide**:
   ```powershell
   notepad RESTORATION_GUIDE.md
   ```
5. **Follow the step-by-step checklist** in the restoration guide

The `RESTORATION_GUIDE.md` file contains:
- Pre-restoration checklist
- PowerShell commands to restore files
- Instructions for reinstalling programs
- How to restore environment variables
- VS Code extension reinstallation
- Post-restoration verification checklist

### Quick Restore Example

```powershell
# Set backup path
$backupPath = "D:\WindowsBackup_20240315_143022"
$userPath = "C:\Users\YourUsername"

# Restore user folders
Copy-Item "$backupPath\Documents\*" "$userPath\Documents" -Recurse -Force
Copy-Item "$backupPath\Desktop\*" "$userPath\Desktop" -Recurse -Force

# Restore SSH keys
Copy-Item "$backupPath\SSHKeys\*" "$userPath\.ssh" -Recurse -Force

# Restore Git config
Copy-Item "$backupPath\GitConfig\.gitconfig" "$userPath\.gitconfig" -Force

# Restore VS Code settings
$vscodeUser = "$env:APPDATA\Code\User"
Copy-Item "$backupPath\VSCodeSettings\settings.json" "$vscodeUser\settings.json" -Force
Copy-Item "$backupPath\VSCodeSettings\keybindings.json" "$vscodeUser\keybindings.json" -Force

# Reinstall VS Code extensions
Get-Content "$backupPath\VSCodeSettings\extensions.txt" | ForEach-Object {
    code --install-extension $_
}
```

## Execution Policy

If you encounter an error about execution policy:

```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy to allow script execution (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or bypass for single execution
PowerShell.exe -ExecutionPolicy Bypass -File .\backup.ps1 -TargetDrive D
```

## Troubleshooting

### "Script must be run as Administrator"

**Solution**: Right-click PowerShell and select "Run as Administrator"

```powershell
# Or elevate from current session:
Start-Process powershell -Verb runAs
```

### "Drive does not exist"

**Solution**: Verify the external drive is connected and note its letter

```powershell
# List available drives
Get-PSDrive -PSProvider FileSystem
```

### "Not enough space"

**Solution**: Check backup size estimate and free up space or use a larger drive

```powershell
# Check space on target drive
Get-PSDrive D | Select-Object Name, @{Name="Free(GB)";Expression={[math]::Round($_.Free/1GB,2)}}

# Estimate user folder sizes
Get-ChildItem C:\Users\YourUsername -Directory | ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    [PSCustomObject]@{
        Folder = $_.Name
        SizeGB = [math]::Round($size / 1GB, 2)
    }
} | Sort-Object SizeGB -Descending
```

### Robocopy Errors

Robocopy exit codes:
- **0-7**: Success (0 = no files copied, 1 = files copied, 2 = extra files/dirs, etc.)
- **8+**: Errors occurred

Check `robocopy_log.txt` in the backup folder for details.

### SSH Keys Not Working After Restore

**Solution**: Fix permissions on `.ssh` folder

```powershell
icacls "$env:USERPROFILE\.ssh" /inheritance:r
icacls "$env:USERPROFILE\.ssh" /grant:r "${env:USERNAME}:(OI)(CI)F"
```

### Very Slow Backup

**Possible causes**:
- Large Downloads folder (use `-ExcludeDownloads`)
- Slow external drive (USB 2.0 vs USB 3.0)
- Antivirus scanning files during copy (temporarily disable)
- Many small files (normal for node_modules, which are excluded)

## Best Practices

### Before Running Backup

- [ ] Close all applications (especially browsers, VS Code, games)
- [ ] Ensure external drive has sufficient space (check with `-WhatIf`)
- [ ] Verify drive is connected via USB 3.0 or faster
- [ ] Run Windows Update to ensure latest OS version is backed up

### After Backup

- [ ] Review `BACKUP_SUMMARY.txt`
- [ ] Check `BackupLog.txt` for any errors
- [ ] Verify a few critical files exist in the backup
- [ ] Test opening a few backed up files
- [ ] Keep backup drive in safe location during reinstall
- [ ] Consider a second backup of truly irreplaceable files (photos, projects)

### Security Considerations

- 🔒 **Backup contains sensitive data**: SSH keys, credentials, tokens
- 🔒 **Keep backup drive secure**: Store in a safe place
- 🔒 **Encrypt if possible**: Consider BitLocker or VeraCrypt for the backup drive
- 🔒 **Delete after restoration**: Securely wipe backup after successful restore
- 🔒 **Don't share**: Never upload backup to public cloud or share with others

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Reporting Issues

If you encounter a bug or have a feature request:

1. Check [existing issues](https://github.com/[yourname]/windows-reinstall-backup/issues)
2. Create a new issue with:
   - Windows version
   - PowerShell version (`$PSVersionTable.PSVersion`)
   - Error message or unexpected behavior
   - Steps to reproduce

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly on Windows 10 and 11
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Frequently Asked Questions

### Can I backup to a network drive?

Yes, but it will be slower than a local USB drive. Use the UNC path:

```powershell
# Map network drive first
New-PSDrive -Name "Z" -PSProvider FileSystem -Root "\\NetworkServer\Share"

# Then run backup
.\backup.ps1 -TargetDrive Z
```

### Does this work on Windows Server?

Yes, the script is compatible with Windows Server 2016 and newer.

### Can I run this on a schedule?

Yes, create a scheduled task:

```powershell
# Create scheduled task (weekly backup)
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\path\to\backup.ps1 -TargetDrive D"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2am
Register-ScheduledTask -TaskName "WeeklyBackup" -Action $action -Trigger $trigger -RunLevel Highest
```

### What if I have multiple Windows installations?

Specify the username explicitly:

```powershell
.\backup.ps1 -TargetDrive D -Username "OtherUser"
```

### Can I backup to the same drive as Windows?

Not recommended, but technically possible. However, it defeats the purpose of having a backup before reinstalling Windows. Always use a separate drive.

## Changelog

### v1.0.0 (2024-03-15)
- Initial release
- User folder backup
- Development config backup
- Application settings backup
- System configuration export
- Interactive prompts and safety checks
- Dry run mode
- Compression support
- Auto-generated restoration guide

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with PowerShell and Robocopy
- Inspired by the need for safe Windows reinstalls
- Community feedback and contributions

## Support

If this script helped you, consider:
- ⭐ Starring the repository
- 🐛 Reporting bugs
- 💡 Suggesting features
- 📖 Improving documentation

## Disclaimer

This script is provided as-is, without warranty. Always verify backups before proceeding with system changes. The author is not responsible for data loss. Test thoroughly and maintain multiple backups of critical data.

---

**Made with ❤️ for the Windows community**
