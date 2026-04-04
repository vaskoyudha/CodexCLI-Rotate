# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 1.x     | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in codex-rotate, please report it responsibly:

1. **Do not** open a public GitHub issue for security vulnerabilities
2. Email your findings or open a [private security advisory](https://github.com/vaskoyudha/MultipleAccountCodex/security/advisories/new)
3. Include steps to reproduce the vulnerability
4. Allow reasonable time for a fix before public disclosure

## Security Design

codex-rotate stores Codex CLI credentials locally with the following protections:

- **Directory permissions**: `~/.codex-accounts/` is created with `700` (owner-only access)
- **File permissions**: Credential files use `600` (owner read/write only)
- **No network transmission**: Credentials are never sent anywhere — they stay on your local filesystem
- **Atomic operations**: Symlink swaps and flock-based locking prevent partial-write corruption
