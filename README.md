# vswitch

A fast CLI tool to switch between multiple Vercel accounts without the hassle of logging in and out.

Works on **macOS**, **Linux**, and **Windows**.

## The Problem

If you manage multiple Vercel accounts (personal projects, work, clients), the only way to switch between them is:

```bash
vercel logout
vercel login   # re-authenticate every single time
```

This gets tedious fast, especially when you're deploying across accounts multiple times a day.

## The Solution

`vswitch` saves your Vercel auth tokens as named profiles and lets you swap between them instantly.

```bash
vswitch use personal   # done. instant switch.
```

## Installation

### macOS / Linux

Download the script to a directory in your `PATH`:

```bash
curl -fsSL https://raw.githubusercontent.com/alabiemmanuel177/vswitch/main/vswitch -o ~/.local/bin/vswitch
chmod +x ~/.local/bin/vswitch
```

Make sure `~/.local/bin` is in your `PATH`. Add this to your `~/.zshrc` or `~/.bashrc` if it isn't:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Windows (PowerShell)

1. Download `vswitch.ps1`:

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/alabiemmanuel177/vswitch/main/vswitch.ps1" -OutFile "$HOME\vswitch.ps1"
```

2. Create a wrapper so you can call `vswitch` directly. Add this function to your PowerShell profile (`$PROFILE`):

```powershell
function vswitch { & "$HOME\vswitch.ps1" @args }
```

Or to install system-wide, place `vswitch.ps1` in a directory in your `PATH` and create a batch wrapper:

```bat
:: Save as vswitch.cmd somewhere in your PATH
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\vswitch.ps1" %*
```

> **Note:** You may need to allow script execution: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Manual Install

1. Clone or download this repository
2. Copy the appropriate script to somewhere in your `PATH`:

```bash
# macOS / Linux
cp vswitch ~/.local/bin/vswitch
chmod +x ~/.local/bin/vswitch
```

```powershell
# Windows
Copy-Item vswitch.ps1 "$HOME\vswitch.ps1"
```

### Requirements

- [Vercel CLI](https://vercel.com/docs/cli) installed and accessible as `vercel`
- **macOS / Linux:** Bash 4+, Python 3 (used for JSON parsing)
- **Windows:** PowerShell 5.1+

## Quick Start

**1. Save your current Vercel account as a profile:**

```bash
vswitch save personal
# Saved profile personal (your-username)
```

**2. Login to another account and save it:**

```bash
vswitch login work
# Opens Vercel login flow in your browser...
# Saved profile work (work-username)
```

**3. Switch between them:**

```bash
vswitch use personal
# Switched to personal (your-username)

vswitch use work
# Switched to work (work-username)
```

That's it. No more `vercel logout && vercel login`.

## Commands

### `vswitch save <name>`

Saves your current Vercel CLI auth session as a named profile.

```bash
# First login normally
vercel login

# Then save it
vswitch save personal
# Saved profile personal (alabiemmanuel177)
```

You must be logged in to Vercel CLI before saving. If you're not, you'll see:

```
Error: No Vercel auth found. Run 'vercel login' first.
```

### `vswitch use <name>`

Switches to a previously saved profile. This is instant - no browser login required.

```bash
vswitch use work
# Switched to work (work-account)
```

If the profile doesn't exist, it shows available profiles:

```
Error: Profile 'typo' not found

Saved profiles:

  * personal (active)
    work
    client-x
