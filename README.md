```
  ___  ___  ___  _____ __  __     ___  ___ _____ _ _____ ___
 / __|/ _ \|   \| __\ \/ / ___  | _ \/ _ \_   _/_\_   _| __|
| (__| (_) | |) | _| >  < |___| |   / (_) || |/ _ \| | | _|
 \___|\___/|___/|___/_/\_\       |_|_\\___/ |_/_/ \_\_| |___|
```

**Multi-account manager for Codex CLI with automatic rotation on rate limits.**

![License](https://img.shields.io/github/license/vaskoyudha/MultipleAccountCodex)
![NPM Version](https://img.shields.io/npm/v/codex-rotate)
![GitHub Stars](https://img.shields.io/github/stars/vaskoyudha/MultipleAccountCodex)
![GitHub Issues](https://img.shields.io/github/issues/vaskoyudha/MultipleAccountCodex)
![ShellCheck](https://img.shields.io/github/actions/workflow/status/vaskoyudha/MultipleAccountCodex/ci.yml?label=shellcheck)

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
  ACCOUNT      STATUS      LAST USED
  personal *   ready       2 min ago
  work         ready       just now

$ codex-rotate run exec "Refactor the auth module to use JWT"
[INFO] Running with account 'personal'...
# ... codex runs normally ...
# Rate limit detected on stderr!
[WARN] Rate limit hit on 'personal' — switching to 'work'
[INFO] Swapped to 'work' (symlink updated atomically)
[INFO] Retrying command with 'work'...
# ... codex continues seamlessly ...

$ codex-rotate status
╔══════════════════════════════════════════════════════════╗
║                  codex-rotate dashboard                  ║
╠══════════════════════════════════════════════════════════╣
║  ACCOUNT     STATUS     USES   COOLDOWN   LAST USED     ║
║  personal    cooldown   14     47m left   3 min ago      ║
║  work *      ready      3      —          just now       ║
╚══════════════════════════════════════════════════════════╝
```

---

## Why codex-rotate?

- Hit the rate limit mid-session? **codex-rotate** auto-switches to your next account in milliseconds.
- Managing multiple Codex accounts? One command to add, switch, and track them all.
- Exhausted your daily or hourly limits? Automated cooldown management ensures you always use a fresh account.
- Need high-throughput CLI usage? Transparent wrapper handles retries and rotation without manual intervention.

## Features

- 🔄 **Auto-rotation** — Detects `429`, `usageLimitExceeded`, and other rate-limit signals to instantly swap accounts.
- ⏰ **Time-based rotation** — Optionally rotate accounts every N hours to balance usage across your fleet.
- 🔒 **Secure storage** — Credentials stored in `~/.codex-accounts/` with strict `700`/`600` permissions.
- ⚡ **Atomic switching** — Uses symlink swapping for `~/.codex/auth.json` to ensure zero-downtime transitions.
- 📊 **Per-account tracking** — Built-in dashboard for usage counts, cooldown timers, and last-used timestamps.
- 🛡️ **Concurrent-safe** — Robust `flock`-based file locking prevents state corruption during parallel execution.

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
curl -fsSL https://raw.githubusercontent.com/vaskoyudha/MultipleAccountCodex/main/install.sh | bash
```

### Manual

```bash
git clone https://github.com/vaskoyudha/MultipleAccountCodex.git
cd MultipleAccountCodex
make install
```

> **Note**: `npm install -g` installs to npm's global prefix (usually `/usr/local/bin`). The curl installer and `make install` install to `~/.local/bin` — make sure it's in your `$PATH`. The installer will detect your shell and tell you the exact line to add if needed.

## Usage

| Command | Description | Example |
|---------|-------------|---------|
| `init` | Initialize structure in `~/.codex-accounts/` | `codex-rotate init` |
| `add` | Add account via browser login | `codex-rotate add my-acc` |
| `import` | Import an existing `auth.json` | `codex-rotate import old-acc ./auth.json` |
| `remove` | Remove an account from rotation | `codex-rotate remove my-acc` |
| `list` | List accounts with simplified status | `codex-rotate list` |
| `switch` | Manually switch the active account | `codex-rotate switch my-acc` |
| `status` | Show detailed dashboard | `codex-rotate status` |
| `run` | Wrap command with rate-limit rotation | `codex-rotate run exec "prompt"` |
| `auto` | Wrap with time + rate-limit rotation | `codex-rotate auto exec "prompt"` |
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
2. **Signal Monitoring** — Monitors `stderr` for rate-limit signals (`429`, `usageLimitExceeded`, `rate limit`).
3. **Atomic Swap** — Swaps the `~/.codex/auth.json` symlink to the next available account.
4. **Auto-Retry** — Retries the command with the new account (up to `MAX_RETRIES`).

## Configuration

Settings are stored in `~/.codex-accounts/config.sh`:

```bash
ROTATION_INTERVAL=10800   # Time-based rotation interval (3 hours)
HOURLY_COOLDOWN=3600      # Cooldown for hourly rate limit (1 hour)
DAILY_COOLDOWN=86400      # Cooldown for daily rate limit (24 hours)
WEEKLY_COOLDOWN=604800    # Cooldown for weekly rate limit (7 days)
MAX_RETRIES=3             # Max retries after rate limit
CODEX_BIN=""              # Path to codex binary (auto-detected if empty)
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

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, testing instructions, and pull request guidelines.

## License

[MIT](LICENSE) © 2025 [vaskoyudha](https://github.com/vaskoyudha)
