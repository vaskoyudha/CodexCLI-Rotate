```
  ___  ___  ___  _____ __  __     ___  ___ _____ _ _____ ___
 / __|/ _ \|   \| __\ \/ / ___  | _ \/ _ \_   _/_\_   _| __|
| (__| (_) | |) | _| >  < |___| |   / (_) || |/ _ \| | | _|
 \___|\___/|___/|___/_/\_\       |_|_\\___/ |_/_/ \_\_| |___|
```

**Multi-account manager for Codex CLI with automatic rotation on rate limits.**

![License](https://img.shields.io/github/license/vaskoyudha/CodexCLI-Rotate)
![NPM Version](https://img.shields.io/npm/v/codex-rotate)
![GitHub Stars](https://img.shields.io/github/stars/vaskoyudha/CodexCLI-Rotate)
![GitHub Issues](https://img.shields.io/github/issues/vaskoyudha/CodexCLI-Rotate)
![ShellCheck](https://img.shields.io/github/actions/workflow/status/vaskoyudha/CodexCLI-Rotate/ci.yml?label=shellcheck)

---

## Table of Contents

- [Demo](#demo)
- [Why codex-rotate?](#why-codex-rotate)
- [Features](#features)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [How It Works](#how-it-works)
- [Configuration](#configuration)
- [What It Does / Does NOT Do](#what-it-does--does-not-do)
- [Requirements](#requirements)
- [Uninstall](#uninstall)
- [FAQ](#faq)
- [Companion Tools](#companion-tools)
- [Contributing](#contributing)
- [License](#license)

---

## Demo

```bash
$ codex-rotate add personal
[INFO] Launching Codex CLI login for 'personal'...
[OK] Account 'personal' added and credentials stored.

$ codex-rotate add work
[INFO] Launching Codex CLI login for 'work'...
[OK] Account 'work' added and credentials stored.

$ codex-rotate list
  ALIAS        EMAIL                  STATUS   USES  PLAN   LAST USED    COOLDOWN
  personal *   user@gmail.com         ready    14    plus   2 min ago    —
  work         work@company.com       ready    3     team   just now     —

$ codex-rotate run exec "Refactor the auth module to use JWT"
[INFO] Running with account 'personal'...
# ... codex runs normally ...
# Rate limit detected on stderr!
[WARN] Rate limit hit on 'personal' — switching to 'work'
[INFO] Swapped to 'work' (symlink updated atomically)
[INFO] Retrying command with 'work'...
# ... codex continues seamlessly ...

$ codex-rotate status
╔═══════════════════════════════════════════════════════════════════════════════════╗
║              Codex Account Rotation Manager v1.3.0                               ║
╠═══════════════════════════════════════════════════════════════════════════════════╣
║  ACCOUNT     EMAIL                STATUS     USES   PLAN   COOLDOWN   LAST USED  ║
║  personal    user@gmail.com       cooldown   14     plus   47m left   3 min ago   ║
║  work *      work@company.com     ready      3      team   —          just now    ║
╚═══════════════════════════════════════════════════════════════════════════════════╝

$ codex-rotate quota
━━━ personal ━━━
  Email:  user@gmail.com
  Plan:   plus
  5-Hour Usage:  [████░░░░░░] 40% (resets in 2h 15m)
  Weekly Usage:  [██░░░░░░░░] 20% (resets in 5d 3h)
  Credits:  ∞ Unlimited

━━━ work ━━━
  Email:  work@company.com
  Plan:   team
  5-Hour Usage:  [█░░░░░░░░░] 10% (resets in 4h 30m)
  Weekly Usage:  [░░░░░░░░░░]  0% (resets in 6d 22h)
  Credits:  ∞ Unlimited

$ codex-rotate email
ALIAS                EMAIL                               PLAN
personal             user@gmail.com                      plus
work                 work@company.com                    team
```

---

## Why codex-rotate?

- Hit the rate limit mid-session? **codex-rotate** auto-switches to your next account in milliseconds.
- Managing multiple Codex accounts? One command to add, switch, and track them all.
- Exhausted your daily or hourly limits? Automated cooldown management ensures you always use a fresh account.
- Need high-throughput CLI usage? Transparent wrapper handles retries and rotation without manual intervention.

## Features

- 🔄 **Auto-rotation** — Detects `429`, `usageLimitExceeded`, and other rate-limit signals to instantly swap accounts.
- 👹 **Background daemon** — `daemon start` monitors Codex logs and quota API in the background. Auto-swaps `auth.json` when rate limits are hit — works with any launcher (omx, codex, codex-rotate run).
- ⏰ **Time-based rotation** — Optionally rotate accounts every N hours to balance usage across your fleet.
- 📊 **Real-time quota checking** — Query OpenAI's usage API to see 5-hour and weekly usage with colored progress bars.
- 📧 **Email & plan display** — Extract and show email addresses and plan types from account JWT tokens.
- 🔃 **Token refresh** — Refresh expired access tokens using stored refresh tokens.
- 🧠 **Quota-aware rotation** — Smart rotation in `auto` mode prefers accounts with the lowest usage percentage.
- 🔒 **Secure storage** — Credentials stored in `~/.codex-accounts/` with strict `700`/`600` permissions.
- ⚡ **Atomic switching** — Uses symlink swapping for `~/.codex/auth.json` to ensure zero-downtime transitions.
- 📈 **Per-account tracking** — Built-in dashboard for usage counts, cooldown timers, and last-used timestamps.
- 🛡️ **Concurrent-safe** — Robust `flock`-based file locking prevents state corruption during parallel execution.
- 🩺 **System diagnostics** — `doctor` command checks Bash version, dependencies, permissions, and token health.
- 🖥️ **Interactive TUI** — Menu-driven interface via `whiptail` or `dialog` — no commands to memorize.
- 📦 **JSON output** — `--json` flag on `list`, `status`, `quota`, `email` for scripting and automation.
- 🏷️ **Account groups** — Tag accounts with groups and rotate only within a group (`--group=work`).
- 🔔 **Notifications** — Desktop notifications and webhooks (Slack, Discord, Telegram) on rotation events.
- ⬆️ **Self-upgrade** — `upgrade` command checks npm for the latest version and upgrades in-place.
- 🐚 **Shell completions** — Tab completion for bash, zsh, and fish with dynamic account alias support.
- 🍺 **Homebrew support** — Install via `brew install codex-rotate` (tap available).

## Quick Start

1. **Install** via npm:
   ```bash
   npm install -g codex-rotate
   ```

2. **Add accounts** (opens browser login):
   ```bash
   codex-rotate add account1
   codex-rotate add account2
   ```

3. **Run with auto-rotation**:
   ```bash
   codex-rotate run exec "Write a snake game in Python"
   ```

That's it. When `account1` hits the rate limit, `codex-rotate` swaps to `account2` and retries — no manual intervention needed.

## Installation

### npm (Recommended)

```bash
npm install -g codex-rotate
```

### curl one-liner

```bash
curl -fsSL https://raw.githubusercontent.com/vaskoyudha/CodexCLI-Rotate/main/install.sh | bash
```

### Manual

```bash
git clone https://github.com/vaskoyudha/CodexCLI-Rotate.git
cd CodexCLI-Rotate
make install
```

### Homebrew

```bash
brew tap vaskoyudha/tap
brew install codex-rotate
```

> **Note**: `npm install -g` installs to npm's global prefix (usually `/usr/local/bin`). The curl installer and `make install` install to `~/.local/bin` — make sure it's in your `$PATH`. The installer will detect your shell and tell you the exact line to add if needed. Shell completions are installed automatically with `npm install -g` and `make install`.

## Usage

| Command | Description | Example |
|---------|-------------|---------|
| `init` | Initialize structure in `~/.codex-accounts/` | `codex-rotate init` |
| `add` | Add account via browser login | `codex-rotate add my-acc` |
| `import` | Import an existing `auth.json` | `codex-rotate import old-acc ./auth.json` |
| `remove` | Remove an account from rotation | `codex-rotate remove my-acc` |
| `list` | List accounts with simplified status | `codex-rotate list` or `codex-rotate list --json` |
| `switch` | Manually switch the active account | `codex-rotate switch my-acc` |
| `status` | Show detailed dashboard | `codex-rotate status` or `codex-rotate status --json` |
| `run` | Wrap command with rate-limit rotation | `codex-rotate run exec "prompt"` |
| `auto` | Wrap with time + rate-limit rotation | `codex-rotate auto exec "prompt"` |
| `quota` | Show real-time usage/quota from OpenAI | `codex-rotate quota` or `codex-rotate quota --json` |
| `email` | Display email and plan from tokens | `codex-rotate email` or `codex-rotate email --json` |
| `refresh` | Refresh access tokens | `codex-rotate refresh my-acc` or `codex-rotate refresh --all` |
| `doctor` | Run system diagnostics | `codex-rotate doctor` |
| `upgrade` | Check for updates and upgrade via npm | `codex-rotate upgrade` |
| `tui` | Interactive terminal menu | `codex-rotate tui` |
| `daemon` | Background rate-limit monitor | `codex-rotate daemon start` |
| `group` | Manage account groups | `codex-rotate group set my-acc work` |
| `cooldown` | Manually mark account as cooling down | `codex-rotate cooldown my-acc` |
| `uncooldown` | Clear cooldown status for an account | `codex-rotate uncooldown my-acc` |
| `help` | Display help information | `codex-rotate help` |

## How It Works

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│ codex-rotate │────▶│  codex CLI   │────▶│  OpenAI API │
│     run      │     │  (wrapped)   │     │             │
└──────┬───────┘     └──────┬───────┘     └──────┬──────┘
       │                    │                     │
       │              stderr monitor              │
       │                    │                     │
       │              ┌─────▼──────┐              │
       │              │ Rate limit │              │
       │              │ detected?  │              │
       │              └─────┬──────┘              │
       │                    │ yes                  │
       │              ┌─────▼──────┐              │
       │              │ Swap auth  │              │
       │              │  symlink   │──────────────┘
       │              │ (atomic)   │   retry with
       │              └────────────┘   new account
       │
```

1. **Transparent Wrapper** — `codex-rotate run` wraps the official Codex CLI, passing all arguments directly.
2. **Signal Monitoring** — Monitors `stderr` for rate-limit signals (`429`, `usageLimitExceeded`, `usage limit`, `rate limit`).
3. **Background Daemon** — `codex-rotate daemon start` watches the Codex TUI log (`~/.codex/log/codex-tui.log`) and polls the quota API every 30s. When rate limits are detected or quota exceeds the threshold, it auto-swaps `auth.json` — no wrapper needed.
4. **Atomic Swap** — Swaps the `~/.codex/auth.json` symlink to the next available account.
5. **Auto-Retry** — Retries the command with the new account (up to `MAX_RETRIES`).

## Configuration

Settings are stored in `~/.codex-accounts/config.sh`:

```bash
ROTATION_INTERVAL=10800   # Time-based rotation interval (3 hours)
HOURLY_COOLDOWN=3600      # Cooldown for hourly rate limit (1 hour)
DAILY_COOLDOWN=86400      # Cooldown for daily rate limit (24 hours)
WEEKLY_COOLDOWN=604800    # Cooldown for weekly rate limit (7 days)
MAX_RETRIES=3             # Max retries after rate limit
QUOTA_AWARE_ROTATION=0    # Set to 1 for usage-based rotation (auto mode enables this)
CODEX_BIN=""              # Path to codex binary (auto-detected if empty)
DAEMON_CHECK_INTERVAL=30  # Seconds between daemon quota/log checks
DAEMON_QUOTA_THRESHOLD=90 # Usage percent to trigger proactive rotation
CODEX_LOG_PATH=""         # Path to codex TUI log (auto-detected if empty)
NOTIFY_DESKTOP=0          # Set to 1 to enable desktop notifications on rotation
NOTIFY_WEBHOOK_URL=""     # Webhook URL for Slack, Discord, or Telegram
NOTIFY_WEBHOOK_TYPE=""    # Type: slack, discord, telegram, or generic
```

## Account Groups

Tag accounts into groups and rotate only within a specific group:

```bash
codex-rotate group set personal-1 personal
codex-rotate group set personal-2 personal
codex-rotate group set work-1 work

codex-rotate group list
# GROUPS:
#   personal       personal-1, personal-2
#   work           work-1

codex-rotate run --group=work exec "Refactor the API"
codex-rotate auto --group=personal exec "Write tests"
```

## Background Daemon

The daemon monitors your Codex usage in the background and automatically rotates accounts when rate limits are hit — no wrapper needed. Works with any launcher: `omx`, `codex`, or `codex-rotate run`.

```bash
# Start the daemon
codex-rotate daemon start
# [OK] Daemon started (PID: 12345)
# [INFO] Monitoring codex log and quota API every 30s
# [INFO] Quota rotation threshold: 90%

# Check status
codex-rotate daemon status

# View rotation history
codex-rotate daemon logs

# Stop the daemon
codex-rotate daemon stop
```

**How it works:**
1. **Log watcher** — Tails `~/.codex/log/codex-tui.log` for rate-limit error messages
2. **Quota poller** — Calls the OpenAI usage API every `DAEMON_CHECK_INTERVAL` seconds
3. When either detects a rate limit (or quota ≥ `DAEMON_QUOTA_THRESHOLD`%), it marks the current account on cooldown, swaps `auth.json` to the next available account, and sends a notification

> **Tip**: Add `codex-rotate daemon start` to your shell startup (`.bashrc`/`.zshrc`) for always-on rotation.

## JSON Output

All display commands support `--json` for scripting and automation:

```bash
codex-rotate list --json | jq '.[].alias'
codex-rotate quota --json | jq '.[] | select(.five_hour_usage_pct > 80)'
codex-rotate status --json | jq '.config'
codex-rotate email --json | jq '.[].email'
```

## Notifications

Enable desktop notifications and/or webhooks to get alerted when rotation happens:

```bash
# Desktop notifications (Linux: notify-send, macOS: osascript)
# Set in ~/.codex-accounts/config.sh:
NOTIFY_DESKTOP=1

# Slack webhook
NOTIFY_WEBHOOK_URL="https://hooks.slack.com/services/T.../B.../xxx"
NOTIFY_WEBHOOK_TYPE="slack"

# Discord webhook
NOTIFY_WEBHOOK_URL="https://discord.com/api/webhooks/..."
NOTIFY_WEBHOOK_TYPE="discord"
```

## Interactive TUI

Launch a menu-driven interface (requires `whiptail` or `dialog`):

```bash
codex-rotate tui
```

Navigate with arrow keys — list accounts, check quota, switch accounts, run diagnostics, all from a single menu.

## Shell Completions

Tab completion is installed automatically with `npm install -g` and `make install`. To install manually:

**Bash** — add to `~/.bashrc`:
```bash
source /path/to/codex-rotate/completions/codex-rotate.bash
```

**Zsh** — add to `~/.zshrc`:
```bash
fpath=(/path/to/codex-rotate/completions $fpath)
autoload -U compinit && compinit
```

**Fish** — copy to completions dir:
```bash
cp completions/codex-rotate.fish ~/.config/fish/completions/
```

## System Diagnostics

Run `doctor` to verify your setup:

```bash
$ codex-rotate doctor
codex-rotate v1.3.0 — System Diagnostics
──────────────────────────────────────────────────

  Bash version (≥ 4 required)            [✓] v5.1.16
  jq (JSON processor)                    [✓] jq-1.6
  curl (HTTP client)                     [✓] curl 7.81.0
  flock (file locking)                   [✓] available
  Codex CLI                              [✓] /usr/local/bin/codex
  Accounts directory                     [✓] ~/.codex-accounts (700)
  Credentials directory                  [✓] ~/.codex-accounts/credentials (700)
  Auth symlink                           [✓] → ~/.codex-accounts/credentials/main.json
  Accounts configured                    [✓] 3 account(s)
  Active token health                    [✓] valid (expires in 2h 15m)

✓ All systems operational.
```

## What It Does / Does NOT Do

| ✅ Does | ❌ Does NOT |
|---------|------------|
| Manage multiple Codex CLI accounts | Create Codex accounts for you |
| Auto-rotate on rate limits (429, etc.) | Bypass or circumvent rate limits |
| Time-based rotation to balance usage | Send your credentials anywhere |
| Secure credential storage (700/600 perms) | Require internet for local switching |
| Atomic symlink switching (zero downtime) | Modify Codex CLI internals |
| Track per-account usage and cooldowns | Work on Windows (Linux/macOS only) |

> **Disclaimer**: This tool manages multiple legitimately-owned Codex CLI accounts. It does not bypass, circumvent, or evade rate limits — it switches between your own accounts when one hits its limit. Please ensure your usage complies with OpenAI's [Terms of Use](https://openai.com/policies/terms-of-use).

## Requirements

- **Bash 4+** — Required for associative arrays. macOS users: `brew install bash`.
- **jq** — JSON processor for auth files. The installer will auto-install if missing on Linux.
- **curl** — Required for `quota` and `refresh` commands (usually pre-installed).
- **flock** — Concurrent-safe file locking (part of `util-linux`). macOS users: `brew install util-linux`.
- **Codex CLI** — The official OpenAI Codex CLI must be installed.

## Uninstall

### npm

```bash
npm uninstall -g codex-rotate
```

### make

```bash
make uninstall
```

### Manual

```bash
rm -f ~/.local/bin/codex-rotate
rm -rf ~/.codex-accounts          # removes all saved accounts and config
```

> **Warning**: Removing `~/.codex-accounts` deletes all stored credentials and configuration. Back up first if needed.

## FAQ

**Does this work with Codex Teams/Pro/Free?**
Yes. It works with any account type that the Codex CLI supports.

**Is this safe?**
Yes. Credentials are stored in a dedicated directory with `700` permissions, and individual files use `600`. File locking prevents race conditions.

**What happens when all accounts are rate-limited?**
The script displays a warning that all accounts are on cooldown and exits with an error. Accounts automatically become available again after their cooldown period expires.

**Does it work on macOS?**
Yes, but macOS requires additional setup. macOS ships with Bash 3.x and does not include `flock`. Install both via Homebrew: `brew install bash util-linux`, then ensure the Homebrew `bash` and `flock` are in your `$PATH`.

**Can I use this with other AI CLI tools?**
It's designed for Codex CLI, but the auth.json symlink pattern could be adapted for other tools that use file-based authentication.

**How many accounts can I add?**
No hard limit. The tool uses flat files, so performance stays consistent regardless of account count.

## Companion Tools

codex-rotate manages accounts locally, but the same accounts can power AI agents on remote servers. Here's the full infrastructure this project supports:

### Hermes Agent

[Hermes](https://github.com/Lampese/codex-switcher) is a Python-based AI agent that uses the Chat Completions API. codex-rotate credentials work directly with Hermes — just copy the auth tokens to the Hermes credential pool.

- Uses Chat Completions API (`/v1/chat/completions`)
- Supports round-robin + failover rotation across multiple accounts
- Compatible with standard codex-rotate tokens (no extra scopes needed)

### OpenClaw

[OpenClaw](https://www.npmjs.com/package/openclaw) is a Telegram-based AI coding assistant that uses the Responses API.

- Uses Responses API (`/v1/responses`)
- Requires `api.responses.write` scope (re-authenticate via `openclaw configure`)
- Telegram bot interface for mobile coding assistance

### Shared Account Pool

All three tools can share the same OpenAI accounts. Use `codex-rotate email` to see your accounts, then configure Hermes and OpenClaw with the same credentials.

See [docs/INFRASTRUCTURE.md](docs/INFRASTRUCTURE.md) for full setup notes and configuration details.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, testing instructions, and pull request guidelines.

## License

[MIT](LICENSE) © 2025-2026 [vaskoyudha](https://github.com/vaskoyudha)
