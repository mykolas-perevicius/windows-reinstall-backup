# Example Script Output

This document shows what you can expect to see when running the backup script.

## Console Output Example

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

Backup user profile for 'JohnDoe'? (Y/n): Y

[2024-03-15 14:30:25] [i] Backup will be created at: D:\WindowsBackup_20240315_143022
[2024-03-15 14:30:25] [i] Available space on D: 500.00 GB

Backup Configuration:
  User:              JohnDoe
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
[2024-03-15 14:32:45] [i] Backing up: Pictures folder
[2024-03-15 14:35:20] [✓] Completed: Pictures folder
[2024-03-15 14:35:20] [i] Backing up: Videos folder
[2024-03-15 14:40:10] [✓] Completed: Videos folder
[2024-03-15 14:40:10] [i] Backing up: Music folder
[2024-03-15 14:42:30] [✓] Completed: Music folder
[2024-03-15 14:42:30] [i] Backing up: Downloads folder
[2024-03-15 14:45:00] [✓] Completed: Downloads folder

=== Backing up development configurations... ===
[2024-03-15 14:45:01] [i] Backing up: SSH keys
[2024-03-15 14:45:02] [✓] Completed: SSH keys
[2024-03-15 14:45:02] [!] IMPORTANT: SSH keys backed up - keep this backup secure!
[2024-03-15 14:45:02] [✓] Git config backed up
[2024-03-15 14:45:03] [!] Skipping AWS configuration (source not found)
[2024-03-15 14:45:03] [!] Skipping Kubernetes configuration (source not found)
[2024-03-15 14:45:03] [!] Skipping Docker configuration (source not found)

=== Backing up VS Code settings... ===
[2024-03-15 14:45:04] [i] Exporting VS Code extensions list...
[2024-03-15 14:45:05] [✓] VS Code extensions list exported
[2024-03-15 14:45:05] [✓] VS Code settings backed up

=== Backing up Windows Terminal settings... ===
[2024-03-15 14:45:06] [✓] Windows Terminal settings backed up

=== Backing up browser data... ===
[2024-03-15 14:45:07] [✓] Chrome bookmarks backed up
[2024-03-15 14:45:08] [i] Backing up: Firefox profiles
[2024-03-15 14:45:10] [✓] Completed: Firefox profiles

=== Scanning for game configurations... ===
[2024-03-15 14:45:11] [i] Backing up: My Games folder
[2024-03-15 14:46:30] [✓] Completed: My Games folder
[2024-03-15 14:46:31] [✓] Backed up Steam configs
[2024-03-15 14:46:32] [✓] Backed up Epic configs

=== Backing up selected AppData folders... ===
[2024-03-15 14:46:33] [i] Backing up: Spotify settings
[2024-03-15 14:46:35] [✓] Completed: Spotify settings
[2024-03-15 14:46:35] [i] Backing up: Discord settings
[2024-03-15 14:46:37] [✓] Completed: Discord settings

=== Exporting system configuration... ===
[2024-03-15 14:46:38] [i] Exporting environment variables...
[2024-03-15 14:46:39] [✓] Environment variables exported
[2024-03-15 14:46:40] [i] Exporting installed programs list...
[2024-03-15 14:46:42] [✓] Installed programs list exported (127 programs)
[2024-03-15 14:46:43] [i] Exporting Windows optional features...
[2024-03-15 14:46:45] [✓] Windows features exported (15 enabled features)
[2024-03-15 14:46:46] [i] Exporting Windows Store apps...
[2024-03-15 14:46:48] [i] Exporting network configuration...
[2024-03-15 14:46:49] [i] Exporting PowerShell modules...
[2024-03-15 14:46:50] [✓] System configuration exported

=== Generating restoration guide... ===
[2024-03-15 14:46:51] [✓] Restoration guide created

=== Finalizing backup... ===


=============================================================================
                     WINDOWS BACKUP SUMMARY
=============================================================================

Backup Date/Time:    2024-03-15 14:46:52
Backup Location:     D:\WindowsBackup_20240315_143022
Source User:         JohnDoe
Source Computer:     DESKTOP-ABC123
Duration:            00:16:30
Total Size:          85.43 GB

=============================================================================
                         BACKUP CONTENTS
=============================================================================

