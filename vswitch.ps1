#Requires -Version 5.1
<#
.SYNOPSIS
    vswitch - Fast Vercel account switcher for Windows.
.DESCRIPTION
    Switch between multiple Vercel CLI accounts without logging in and out.
    Saves auth tokens as named profiles and swaps them instantly.
.EXAMPLE
    vswitch save personal
    vswitch use work
    vswitch list
#>

param(
    [Parameter(Position = 0)]
    [string]$Command,

    [Parameter(Position = 1)]
    [string]$Name
)

$ErrorActionPreference = "Stop"

$VercelDir = Join-Path $env:APPDATA "com.vercel.cli"
$AuthFile = Join-Path $VercelDir "auth.json"
$ProfilesDir = Join-Path $env:USERPROFILE ".vercel-profiles"

if (-not (Test-Path $ProfilesDir)) {
    New-Item -ItemType Directory -Path $ProfilesDir -Force | Out-Null
}

function Show-Usage {
    Write-Host "vswitch" -ForegroundColor White -NoNewline
    Write-Host " - Vercel account switcher"
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor White
    Write-Host "  vswitch save <name>      Save current login as a named profile"
    Write-Host "  vswitch use <name>       Switch to a saved profile"
    Write-Host "  vswitch list             List all saved profiles"
    Write-Host "  vswitch current          Show the currently active profile"
    Write-Host "  vswitch remove <name>    Remove a saved profile"
    Write-Host "  vswitch login <name>     Login to Vercel and save as profile"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor White
    Write-Host "  vswitch save personal    # Save current auth as 'personal'"
    Write-Host "  vswitch save work        # Save current auth as 'work'"
    Write-Host "  vswitch use personal     # Switch to 'personal' account"
    Write-Host "  vswitch login client-x   # Login fresh and save as 'client-x'"
}

function Get-ActiveProfile {
    if (-not (Test-Path $AuthFile)) {
        return $null
    }
    $currentToken = (Get-Content $AuthFile -Raw | ConvertFrom-Json).token
    $profiles = Get-ChildItem -Path $ProfilesDir -Filter "*.json" -ErrorAction SilentlyContinue
    foreach ($profile in $profiles) {
        $profileToken = (Get-Content $profile.FullName -Raw | ConvertFrom-Json).token
        if ($currentToken -eq $profileToken) {
            return $profile.BaseName
        }
    }
    return $null
}

function Get-VercelUser {
    try {
        $result = vercel whoami 2>$null
        if ($LASTEXITCODE -eq 0) { return $result }
    } catch {}
    return "unknown"
}

function Save-Profile {
    param([string]$ProfileName)
    if (-not $ProfileName) {
        Write-Host "Error: " -ForegroundColor Red -NoNewline
        Write-Host "Profile name required"
        Write-Host "Usage: vswitch save <name>"
        exit 1
    }
    if (-not (Test-Path $AuthFile)) {
        Write-Host "Error: " -ForegroundColor Red -NoNewline
        Write-Host "No Vercel auth found. Run 'vercel login' first."
        exit 1
    }
    $user = Get-VercelUser
    Copy-Item $AuthFile (Join-Path $ProfilesDir "$ProfileName.json") -Force
    Write-Host "Saved " -ForegroundColor Green -NoNewline
    Write-Host "profile " -NoNewline
    Write-Host "$ProfileName" -ForegroundColor White -NoNewline
    Write-Host " ($user)"
}

function Use-Profile {
    param([string]$ProfileName)
    if (-not $ProfileName) {
        Write-Host "Error: " -ForegroundColor Red -NoNewline
        Write-Host "Profile name required"
        Write-Host "Usage: vswitch use <name>"
        exit 1
    }
    $profileFile = Join-Path $ProfilesDir "$ProfileName.json"
    if (-not (Test-Path $profileFile)) {
        Write-Host "Error: " -ForegroundColor Red -NoNewline
        Write-Host "Profile '$ProfileName' not found"
        Write-Host ""
        List-Profiles
        exit 1
    }
    if (-not (Test-Path $VercelDir)) {
        New-Item -ItemType Directory -Path $VercelDir -Force | Out-Null
    }
    Copy-Item $profileFile $AuthFile -Force
    $user = Get-VercelUser
    Write-Host "Switched " -ForegroundColor Green -NoNewline
    Write-Host "to " -NoNewline
    Write-Host "$ProfileName" -ForegroundColor White -NoNewline
    Write-Host " ($user)"
}

