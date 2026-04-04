# codex-rotate

Multi-account manager for Codex CLI with automatic rotation on rate limits

![License](https://img.shields.io/github/license/vaskoyudha/MultipleAccountCodex)
![NPM Version](https://img.shields.io/npm/v/codex-rotate)
![GitHub Stars](https://img.shields.io/github/stars/vaskoyudha/MultipleAccountCodex)
![GitHub Issues](https://img.shields.io/github/issues/vaskoyudha/MultipleAccountCodex)
![ShellCheck](https://img.shields.io/github/actions/workflow/status/vaskoyudha/MultipleAccountCodex/shellcheck.yml?label=shellcheck)

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
make install # or sudo cp bin/codex-rotate /usr/local/bin/
```

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

1. **Transparent Wrapper**: `codex-rotate run` wraps the official Codex CLI, passing all arguments directly.
2. **Signal Monitoring**: It monitors `stderr` for rate-limit signals (e.g., `429`, `usageLimitExceeded`, `rate limit`).
3. **Atomic Swap**: Upon detection, it atomically swaps the `~/.codex/auth.json` symlink to the next available account.
4. **Auto-Retry**: The command is automatically retried with the new account (up to `MAX_RETRIES`).

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

## Requirements

- **Bash 4+**: Modern bash features required for associative arrays.
- **jq**: For processing Codex JSON authentication files.
- **flock**: For safe concurrent account switching (part of `util-linux`).
- **Codex CLI**: The official OpenAI Codex CLI must be installed.

## FAQ

**Does this work with Codex Teams/Pro/Free?**
Yes. It works with any account type that the Codex CLI supports.

**Is this safe?**
Yes. Credentials are stored in a dedicated directory with `700` permissions, and individual files use `600`. File locking prevents race conditions.

**What happens when all accounts are rate-limited?**
The script will display a warning indicating all accounts are on cooldown and exit with an error.

**Does it work on macOS?**
Yes, but macOS ships with an ancient version of Bash. Use `brew install bash` to get Bash 4+ and ensure it's in your `$PATH`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