User Folders:
  • Documents
  • Desktop
  • Pictures
  • Videos
  • Music
  • Downloads

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

Files Backed Up:     15 major categories
Errors Encountered:  0
Items Skipped:       3

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


[2024-03-15 14:46:52] [✓] ========================================
[2024-03-15 14:46:52] [✓]   BACKUP COMPLETED SUCCESSFULLY!
[2024-03-15 14:46:52] [✓] ========================================

[2024-03-15 14:46:52] [i] Backup Location: D:\WindowsBackup_20240315_143022

[2024-03-15 14:46:52] [i] Next steps:
  1. Review BACKUP_SUMMARY.txt for details
  2. Check BackupLog.txt for comprehensive log
  3. After Windows reinstall, open RESTORATION_GUIDE.md

[2024-03-15 14:46:52] [!] Keep this backup drive safe! 🔒
```

## Example with -WhatIf (Dry Run)

```
PS C:\Users\JohnDoe\windows-reinstall-backup> .\backup.ps1 -TargetDrive D -WhatIf

╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║        Windows Reinstall Backup Script v1.0                 ║
║        Safe backup of user data and configurations          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

[2024-03-15 14:30:22] [i] Backup will be created at: D:\WindowsBackup_20240315_143022
[2024-03-15 14:30:22] [i] Available space on D: 500.00 GB

=== Creating backup directory structure... ===
What if: Performing the operation "Create directory structure" on target "D:\WindowsBackup_20240315_143022".

=== Backing up user folders... ===
[2024-03-15 14:30:31] [i] Backing up: Documents folder
  [WhatIf] Would copy: C:\Users\JohnDoe\Documents -> D:\WindowsBackup_20240315_143022\Documents
[2024-03-15 14:30:31] [i] Backing up: Desktop folder
  [WhatIf] Would copy: C:\Users\JohnDoe\Desktop -> D:\WindowsBackup_20240315_143022\Desktop
[2024-03-15 14:30:31] [i] Backing up: Pictures folder
  [WhatIf] Would copy: C:\Users\JohnDoe\Pictures -> D:\WindowsBackup_20240315_143022\Pictures
...

[2024-03-15 14:30:40] [✓] ========================================
[2024-03-15 14:30:40] [✓]   BACKUP COMPLETED SUCCESSFULLY!
[2024-03-15 14:30:40] [✓] ========================================

Note: This was a dry run (-WhatIf). No files were actually copied.
```

## Example Backup Directory Structure

After completion, your backup drive will contain:

```
D:\WindowsBackup_20240315_143022\
│
├── 📁 Projects\
│   └── (Empty - manual projects backup recommended)
│
├── 📁 Documents\
│   ├── Work Projects\
│   ├── Personal\
│   └── Notes\
│
├── 📁 Desktop\
│   ├── Shortcuts\
│   └── Files\
│
├── 📁 Pictures\
│   ├── 2023\
│   ├── 2024\
│   └── Screenshots\
│
├── 📁 Videos\
│   └── Recordings\
│
├── 📁 Music\
│   └── Playlists\
│
├── 📁 Downloads\
│   └── (Various files)\
│
├── 📁 SSHKeys\
│   ├── id_rsa
│   ├── id_rsa.pub
│   ├── known_hosts
│   └── config
│
├── 📁 GitConfig\
│   ├── .gitconfig
│   ├── .gitignore_global
│   ├── .bashrc
│   └── .npmrc
│
├── 📁 VSCodeSettings\
│   ├── settings.json
│   ├── keybindings.json
│   ├── extensions.txt
│   └── 📁 snippets\
│       ├── javascript.json
│       └── python.json
│
├── 📁 TerminalSettings\
│   └── settings.json
│
├── 📁 GameConfigs\
│   ├── 📁 My Games\
│   │   ├── Skyrim\
│   │   └── Witcher 3\
│   └── 📁 AppDataLocal_Steam\
│       └── config.vdf
│
├── 📁 AppDataRoaming_Selected\
│   ├── 📁 Spotify\
│   ├── 📁 Discord\
│   └── 📁 Slack\
│
├── 📁 AppDataLocal_Selected\
│   └── (Various)\
│
├── 📁 BrowserData\
│   ├── Chrome_Bookmarks.json
│   └── 📁 Firefox_Profiles\
│
├── 📁 SystemConfig\
│   ├── EnvironmentVariables.txt
│   ├── EnvironmentVariables_User.txt
│   ├── EnvironmentVariables_System.txt
│   ├── InstalledPrograms.txt
│   ├── InstalledPrograms.csv
│   ├── WindowsFeatures.txt
│   ├── WindowsFeatures.csv
│   ├── PowerShellModules.csv
│   ├── WindowsStoreApps.csv
│   ├── NetworkAdapters.txt
│   └── SystemInfo.txt
│
├── 📄 RESTORATION_GUIDE.md          ⭐ START HERE after fresh install
├── 📄 BACKUP_SUMMARY.txt            📊 Quick overview
├── 📄 BackupLog.txt                 📝 Detailed log
└── 📄 robocopy_log.txt              🔍 File-level copy log
```

## Example BACKUP_SUMMARY.txt Content

```
=============================================================================
                     WINDOWS BACKUP SUMMARY
