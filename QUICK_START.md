# Quick Start Guide

**TL;DR:** Run this script before wiping your Windows installation to backup everything important.

## 30-Second Quick Start

```powershell
# 1. Open PowerShell as Administrator (right-click, "Run as Administrator")
cd C:\path\to\windows-reinstall-backup

# 2. Run the backup to your external drive (e.g., D:)
.\backup.ps1 -TargetDrive D

# 3. Follow the prompts, confirm, and wait for completion

# 4. After fresh Windows install, open D:\WindowsBackup_[timestamp]\RESTORATION_GUIDE.md
```

## Visual Step-by-Step

### Before Windows Reinstall

```
┌─────────────────────────────────────────────────────────┐
│ 1. Connect External Drive                              │
│    - At least 10GB free space                          │
│    - Note the drive letter (D:, E:, etc.)              │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 2. Close All Applications                              │
│    - Browsers, VS Code, games, etc.                    │
│    - Ensures all files can be copied                   │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 3. Open PowerShell as Administrator                    │
│    - Press Win + X → "Windows PowerShell (Admin)"      │
│    - Or search "PowerShell", right-click, "Run as Admin│
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 4. Navigate to Script Directory                        │
│    cd C:\path\to\windows-reinstall-backup              │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 5. (Optional) Preview What Will Be Backed Up           │
│    .\backup.ps1 -TargetDrive D -WhatIf                 │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 6. Run The Backup                                      │
│    .\backup.ps1 -TargetDrive D                         │
│                                                         │
│    Add flags as needed:                                │
│    -ExcludeDownloads (skip Downloads folder)           │
│    -Compress (create ZIP file)                         │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 7. Review The Results                                  │
│    - Check BACKUP_SUMMARY.txt                          │
│    - Verify a few critical files exist in backup       │
│    - Keep backup drive safe during reinstall           │
└─────────────────────────────────────────────────────────┘
```

### After Fresh Windows Install

```
┌─────────────────────────────────────────────────────────┐
│ 1. Connect Backup Drive                                │
│    - Same drive used for backup                        │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 2. Navigate to Backup Folder                           │
│    D:\WindowsBackup_20240315_143022\                   │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 3. Open RESTORATION_GUIDE.md                           │
│    - Contains step-by-step restoration instructions    │
│    - PowerShell commands ready to copy-paste           │
│    - Checklist format for verification                 │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ 4. Follow The Checklist                                │
│    - Restore user files                                │
│    - Reinstall programs                                │
│    - Restore configurations                            │
│    - Verify everything works                           │
└─────────────────────────────────────────────────────────┘
```

## Common Scenarios

### Scenario 1: Standard Backup (Most Common)

```powershell
.\backup.ps1 -TargetDrive D
```

**When to use:**
- Normal Windows reinstall
- Have sufficient space on backup drive
- Want to keep Downloads folder

---

### Scenario 2: Backup Without Downloads

```powershell
.\backup.ps1 -TargetDrive D -ExcludeDownloads
```

**When to use:**
- Downloads folder is very large (>50GB)
- Running low on backup drive space
- Downloads folder contains mostly temporary/reinstallable files

---

### Scenario 3: Compressed Backup

```powershell
.\backup.ps1 -TargetDrive D -Compress
```

**When to use:**
- Want a single ZIP file for easier management
- Need to save space on backup drive
- Planning to move backup to another location

---

### Scenario 4: Preview First (Dry Run)

```powershell
# Preview what would be backed up
.\backup.ps1 -TargetDrive D -WhatIf

# Then run actual backup
.\backup.ps1 -TargetDrive D
```

**When to use:**
- First time using the script
- Want to verify what will be backed up
- Checking if you have enough space

---

### Scenario 5: Backup Specific User

```powershell
.\backup.ps1 -TargetDrive D -Username "JohnDoe"
```

**When to use:**
- Multiple user accounts on the PC
- Backing up someone else's profile
- Not logged in as the user to backup

---

### Scenario 6: Maximum Space Saving

```powershell
.\backup.ps1 -TargetDrive D -ExcludeDownloads -Compress
```

**When to use:**
- Limited backup drive space
- Want smallest possible backup
- Don't need Downloads folder

