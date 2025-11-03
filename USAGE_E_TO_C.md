# Backing Up From E: Drive to C: Drive

**Your Scenario:** You've already done a fresh Windows install on C: and want to backup your old Windows installation on E: before wiping it.

## Quick Commands for Your Setup

### Step 1: Find Your Old Username

First, check what username was on the E: drive:

```powershell
# List users on E: drive
Get-ChildItem E:\Users
```

You'll see folders like:
- `Administrator`
- `Public`
- `YourOldUsername` ← This is what you need!

### Step 2: Run the Backup

```powershell
# Navigate to where you have the script
cd C:\path\to\windows-reinstall-backup

# Run backup FROM E: TO C:
.\backup.ps1 -SourceDrive E -TargetDrive C -Username "YourOldUsername"
```

Replace `YourOldUsername` with the actual username you found in Step 1.

### Step 3: What Will Happen

The script will:
1. Look for user data on **E:\Users\YourOldUsername**
2. Create backup folder on **C:\WindowsBackup_[timestamp]**
3. Copy all your old data from E: to C:

**Example:**
```
Source: E:\Users\OldUser\Documents  →  C:\WindowsBackup_20241103_153000\Documents
Source: E:\Users\OldUser\Desktop   →  C:\WindowsBackup_20241103_153000\Desktop
Source: E:\Users\OldUser\.ssh      →  C:\WindowsBackup_20241103_153000\SSHKeys
... etc
```

## Full Example Session

```powershell
PS C:\Users\NewUser> cd C:\windows-reinstall-backup

PS C:\windows-reinstall-backup> .\backup.ps1 -SourceDrive E -TargetDrive C -Username "OldUser"

╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║        Windows Reinstall Backup Script v1.0                 ║
║        Safe backup of user data and configurations          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

[2024-11-03 15:30:00] [i] Backup will be created at: C:\WindowsBackup_20241103_153000
[2024-11-03 15:30:00] [i] Available space on C: 450.00 GB

Backup Configuration:
  Source Drive:      E: (E:\Users\OldUser)
  Target Drive:      C: (C:\WindowsBackup_20241103_153000)
  Username:          OldUser
  Exclude Downloads: False
  Compress:          False

Proceed with backup? (Y/n): Y

=== Creating backup directory structure... ===
[2024-11-03 15:30:05] [✓] Directory structure created successfully

=== Backing up user folders... ===
[2024-11-03 15:30:06] [i] Backing up: Documents folder
... (continues backing up everything from E: drive)
```

## After Backup Completes

Your C: drive will have:

```
C:\WindowsBackup_20241103_153000\
├── Documents\          ← From E:\Users\OldUser\Documents
├── Desktop\            ← From E:\Users\OldUser\Desktop
├── Pictures\           ← From E:\Users\OldUser\Pictures
├── SSHKeys\            ← From E:\Users\OldUser\.ssh
├── VSCodeSettings\     ← From E:\Users\OldUser\AppData\...
├── RESTORATION_GUIDE.md ← How to restore everything
└── ... (all your backed up data)
```

## Important Notes for Your Setup

### ✅ Safe to Do:
- Backup E: → C: (what you're doing)
- E: and C: are different physical drives
- C: has enough space to hold the backup

### ⚠️ Before Wiping E: Drive:
1. **Verify backup completed successfully**
   ```powershell
   # Check the backup summary
   notepad C:\WindowsBackup_20241103_153000\BACKUP_SUMMARY.txt
   ```

2. **Test a few critical files**
   ```powershell
   # Make sure you can open some important files from the backup
   explorer C:\WindowsBackup_20241103_153000\Documents
   ```

3. **Check for errors**
   ```powershell
   # Review the detailed log
   notepad C:\WindowsBackup_20241103_153000\BackupLog.txt
   ```

4. **Verify everything you need is backed up**
   - Important documents
   - Photos
   - SSH keys
   - Project files
   - Game saves

## Restoring Data Later

Since you're already on your fresh C: installation, you don't need to "restore" - just copy what you need:

### Option 1: Manually Copy What You Need

```powershell
# Copy documents back to your new user
Copy-Item "C:\WindowsBackup_20241103_153000\Documents\*" "C:\Users\NewUser\Documents" -Recurse

# Copy SSH keys
Copy-Item "C:\WindowsBackup_20241103_153000\SSHKeys\*" "C:\Users\NewUser\.ssh" -Recurse

# Copy Git config
Copy-Item "C:\WindowsBackup_20241103_153000\GitConfig\.gitconfig" "C:\Users\NewUser\.gitconfig"

# Etc...
```

### Option 2: Follow the Restoration Guide

```powershell
# Open the auto-generated guide
notepad C:\WindowsBackup_20241103_153000\RESTORATION_GUIDE.md
```

This has step-by-step PowerShell commands you can copy-paste.

## What Happens to E: Drive?

After you verify the backup:
1. The backup is safely on C:
2. You can now wipe/format E: drive
3. Or repurpose E: for other storage
4. The backup on C: has everything you need

## Troubleshooting

### "User profile path does not exist: E:\Users\OldUser"

**Problem:** Username is wrong or doesn't exist on E:

**Solution:**
```powershell
# Check actual users on E:
Get-ChildItem E:\Users

# Use the correct username
.\backup.ps1 -SourceDrive E -TargetDrive C -Username "CorrectUsername"
```

### "Source drive E: does not exist!"

**Problem:** E: drive not connected or wrong letter

**Solution:**
```powershell
# Check available drives
Get-PSDrive -PSProvider FileSystem

# Use correct drive letter
.\backup.ps1 -SourceDrive [CorrectLetter] -TargetDrive C -Username "OldUser"
```

### "Not enough space on C:"

**Problem:** Backup is too large for C: drive

**Solution 1: Exclude Downloads**
```powershell
.\backup.ps1 -SourceDrive E -TargetDrive C -Username "OldUser" -ExcludeDownloads
```

**Solution 2: Use compression**
```powershell
.\backup.ps1 -SourceDrive E -TargetDrive C -Username "OldUser" -Compress
```

**Solution 3: Backup to external drive instead**
```powershell
# If you have an external drive D:
.\backup.ps1 -SourceDrive E -TargetDrive D -Username "OldUser"
```

## Preview First (Recommended!)

Before running the actual backup, do a dry run to see what will be backed up:

```powershell
.\backup.ps1 -SourceDrive E -TargetDrive C -Username "OldUser" -WhatIf
```

This will show you:
- What folders will be backed up
- Where they'll be copied to
- **Without actually copying anything**

Then run the real backup when you're confident.

---

## Summary for Your Exact Scenario

```powershell
# 1. Check old username on E:
Get-ChildItem E:\Users

# 2. Preview the backup (dry run)
.\backup.ps1 -SourceDrive E -TargetDrive C -Username "YourOldUsername" -WhatIf

# 3. Run the actual backup
.\backup.ps1 -SourceDrive E -TargetDrive C -Username "YourOldUsername"

# 4. Verify it completed
notepad C:\WindowsBackup_[timestamp]\BACKUP_SUMMARY.txt

# 5. Now you can safely wipe E: drive!
```

Your data from E: is now safely backed up on C:! 🎉
