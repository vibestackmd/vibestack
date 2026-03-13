# bootstrap-windows.ps1
#
# VibeStack Windows Bootstrap: Installs WSL + Ubuntu + Hyper terminal so you
# can run the cross-platform dev-tools installer (install.sh) inside Linux.
#
# Safe to re-run — skips steps that are already done.
#
# Usage:
#   Right-click → Run with PowerShell (as Administrator)
#   or from an elevated PowerShell prompt:
#     Set-ExecutionPolicy Bypass -Scope Process -Force; .\bootstrap-windows.ps1

# ── Self-elevate to Administrator if needed ──────────────

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Relaunching as Administrator..."
    $workDir = (Get-Location).Path
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -WorkingDirectory `"$workDir`"" -Verb RunAs
    Exit
}

# Restore working directory when re-launched elevated
foreach ($arg in $args) {
    if ($arg -like "-WorkingDirectory") { continue }
    if ($prevArg -eq "-WorkingDirectory") { Set-Location $arg; break }
    $prevArg = $arg
}
# Also handle the case where we parsed -WorkingDirectory from $args
for ($i = 0; $i -lt $args.Count; $i++) {
    if ($args[$i] -eq "-WorkingDirectory" -and ($i + 1) -lt $args.Count) {
        Set-Location $args[$i + 1]
        break
    }
}

Write-Host ""
Write-Host "VibeStack Windows Bootstrap" -ForegroundColor Cyan
Write-Host "Sets up WSL + Ubuntu + Hyper terminal, then runs the dev-tools installer inside Linux." -ForegroundColor Cyan
Write-Host "Safe to re-run — already-completed steps are skipped." -ForegroundColor Cyan
Write-Host ""

$NeedsReboot = $false

# ── 1. Enable WSL feature ────────────────────────────────

