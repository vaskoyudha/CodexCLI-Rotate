# Contributing to codex-rotate

Thank you for your interest in contributing! We welcome bug reports, feature requests, and pull requests.

## Reporting Issues

- **Bugs**: Open an [issue](https://github.com/vaskoyudha/MultipleAccountCodex/issues) with a clear description, steps to reproduce, and expected vs. actual behavior.
- **Security**: See [SECURITY.md](SECURITY.md) for vulnerability reporting.

## Suggesting Features

Open an [issue](https://github.com/vaskoyudha/MultipleAccountCodex/issues) with:
- Use case and motivation
- Proposed behavior
- Examples

## Development Setup

```bash
git clone https://github.com/vaskoyudha/MultipleAccountCodex.git
cd MultipleAccountCodex
```

Test your changes:
```bash
shellcheck bin/codex-rotate install.sh
make test
```

## Code Style

- **Bash**: Use POSIX-friendly syntax where possible
- **Strict mode**: All scripts must use `set -euo pipefail`
- **Functions**: Write functions instead of inline logic
- **Comments**: Document non-obvious logic

## Pull Request Process

1. **Fork** the repository
2. **Create a branch**: `git checkout -b feat/your-feature`
3. **Commit**: Follow [conventional commits](https://www.conventionalcommits.org/) (e.g., `feat: add X`, `fix: resolve Y`)
4. **Test**: Run `make lint` and `make test`
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