=============================================================================

Backup Date/Time:    2024-03-15 14:46:52
Backup Location:     D:\WindowsBackup_20240315_143022
Source User:         JohnDoe
Source Computer:     DESKTOP-ABC123
Duration:            00:16:30
Total Size:          85.43 GB

=============================================================================
                         BACKUP CONTENTS
=============================================================================

User Folders:
  • Documents (12.5 GB)
  • Desktop (2.3 GB)
  • Pictures (45.2 GB)
  • Videos (20.1 GB)
  • Music (3.4 GB)
  • Downloads (1.9 GB)

Development Configs:
  • SSH Keys (45 KB)
  • Git configuration
  • Shell configs

Application Settings:
  • VS Code (42 extensions)
  • Windows Terminal
  • Chrome bookmarks
  • Firefox profile
  • Game configs (Steam, Epic)

System Configuration:
  • 127 installed programs
  • 15 enabled Windows features
  • User & System environment variables
  • PowerShell modules
  • Network configuration

=============================================================================
```

## Example Items Skipped (Normal)

If some items aren't found, you'll see:

```
Items skipped:
  • AWS configuration (not found)
  • Kubernetes config (not found)
  • Docker config (not found)
```

This is normal if you don't have these tools installed.

## Example Error Output

If errors occur (rare), you'll see:

```
Errors encountered during backup:
  • Partial backup of Documents folder (Exit code: 8)
  • Failed to backup Discord settings: Access denied

Check BackupLog.txt for detailed error information.
```

## Example Compression Output

If you use `-Compress` flag:

```
=== Compressing backup... ===
[2024-03-15 14:50:00] [i] Creating ZIP archive: D:\WindowsBackup_20240315_143022.zip
[2024-03-15 14:50:00] [!] This may take a while depending on backup size...

[Progress shown by Compress-Archive...]

[2024-03-15 15:05:30] [✓] Backup compressed successfully
[2024-03-15 15:05:30] [i] Compressed size: 65.32 GB
[2024-03-15 15:05:30] [i] Original folder: D:\WindowsBackup_20240315_143022
[2024-03-15 15:05:30] [i] Compressed file: D:\WindowsBackup_20240315_143022.zip

Delete original backup folder to save space? (y/N): n
```

## What to Look For

### ✅ Good Signs
- "Backup completed successfully" message
- 0 errors encountered
- All expected folders backed up
- Reasonable backup size for your data
- RESTORATION_GUIDE.md created

### ⚠️ Warning Signs (Check These)
- Multiple errors encountered (check BackupLog.txt)
- Unexpectedly small backup size
- Missing expected folders
- "Access denied" messages for important files

### 🔍 Post-Backup Verification

```powershell
# Check backup folder exists
Test-Path D:\WindowsBackup_20240315_143022

# Check a few critical files
Test-Path D:\WindowsBackup_20240315_143022\Documents
Test-Path D:\WindowsBackup_20240315_143022\SSHKeys
Test-Path D:\WindowsBackup_20240315_143022\RESTORATION_GUIDE.md

# View summary
notepad D:\WindowsBackup_20240315_143022\BACKUP_SUMMARY.txt

# View detailed log
notepad D:\WindowsBackup_20240315_143022\BackupLog.txt
```

---

This example output should give you confidence that the script is working correctly. The actual output will vary based on your specific data and configuration.
