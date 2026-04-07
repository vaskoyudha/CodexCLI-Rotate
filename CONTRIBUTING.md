# Contributing to codex-rotate

Thank you for your interest in contributing! We welcome bug reports, feature requests, and pull requests.

## Reporting Issues

- **Bugs**: Open an [issue](https://github.com/vaskoyudha/CodexCLI-Rotate/issues) with a clear description, steps to reproduce, and expected vs. actual behavior.
- **Security**: See [SECURITY.md](SECURITY.md) for vulnerability reporting.

## Suggesting Features

Open an [issue](https://github.com/vaskoyudha/CodexCLI-Rotate/issues) with:
- Use case and motivation
- Proposed behavior
- Examples

## Development Setup

```bash
git clone https://github.com/vaskoyudha/CodexCLI-Rotate.git
cd CodexCLI-Rotate
```

### Dependencies

- **Bash** >= 4.0
- **jq** — JSON processor
- **ShellCheck** — static analysis for shell scripts
- **BATS** — Bash Automated Testing System

### Installing BATS

```bash
# macOS (Homebrew)
brew install bats-core

# Ubuntu / Debian
git clone --depth 1 --branch v1.11.1 https://github.com/bats-core/bats-core.git /tmp/bats
sudo /tmp/bats/install.sh /usr/local

# Verify
bats --version
```

### Running Tests

```bash
make lint          # ShellCheck on all scripts
make test          # BATS test suite (28 tests) — falls back to smoke test if BATS is missing
make clean         # Remove build artifacts
```

### Writing Tests

Tests live in `test/codex-rotate.bats`. Each test gets a clean sandboxed `$HOME` (via `test/test_helper.bash`) so nothing touches your real system.

```bash
@test "my new feature works" {
  run codex-rotate init
  assert_success

  run codex-rotate my-command --flag
  assert_success
  assert_output --partial "expected output"
}
```

Helpers available in every test:
- `assert_success` / `assert_failure` — check exit code
- `assert_output --partial "text"` — check stdout contains text
- `_install_fake_codex` — creates a stub `codex` binary (required for commands that resolve the codex path)

## Code Style

- **Bash**: Use POSIX-friendly syntax where possible
- **Strict mode**: All scripts must use `set -euo pipefail`
- **Functions**: Write functions instead of inline logic
- **Comments**: Document non-obvious logic only

## Pull Request Process

1. **Fork** the repository
2. **Create a branch**: `git checkout -b feat/your-feature`
3. **Commit**: Follow [conventional commits](https://www.conventionalcommits.org/) (e.g., `feat: add X`, `fix: resolve Y`)
4. **Test**: Run `make lint` and `make test` — both must pass
5. **Push** and open a PR

## Commit Format

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `test:` Tests
- `refactor:` Code refactoring
- `chore:` Maintenance

Example: `git commit -m "feat: add concurrent account switching"`

Thanks for contributing!
