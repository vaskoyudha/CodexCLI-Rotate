# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