---

## Expected Output

When running the script, you'll see:

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║        Windows Reinstall Backup Script v1.0                 ║
║        Safe backup of user data and configurations          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

[2024-03-15 14:30:22] [i] Available drives:
  D: - 500.00 GB free
  E: - 250.00 GB free

Enter target drive letter (e.g., D, E): D

Backup user profile for 'YourUsername'? (Y/n): Y

[2024-03-15 14:30:25] [i] Backup will be created at: D:\WindowsBackup_20240315_143022
[2024-03-15 14:30:25] [i] Available space on D: 500.00 GB

Backup Configuration:
  User:              YourUsername
  Target:            D:\WindowsBackup_20240315_143022
  Exclude Downloads: False
  Compress:          False

Proceed with backup? (Y/n): Y

=== Creating backup directory structure... ===
[2024-03-15 14:30:30] [✓] Directory structure created successfully

=== Backing up user folders... ===
[2024-03-15 14:30:31] [i] Backing up: Documents folder
[2024-03-15 14:32:15] [✓] Completed: Documents folder
[2024-03-15 14:32:15] [i] Backing up: Desktop folder
[2024-03-15 14:32:45] [✓] Completed: Desktop folder
...
```

## Typical Backup Duration

| Data Size | Duration (Estimate) |
|-----------|---------------------|
| 10 GB     | 5-10 minutes        |
| 50 GB     | 15-30 minutes       |
| 100 GB    | 30-60 minutes       |
| 500 GB    | 2-4 hours           |

**Factors affecting speed:**
- USB 2.0 vs USB 3.0/3.1
- HDD vs SSD backup drive
- Number of small files vs large files
- Antivirus scanning during copy

## What You'll Get

After completion, your backup drive will contain:

```
D:\WindowsBackup_20240315_143022\
├── 📁 Documents/              ← Your documents
├── 📁 Desktop/                ← Desktop files
├── 📁 Pictures/               ← Photos
├── 📁 Videos/                 ← Videos
├── 📁 Music/                  ← Music
├── 📁 SSHKeys/                ← SSH keys (SENSITIVE!)
├── 📁 VSCodeSettings/         ← VS Code config
├── 📄 RESTORATION_GUIDE.md    ← ⭐ START HERE after fresh install
├── 📄 BACKUP_SUMMARY.txt      ← What was backed up
└── 📄 BackupLog.txt           ← Detailed log
```

## Troubleshooting Quick Reference

| Problem | Solution |
|---------|----------|
| "Script must be run as Administrator" | Right-click PowerShell → "Run as Administrator" |
| "Drive does not exist" | Check drive letter with `Get-PSDrive` |
| "Not enough space" | Use `-ExcludeDownloads` or `-Compress` |
| "Execution Policy" | Run: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| Script is slow | Normal for large data; close other programs; check USB 3.0 |

## Getting Help

1. Check the [README.md](README.md) for full documentation
2. Review [VERIFICATION_CHECKLIST.md](VERIFICATION_CHECKLIST.md) for known issues
3. Check [BackupLog.txt](BackupLog.txt) in your backup folder for errors
4. Report issues: https://github.com/[yourname]/windows-reinstall-backup/issues

## Pro Tips

💡 **Run a dry run first:**
```powershell
.\backup.ps1 -TargetDrive D -WhatIf
```

💡 **Close all apps before backing up:**
- Browsers (Chrome, Firefox)
- Code editors (VS Code)
- Games and game launchers
- File explorers

💡 **Verify backup before reinstalling:**
- Open a few backed up files
- Check BACKUP_SUMMARY.txt
- Look for any errors in BackupLog.txt

💡 **Keep backup drive safe:**
- Don't format it during Windows reinstall
- Store securely (contains SSH keys!)
- Consider encrypting the drive

💡 **After restoration:**
- Delete the backup from the drive (securely wipe)
- Or keep as a long-term backup
- Enable cloud sync to avoid this in the future

---

**Ready to go?** Open PowerShell as Admin and run:

```powershell
.\backup.ps1 -TargetDrive D
```

Good luck with your Windows reinstall! 🚀