```

**Shorthand:** You can omit `use` and just pass the profile name directly:

```bash
vswitch personal
# Switched to personal (your-username)
```

### `vswitch login <name>`

Runs `vercel login` and automatically saves the new session as a named profile. This is the easiest way to add a new account.

```bash
vswitch login client-project
# Opens browser for Vercel login...
# Saved profile client-project (client-username)
```

### `vswitch list`

Lists all saved profiles and highlights the currently active one.

```bash
vswitch list
# Saved profiles:
#
#   * personal (active)
#     work
#     client-x
```

**Alias:** `vswitch ls`

### `vswitch current`

Shows which profile (and Vercel username) is currently active.

```bash
vswitch current
# personal (alabiemmanuel177)
```

If you're logged in but haven't saved the session as a profile:

```
Logged in as some-user (unsaved profile)
```

### `vswitch remove <name>`

Deletes a saved profile. This does **not** revoke the Vercel token - it only removes the local copy.

```bash
vswitch remove old-client
# Removed profile old-client
```

**Alias:** `vswitch rm`

### `vswitch help`

Shows usage information and examples.

**Aliases:** `vswitch -h`, `vswitch --help`

## Command Summary

| Command | Alias | Description |
|---|---|---|
| `vswitch save <name>` | | Save current auth as a named profile |
| `vswitch use <name>` | `vswitch <name>` | Switch to a saved profile |
| `vswitch login <name>` | | Login to Vercel and save as profile |
| `vswitch list` | `vswitch ls` | List all saved profiles |
| `vswitch current` | | Show the active profile |
| `vswitch remove <name>` | `vswitch rm <name>` | Delete a saved profile |
| `vswitch help` | `vswitch -h` | Show help |

## How It Works

Vercel CLI stores its authentication in a platform-specific directory:

| Platform | Auth file path |
|---|---|
| macOS | `~/Library/Application Support/com.vercel.cli/auth.json` |
| Linux | `~/.config/com.vercel.cli/auth.json` (or `$XDG_CONFIG_HOME`) |
| Windows | `%APPDATA%\com.vercel.cli\auth.json` |

This file contains your API token, refresh token, and expiry timestamp. `vswitch` works by:

1. **Saving** - copies `auth.json` to `~/.vercel-profiles/<name>.json`
2. **Switching** - copies `~/.vercel-profiles/<name>.json` back to `auth.json`

That's the entire mechanism. No daemon, no background process, no config server. Just file copies.

### File Locations

| Path | Purpose |
|---|---|
| `~/.local/bin/vswitch` | The CLI script (macOS/Linux) |
| `$HOME\vswitch.ps1` | The CLI script (Windows) |
| `~/.vercel-profiles/` | Saved profile directory (all platforms) |
| `~/.vercel-profiles/<name>.json` | Individual profile auth data |

On Windows, the profiles directory is `%USERPROFILE%\.vercel-profiles\`.

## Typical Workflow

```bash
# Initial setup - save all your accounts
vercel login                  # login to account 1
vswitch save personal

vswitch login work            # login to account 2 and save
vswitch login freelance       # login to account 3 and save

# Day-to-day usage
cd ~/projects/my-blog
vswitch personal
vercel deploy

cd ~/projects/company-app
vswitch work
vercel deploy

cd ~/projects/client-site
vswitch freelance
vercel deploy
```

## Security Notes

- Profile files in `~/.vercel-profiles/` contain **auth tokens**. They are created with user-only read/write permissions, matching Vercel's own `auth.json` permissions.
- Tokens are stored exactly as Vercel CLI stores them - no additional encryption is added. If you're comfortable with how Vercel CLI handles auth, `vswitch` doesn't change that security model.
- `vswitch remove` deletes the local profile file but does **not** revoke the token on Vercel's servers. To fully revoke access, use the Vercel dashboard.
- Never commit the `~/.vercel-profiles/` directory to version control.

## Troubleshooting

### `command not found: vswitch`

**macOS / Linux** - Make sure `~/.local/bin` is in your PATH:

```bash
echo $PATH | tr ':' '\n' | grep .local/bin
```

If not, add to your `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then restart your terminal or run `source ~/.zshrc`.

**Windows** - Make sure the PowerShell function or batch wrapper is set up. See [Windows installation](#windows-powershell).

### `Error: No Vercel auth found`

You're not currently logged in to Vercel CLI. Run `vercel login` first, then `vswitch save <name>`.

### Token expired after switching

Vercel tokens have an expiry. If a saved profile's token has expired, switch to it and run `vercel login` to refresh, then re-save:

```bash
vswitch use old-profile
vercel login
vswitch save old-profile    # overwrites with fresh token
```

### Windows: script execution is disabled

If you see a script execution policy error, run:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request.

## License

MIT
