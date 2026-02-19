# vswitch

A fast CLI tool to switch between multiple Vercel accounts without the hassle of logging in and out.

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

### Quick Install (macOS)

Download the script to a directory in your `PATH`:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/vswitch/main/vswitch -o ~/.local/bin/vswitch
chmod +x ~/.local/bin/vswitch
```

Make sure `~/.local/bin` is in your `PATH`. Add this to your `~/.zshrc` or `~/.bashrc` if it isn't:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Manual Install

1. Clone or download this repository
2. Copy the `vswitch` script to somewhere in your `PATH`:

```bash
cp vswitch ~/.local/bin/vswitch
chmod +x ~/.local/bin/vswitch
```

### Requirements

- macOS (uses `~/Library/Application Support/com.vercel.cli/` for auth storage)
- [Vercel CLI](https://vercel.com/docs/cli) installed
- Python 3 (pre-installed on macOS, used for JSON parsing)
- Bash 4+

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

Vercel CLI stores its authentication in:

```
~/Library/Application Support/com.vercel.cli/auth.json
```

This file contains your API token, refresh token, and expiry timestamp. `vswitch` works by:

1. **Saving** - copies `auth.json` to `~/.vercel-profiles/<name>.json`
2. **Switching** - copies `~/.vercel-profiles/<name>.json` back to `auth.json`

That's the entire mechanism. No daemon, no background process, no config server. Just file copies.

### File Locations

| Path | Purpose |
|---|---|
| `~/.local/bin/vswitch` | The CLI script |
| `~/.vercel-profiles/` | Saved profile directory |
| `~/.vercel-profiles/<name>.json` | Individual profile auth data |
| `~/Library/Application Support/com.vercel.cli/auth.json` | Vercel CLI's active auth (managed by Vercel) |

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

- Profile files in `~/.vercel-profiles/` contain **auth tokens**. They are created with user-only read/write permissions (`600`), matching Vercel's own `auth.json` permissions.
- Tokens are stored exactly as Vercel CLI stores them - no additional encryption is added. If you're comfortable with how Vercel CLI handles auth, `vswitch` doesn't change that security model.
- `vswitch remove` deletes the local profile file but does **not** revoke the token on Vercel's servers. To fully revoke access, use the Vercel dashboard.
- Never commit the `~/.vercel-profiles/` directory to version control.

## Troubleshooting

### `command not found: vswitch`

Make sure `~/.local/bin` is in your PATH:

```bash
echo $PATH | tr ':' '\n' | grep .local/bin
```

If not, add to your `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then restart your terminal or run `source ~/.zshrc`.

### `Error: No Vercel auth found`

You're not currently logged in to Vercel CLI. Run `vercel login` first, then `vswitch save <name>`.

### Token expired after switching

Vercel tokens have an expiry. If a saved profile's token has expired, switch to it and run `vercel login` to refresh, then re-save:

```bash
vswitch use old-profile
vercel login
vswitch save old-profile    # overwrites with fresh token
```

### Wrong platform

Currently `vswitch` is built for **macOS** where Vercel CLI stores auth in `~/Library/Application Support/com.vercel.cli/`. For Linux, the path would need to be updated to `~/.local/share/com.vercel.cli/` or equivalent XDG path.

## License

MIT
