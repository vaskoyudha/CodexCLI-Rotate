# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