function Test-WslFunctional {
    try {
        $result = wsl --status 2>&1
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

Write-Host "[1/5] WSL" -ForegroundColor Cyan

if (Test-WslFunctional) {
    Write-Host "  OK — WSL is installed and functional." -ForegroundColor Green
} else {
    Write-Host "  Installing WSL..." -ForegroundColor Yellow
    wsl --install --no-distribution
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  WSL install failed. You may need to enable it manually:" -ForegroundColor Red
        Write-Host "    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart" -ForegroundColor DarkGray
        Write-Host "    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart" -ForegroundColor DarkGray
        Read-Host "Press Enter to exit"
        Exit 1
    }
    $NeedsReboot = $true
}

# ── 2. Ensure WSL 2 is the default version ───────────────

Write-Host ""
Write-Host "[2/5] WSL version" -ForegroundColor Cyan

wsl --set-default-version 2 2>$null | Out-Null
Write-Host "  OK — WSL 2 set as default." -ForegroundColor Green

# ── 3. Install Ubuntu if not present ─────────────────────

Write-Host ""
Write-Host "[3/5] Ubuntu" -ForegroundColor Cyan

function Get-WslDistros {
    # wsl --list --quiet outputs UTF-16LE with null bytes — clean it up
    $raw = wsl --list --quiet 2>&1
    if ($LASTEXITCODE -ne 0) { return @() }
    $lines = ($raw | Out-String) -split "`r?`n" | ForEach-Object { $_.Trim("`0", " ", "`r", "`n") } | Where-Object { $_ -ne "" }
    return $lines
}

$distros = Get-WslDistros
$hasUbuntu = $distros | Where-Object { $_ -match "^Ubuntu" }

if ($NeedsReboot) {
    Write-Host "  WSL was just installed — a restart is needed before Ubuntu can be added." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  After restarting:" -ForegroundColor Yellow
    Write-Host "    1. Open PowerShell as Administrator" -ForegroundColor Yellow
    Write-Host "    2. cd back to this folder" -ForegroundColor Yellow
    Write-Host "    3. Re-run: .\bootstrap-windows.ps1" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit (then restart your computer)"
    Exit 0
}

if ($hasUbuntu) {
    Write-Host "  OK — Ubuntu is already installed." -ForegroundColor Green
} else {
    Write-Host "  Installing Ubuntu (this may take a few minutes)..." -ForegroundColor Yellow
    Write-Host ""

    # Stream output in real time while also capturing it for error checks
    $ubuntuLog = "$env:TEMP\vibestack-wsl-install.log"
    wsl --install -d Ubuntu 2>&1 | Tee-Object -FilePath $ubuntuLog
    $ubuntuExitCode = $LASTEXITCODE
    $ubuntuOutput = Get-Content $ubuntuLog -Raw -ErrorAction SilentlyContinue

    if ($ubuntuOutput -match "reboot|restart") {
        Write-Host ""
        Write-Host "  A restart is needed before Ubuntu is available." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  After restarting:" -ForegroundColor Yellow
        Write-Host "    1. Ubuntu may open automatically to create a username/password — complete that first" -ForegroundColor Yellow
        Write-Host "    2. Open PowerShell as Administrator" -ForegroundColor Yellow
        Write-Host "    3. Re-run this script to finish setup" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter to exit (then restart your computer)"
        Exit 0
    }

    if ($ubuntuOutput -match "HYPERV_NOT_INSTALLED|Virtual Machine Platform|virtualization") {
        Write-Host ""
        Write-Host "  Virtualization is not enabled on this machine." -ForegroundColor Red
        Write-Host ""
        Write-Host "  WSL 2 requires hardware virtualization. To fix:" -ForegroundColor Yellow
        Write-Host "    1. Restart your computer and enter BIOS (usually F2, F10, Del, or Esc during boot)" -ForegroundColor Yellow
        Write-Host "    2. Find and enable virtualization:" -ForegroundColor Yellow
        Write-Host "         Intel: 'Intel Virtualization Technology' or 'VT-x'" -ForegroundColor Yellow
        Write-Host "         AMD:   'SVM Mode' or 'AMD-V'" -ForegroundColor Yellow
        Write-Host "       (Usually under Advanced > CPU Configuration)" -ForegroundColor Yellow
        Write-Host "    3. Save, exit BIOS, and re-run this script" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter to exit"
        Exit 1
    }

    if ($ubuntuExitCode -ne 0) {
        Write-Host "  Ubuntu install failed. Try manually: wsl --install -d Ubuntu" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        Exit 1
    }
    Write-Host ""
    Write-Host "  Ubuntu is installing. A terminal window may open to create a username/password." -ForegroundColor Yellow
    Write-Host "  Complete that setup, then come back here and press Enter." -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
}

wsl --set-default Ubuntu 2>$null | Out-Null

# ── 4. Install Hyper terminal ─────────────────────────────

Write-Host ""
Write-Host "[4/5] Hyper terminal" -ForegroundColor Cyan

$hyperPath = "$env:LOCALAPPDATA\Programs\Hyper\Hyper.exe"
if (Test-Path $hyperPath) {
    Write-Host "  OK — Hyper is already installed." -ForegroundColor Green
} else {
    Write-Host "  Installing Hyper terminal..." -ForegroundColor Yellow
    winget install --id Vercel.Hyper --accept-source-agreements --accept-package-agreements --silent
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Hyper install failed. You can install it manually from https://hyper.is" -ForegroundColor Red
    } else {
        Write-Host "  OK — Hyper installed." -ForegroundColor Green
    }
}

