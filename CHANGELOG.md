# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.1] - 2026-04-07

### Fixed
- All repository slug references updated from `MultipleAccountCodex` to `CodexCLI-Rotate` across public-facing files (README, CONTRIBUTING, SECURITY, install.sh, Formula, bin/codex-rotate, package.json, issue templates, plan docs)
- Homebrew Formula now includes real `sha256` checksum for the release tarball
- CONTRIBUTING.md test count corrected from 28 to 116
- Removed rogue automation comment from bin/codex-rotate

### Changed
- GitHub Discussions enabled for community Q&A (issue template contact link now resolves)

## [1.3.0] - 2025-04-06

### Added
- **`daemon` command** — Background process that monitors Codex TUI logs and OpenAI quota API for rate-limit detection. Automatically rotates accounts by swapping `auth.json` symlink when limits are hit — works with any launcher (omx, codex, codex-rotate run).
  - `daemon start` — start background daemon
  - `daemon stop` — stop running daemon
  - `daemon status` — show daemon status and rotation history
  - `daemon logs [N]` — show last N daemon log entries
- Dual detection: log file watcher (instant) + quota API polling (proactive)
- Config variables: `DAEMON_CHECK_INTERVAL`, `DAEMON_QUOTA_THRESHOLD`, `CODEX_LOG_PATH`
- Shell completions for `daemon` subcommands (bash, zsh, fish)

### Fixed
- **Rate limit detection regex** — Added `usage limit` and `you've hit` patterns to match actual Codex CLI error: "You've hit your usage limit". Previously only matched "you've reached" and missed the real error message.

## [1.2.0] - 2025-04-05

### Added
- **`doctor` command** — System diagnostics checking Bash version, jq, curl, flock, Codex CLI, directory permissions, symlink health, account count, and token expiry
- **`upgrade` command** — Self-update via npm with changelog preview
- **`tui` command** — Interactive terminal menu via whiptail/dialog for navigating all features without memorizing commands
- **`group` command** — Account grouping system (`group set/unset/list`) to tag accounts and scope rotation with `--group=<name>`
- **`--json` output flag** — Machine-readable JSON output for `list`, `status`, `quota`, and `email` commands
- **Notification system** — Desktop notifications (notify-send/osascript) and webhook alerts (Slack, Discord, Telegram, generic) triggered on account rotation events
- **Shell completions** — Tab completion for bash, zsh, and fish with dynamic account alias completion
- **Homebrew formula** — `brew tap vaskoyudha/tap && brew install codex-rotate`
- **VHS demo tape** — Reproducible terminal recording script (`demo.tape`) for generating README demo GIFs
- Config variables: `NOTIFY_DESKTOP`, `NOTIFY_WEBHOOK_URL`, `NOTIFY_WEBHOOK_TYPE`
- `--group=<name>` flag for `run` and `auto` commands to rotate only within a group
- `--group=<name>` flag for `add` command to assign group on creation
- Makefile targets: `install-completions` for manual completion installation
- 23 new BATS tests (107 total)

### Changed
- Features list in README expanded from 10 to 18 items
- Usage command table includes all new commands
- Makefile `install` target now also installs shell completions
- Makefile `uninstall` target now also removes shell completions
- `.npmignore` updated to include completions, exclude Formula and demo files

## [1.1.5] - 2025-04-05

### Fixed
- **`refresh --all` now works** — `--all` flag is properly parsed instead of being treated as an alias name; no-arg refresh already refreshed all accounts, now `--all` does the same explicitly

### Changed
- Help text documents `refresh [alias|--all]` with description

### Added
- BATS tests for `refresh --all`, no-arg refresh-all, and help text (85 total tests)

## [1.1.4] - 2025-04-05

### Fixed
- **Refresh preserves existing `id_token`** — when the OAuth refresh response omits `id_token`, the existing token is kept instead of being blanked (prevents losing email/plan/account-id claims)
- **Quota error messages are specific** — network errors, auth failures (401/403), invalid JSON, and missing tokens now report distinct diagnostics instead of generic "token may be expired"
- **Version consistency** — synced README demo banner, `SCRIPT_VERSION`, and `package.json` to 1.1.4

### Added
- Regression tests for: refresh without `id_token`, malformed JWTs, missing email claim, usage 401/403 auto-refresh retry, invalid usage JSON, and full `cmd_auto` path through `flock`

## [1.1.3] - 2025-04-05

### Fixed
- **Smart rotation now works in `auto` mode** — `QUOTA_AWARE_ROTATION` flag was lost when `cmd_auto` spawned a subprocess via `flock`; the subprocess re-entered `load_config` which reset the flag to 0. Fixed by exporting `CODEX_ROTATE__QUOTA_AWARE=1` as an environment variable that survives the subprocess boundary.

### Added
- BATS test proving quota-aware auto selection picks the lowest-usage account (71 total tests)

## [1.1.2] - 2025-04-05

### Fixed
- Sync `SCRIPT_VERSION` in binary, README demo banner, and `package.json` to match release version
- Add BATS test asserting `help` output reports the correct version (70 total tests)

## [1.1.1] - 2025-04-05

### Fixed
- `refresh` command now returns non-zero exit code when any token refresh fails
- Refresh token values are URL-encoded before sending to OAuth endpoint
- `quota` command correctly parses both Unix epoch and ISO 8601 `reset_at` timestamps
- `query_usage_api` auto-retries once on 401/403 by refreshing the access token
- `query_usage_api` falls back to extracting `account_id` from JWT when not in credentials file
- `help` text for `list` now accurately describes all 7 columns (alias, email, status, uses, plan, last used, cooldown)
- README demo examples updated to match current 7-column list/status output

### Added
- `parse_reset_epoch()` helper function for robust reset timestamp handling
- 7 new mocked-API BATS tests covering quota display, refresh success/failure, credential file updates, help accuracy, and epoch timestamp parsing (69 total tests)

## [1.1.0] - 2025-04-05

### Added
- `quota` command — real-time usage/quota display from OpenAI API (5-hour + weekly windows)
- `email` command — extract and display email/plan from account JWT tokens
- `refresh` command — refresh access tokens using stored refresh_token
- Quota-aware rotation — `auto` mode prefers accounts with lowest usage percentage
- Enhanced `list` output with email and plan type columns
- Enhanced `status` dashboard with email, plan type, wider layout
- JWT claim extraction helpers (email, plan type, account ID)
- Usage bar visualization with color coding (green/yellow/red)
- Token refresh mechanism via OpenAI OAuth endpoint
- BATS tests for all new features (16 new test cases, 62 total)

### Changed
- `list` now shows 7 columns: ALIAS, EMAIL, STATUS, USES, PLAN, LAST USED, COOLDOWN
- `status` dashboard is wider and includes email/plan per account
- `auto` mode uses quota-aware rotation (prefers lowest usage) with round-robin fallback

## [1.0.0] - 2025-04-04

### Added
- Multi-account management with `add`, `import`, `remove`, `list`, `switch` commands
- Automatic rate-limit detection and account rotation via `run` command
- Time-based rotation via `auto` command
- Per-account cooldown tracking with configurable durations
- Atomic symlink swap for zero-downtime account switching
- Concurrent-safe state management with flock-based locking
- Interactive browser-based account setup via `add` command
- Configurable rotation intervals, cooldowns, and retry limits
- Status dashboard showing all accounts and their states
- npm global installation support
- curl one-liner installation
- Makefile with install, uninstall, lint targets