function List-Profiles {
    $active = Get-ActiveProfile
    Write-Host "Saved profiles:" -ForegroundColor White
    Write-Host ""
    $profiles = Get-ChildItem -Path $ProfilesDir -Filter "*.json" -ErrorAction SilentlyContinue
    if (-not $profiles -or $profiles.Count -eq 0) {
        Write-Host "  No profiles saved yet." -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Save your current login:"
        Write-Host "    vswitch save <name>"
    } else {
        foreach ($profile in $profiles) {
            $name = $profile.BaseName
            if ($name -eq $active) {
                Write-Host "  * " -ForegroundColor Green -NoNewline
                Write-Host "$name" -ForegroundColor White -NoNewline
                Write-Host " (active)" -ForegroundColor Green
            } else {
                Write-Host "    $name"
            }
        }
    }
    Write-Host ""
}

function Show-Current {
    $active = Get-ActiveProfile
    if ($active) {
        $user = Get-VercelUser
        Write-Host "$active" -ForegroundColor White -NoNewline
        Write-Host " ($user)"
    } elseif (Test-Path $AuthFile) {
        $user = Get-VercelUser
        Write-Host "Logged in as " -ForegroundColor Yellow -NoNewline
        Write-Host "$user " -NoNewline
        Write-Host "(unsaved profile)" -ForegroundColor DarkGray
    } else {
        Write-Host "Not logged in" -ForegroundColor DarkGray
    }
}

function Remove-Profile {
    param([string]$ProfileName)
    if (-not $ProfileName) {
        Write-Host "Error: " -ForegroundColor Red -NoNewline
        Write-Host "Profile name required"
        Write-Host "Usage: vswitch remove <name>"
        exit 1
    }
    $profileFile = Join-Path $ProfilesDir "$ProfileName.json"
    if (-not (Test-Path $profileFile)) {
        Write-Host "Error: " -ForegroundColor Red -NoNewline
        Write-Host "Profile '$ProfileName' not found"
        exit 1
    }
    Remove-Item $profileFile
    Write-Host "Removed " -ForegroundColor Green -NoNewline
    Write-Host "profile " -NoNewline
    Write-Host "$ProfileName" -ForegroundColor White
}

function Login-Profile {
    param([string]$ProfileName)
    if (-not $ProfileName) {
        Write-Host "Error: " -ForegroundColor Red -NoNewline
        Write-Host "Profile name required"
        Write-Host "Usage: vswitch login <name>"
        exit 1
    }
    Write-Host "Logging in for profile " -NoNewline
    Write-Host "$ProfileName" -ForegroundColor White -NoNewline
    Write-Host "..."
    vercel login
    Copy-Item $AuthFile (Join-Path $ProfilesDir "$ProfileName.json") -Force
    $user = Get-VercelUser
    Write-Host "Saved " -ForegroundColor Green -NoNewline
    Write-Host "profile " -NoNewline
    Write-Host "$ProfileName" -ForegroundColor White -NoNewline
    Write-Host " ($user)"
}

# Main
switch ($Command) {
    "save"              { Save-Profile $Name }
    "use"               { Use-Profile $Name }
    "switch"            { Use-Profile $Name }
    "list"              { List-Profiles }
    "ls"                { List-Profiles }
    "current"           { Show-Current }
    "remove"            { Remove-Profile $Name }
    "rm"                { Remove-Profile $Name }
    "login"             { Login-Profile $Name }
    "help"              { Show-Usage }
    "-h"                { Show-Usage }
    "--help"            { Show-Usage }
    ""                  { Show-Usage }
    default {
        # If just a name is passed, treat as "use"
        $profileFile = Join-Path $ProfilesDir "$Command.json"
        if (Test-Path $profileFile) {
            Use-Profile $Command
        } else {
            Write-Host "Unknown command: " -ForegroundColor Red -NoNewline
            Write-Host $Command
            Write-Host ""
            Show-Usage
            exit 1
        }
    }
}
