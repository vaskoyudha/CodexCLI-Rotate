# MultipleAccountCodex

A Bash-based multi-account manager for [Codex CLI](https://github.com/openai/codex) with automatic rotation when usage limits are hit.

## Features

- 🔄 **Auto-rotation** — detects rate limits (`429`, `usageLimitExceeded`, etc.) and instantly switches to the next available account
- ⏰ **Time-based rotation** — optionally rotate accounts every N hours (default: 3h)
- 🔒 **Secure storage** — credentials stored in `~/.codex-accounts/` with `700`/`600` permissions
- ⚡ **Atomic switching** — symlink swap of `~/.codex/auth.json`, zero downtime
- 📊 **Per-account tracking** — usage counts, cooldown timers, last-used timestamps
- 🛡️ **Concurrent-safe** — `flock`-based locking on all state mutations

## Installation

```bash
git clone https://github.com/vaskoyudha/MultipleAccountCodex.git
cd MultipleAccountCodex
bash install-codex-rotate.sh
```

## Quick Start

```bash
# Add accounts (opens browser login for each)
codex-rotate add account1
codex-rotate add account2

# Or import existing auth.json files
codex-rotate import account1 /path/to/auth1.json
codex-rotate import account2 /path/to/auth2.json

# Use as transparent wrapper — auto-rotates on rate limits
codex-rotate run exec "your prompt here"

# Time-based rotation (rotates if account used > 3h ago)
codex-rotate auto exec "your prompt here"

# Check all account statuses
codex-rotate status
```

## Commands

| Command | Description |
|---------|-------------|
| `codex-rotate init` | Initialize `~/.codex-accounts/` structure |
| `codex-rotate add <alias>` | Add account via interactive browser login |
| `codex-rotate import <alias> <path>` | Import existing `auth.json` |
| `codex-rotate remove <alias>` | Remove an account |
| `codex-rotate list` | List all accounts with status |
| `codex-rotate switch <alias>` | Manually switch active account |
| `codex-rotate status` | Full dashboard view |
| `codex-rotate run [args]` | Wrapper with auto rate-limit rotation |
| `codex-rotate auto [args]` | Wrapper with time-based + rate-limit rotation |
| `codex-rotate cooldown <alias>` | Manually put account on cooldown |
| `codex-rotate uncooldown <alias>` | Clear cooldown |
| `codex-rotate help` | Show help |

## How Rotation Works

1. `codex-rotate run exec "..."` wraps the `codex` command
2. If codex exits with a non-zero code **and** output contains rate-limit signals → marks account on cooldown
3. Atomically swaps `~/.codex/auth.json` symlink to next available account
4. Retries the command (up to `MAX_RETRIES`, default: 3)

## Configuration

Edit `~/.codex-accounts/config.sh`:

```bash
ROTATION_INTERVAL=10800   # Time-based rotation interval (seconds) — 3 hours
HOURLY_COOLDOWN=3600      # Cooldown for hourly rate limit — 1 hour
DAILY_COOLDOWN=86400      # Cooldown for daily rate limit — 24 hours
WEEKLY_COOLDOWN=604800    # Cooldown for weekly rate limit — 7 days
MAX_RETRIES=3             # Max retries after rate limit before giving up
CODEX_BIN=""              # Override codex binary path (auto-detected if empty)
```

## Requirements

- Bash 4+
- `jq` (auto-installed by `install-codex-rotate.sh` if missing)
- `flock` (part of `util-linux`, pre-installed on most Linux systems)
- [Codex CLI](https://github.com/openai/codex) installed

## License

MIT
