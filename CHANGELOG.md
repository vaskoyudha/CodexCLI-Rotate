# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