# Configure Hyper to use WSL by default
$hyperConfig = "$env:APPDATA\Hyper\.hyper.js"
if (Test-Path $hyperConfig) {
    $content = Get-Content $hyperConfig -Raw
    $modified = $false

    # Set shell to WSL
    if ($content -match "shell:\s*'[^']*'") {
        $content = $content -replace "shell:\s*'[^']*'", "shell: 'wsl.exe'"
        $modified = $true
    } elseif ($content -match "shell:\s*`"[^`"]*`"") {
        $content = $content -replace "shell:\s*`"[^`"]*`"", "shell: 'wsl.exe'"
        $modified = $true
    }

    # Set shellArgs to start in home directory
    if ($content -match "shellArgs:\s*\[.*?\]") {
        $content = $content -replace "shellArgs:\s*\[.*?\]", "shellArgs: ['~']"
        $modified = $true
    }

    if ($modified) {
        Set-Content $hyperConfig -Value $content -NoNewline
        Write-Host "  OK — Hyper configured to use WSL." -ForegroundColor Green
    } else {
        Write-Host "  Could not auto-configure .hyper.js — set shell manually to C:\Windows\System32\wsl.exe" -ForegroundColor Yellow
    }
} else {
    # Hyper creates .hyper.js on first launch — launch it, wait, then patch
    Write-Host "  .hyper.js not found — launching Hyper to generate defaults..." -ForegroundColor Yellow
    Start-Process $hyperPath
    Start-Sleep -Seconds 5
    Stop-Process -Name "Hyper" -ErrorAction SilentlyContinue -Force
    if (Test-Path $hyperConfig) {
        $content = Get-Content $hyperConfig -Raw
        $patched = $false
        if ($content -match "shell:\s*'[^']*'") {
            $content = $content -replace "shell:\s*'[^']*'", "shell: 'wsl.exe'"
            $patched = $true
        } elseif ($content -match "shell:\s*`"[^`"]*`"") {
            $content = $content -replace "shell:\s*`"[^`"]*`"", "shell: 'wsl.exe'"
            $patched = $true
        }
        if ($content -match "shellArgs:\s*\[.*?\]") {
            $content = $content -replace "shellArgs:\s*\[.*?\]", "shellArgs: ['~']"
            $patched = $true
        }
        if ($patched) {
            Set-Content $hyperConfig -Value $content -NoNewline
            Write-Host "  OK — Hyper configured to use WSL." -ForegroundColor Green
        } else {
            Write-Host "  Could not auto-configure .hyper.js — set shell manually to wsl.exe" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Could not generate .hyper.js — open Hyper manually, then re-run this script." -ForegroundColor Yellow
    }
}

# ── 5. Run dev-tools installer inside WSL ─────────────────

Write-Host ""
Write-Host "[5/5] Dev tools installer" -ForegroundColor Cyan

# Convert Windows path (C:\Users\foo\vibestack) → WSL path (/mnt/c/Users/foo/vibestack)
function ConvertTo-WslPath {
    param([string]$WinPath)
    if ($WinPath -match '^([A-Za-z]):\\(.*)$') {
        $drive = $Matches[1].ToLower()
        $rest = $Matches[2] -replace '\\', '/'
        return "/mnt/$drive/$rest"
    }
    return $WinPath
}

$scriptDir = Split-Path -Parent $PSCommandPath
$installScript = Join-Path $scriptDir "install.sh"

if (Test-Path $installScript) {
    $wslPath = ConvertTo-WslPath $scriptDir
    Write-Host "  Running install.sh from: $wslPath" -ForegroundColor DarkGray
    Write-Host ""
    wsl -d Ubuntu -- bash -c "cd '$wslPath' && chmod +x install.sh && ./install.sh"
} else {
    Write-Host "  install.sh not found next to this script — running from GitHub..." -ForegroundColor Yellow
    Write-Host ""
    wsl -d Ubuntu -- bash -c "curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/kit/extras/dev-tools/install.sh | bash"
}

# ── Done ──────────────────────────────────────────────────

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open Hyper — it's pre-configured to launch into WSL." -ForegroundColor White
Write-Host "       Or type 'wsl' in PowerShell, or open Windows Terminal > Ubuntu" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  2. Your Windows drives are at /mnt/c/, /mnt/d/, etc." -ForegroundColor White
Write-Host ""
Write-Host "  3. To re-run just the dev tools installer later:" -ForegroundColor White
Write-Host "       curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/kit/extras/dev-tools/install.sh | bash" -ForegroundColor DarkGray
Write-Host ""

Read-Host "Press Enter to exit"
