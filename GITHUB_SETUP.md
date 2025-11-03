# GitHub Setup Instructions

The code is ready and committed locally. Here are your options to push to GitHub:

## Option 1: Using GitHub CLI (Easiest)

```bash
# 1. Authenticate with GitHub
gh auth login

# 2. Follow the prompts:
#    - Choose: GitHub.com
#    - Protocol: HTTPS
#    - Authenticate: Login with a web browser

# 3. Create the repository and push
gh repo create windows-reinstall-backup --public --source=. --push

# Done! Repository created and code pushed.
```

## Option 2: Manual Setup via GitHub Website

```bash
# 1. Go to https://github.com/new

# 2. Fill in:
#    - Repository name: windows-reinstall-backup
#    - Description: Comprehensive PowerShell script for backing up Windows before reinstall
#    - Visibility: Public
#    - Do NOT initialize with README (we already have one)

# 3. Click "Create repository"

# 4. Back in your terminal, run:
git remote add origin https://github.com/YOUR_USERNAME/windows-reinstall-backup.git
git branch -M main
git push -u origin main

# Done! Code is now on GitHub.
```

## Option 3: Using SSH (If you have SSH keys set up)

```bash
# 1. Create repo on GitHub: https://github.com/new
#    - Name: windows-reinstall-backup
#    - Public
#    - Don't initialize with README

# 2. Add remote and push:
git remote add origin git@github.com:YOUR_USERNAME/windows-reinstall-backup.git
git branch -M main
git push -u origin main
```

## Verify It Worked

After pushing, visit:
```
https://github.com/YOUR_USERNAME/windows-reinstall-backup
```

You should see all your files, README displayed, and the commit message.

## Next: Clone on Windows

Once pushed to GitHub, on your Windows machine:

```powershell
# 1. Open PowerShell
# 2. Navigate to where you want the script
cd C:\Users\YourName

# 3. Clone the repository
git clone https://github.com/YOUR_USERNAME/windows-reinstall-backup.git

# 4. Navigate into the directory
cd windows-reinstall-backup

# 5. Run the script (as Administrator)
.\backup.ps1 -TargetDrive D
```

---

**Which option do you prefer?** I can help you with any of them!
