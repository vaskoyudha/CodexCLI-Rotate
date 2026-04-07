# Infrastructure Setup Notes: Multi-Tool AI Coding

This document serves as operational documentation for the multi-account AI coding infrastructure, covering local and remote tools, configurations, and troubleshooting procedures.

## Tool 1: codex-rotate (Local Machine)

The multi-account manager for Codex CLI handles automated credential rotation on the local workstation.

*   **Version:** 1.3.0 (published on npm)
*   **Installation:** `npm install -g codex-rotate`
*   **Configuration Directory:** `~/.codex-accounts/`
*   **Credentials Storage:** `~/.codex-accounts/credentials/*.json`
*   **Authentication Symlink:** `~/.codex/auth.json` (managed and rotated by codex-rotate)
*   **Background Management:** Use `codex-rotate daemon start` for automated rotation.

### Managed Accounts
*   **seragithub27@gmail.com (main):** Team plan, active.
*   **seragithub19@gmail.com (account3):** Team plan, active.

### Core Commands
*   `add`: Register a new account.
*   `list`: View all registered accounts.
*   `status`: Check current active account and rotation state.
*   `quota`: View remaining usage for accounts.
*   `email`: Display email addresses and plan types from account tokens.
*   `run`: Execute a command using a specific account.
*   `auto`: Toggle automatic rotation logic.
*   `daemon`: Manage the background rotation process.
*   `doctor`: Run diagnostic checks on the environment.
*   `tui`: Launch the interactive terminal UI.
*   `refresh`: Update tokens for accounts.

## Tool 2: Hermes Agent (Remote Droplet)

AI agent running on a DigitalOcean droplet for persistent background tasks.

*   **Host:** 157.230.39.218 (root@157.230.39.218)
*   **Version:** 0.7.0
*   **SSH Access:** Configured as `ssh droplet` using `~/.ssh/id_ed25519`.
*   **Configuration:** `/root/.hermes/config.yaml` (utilizes round-robin and failover rotation).
*   **Authentication Pool:** `/root/.hermes/auth.json` (contains seragithub27, seragithub19, and vascoyudha2).
*   **Agent Logic:** `/root/.hermes/hermes-agent/run_agent.py`.
*   **Logs:** `/root/.hermes/logs/agent.log`.

### Operational Commands
*   `hermes status`: Check agent health and active account.
*   `hermes gateway run --replace`: Restart the gateway and replace existing process.

### Critical Patch Information
The `run_agent.py` script contains three specific modifications to address a bug in the Codex API where `response.completed` SSE events return an empty `output` array despite valid streaming data. The patch ensures output is collected from `response.output_item.done` events instead.

## Tool 3: OpenClaw (Remote Droplet)

Telegram-based AI coding assistant running on the same DigitalOcean droplet.

*   **Version:** 2026.4.5
*   **Telegram Bot:** @VynsClaw_bot
*   **Main Config:** `/root/.openclaw/openclaw.json` (Allowlist: "93372553", "5170950996").
*   **Agent Auth:** `/root/.openclaw/agents/main/agent/auth-profiles.json` (seragithub27, seragithub19).
*   **Binary Path:** `/usr/bin/openclaw` (installed via npm).

### Service Management
Restart the service using: `systemctl --user restart openclaw-gateway.service`.

### Network Configuration (IPv6 Workaround)
The systemd service is modified with `--dns-result-order=ipv4first` in `ExecStart` and the environment variable `NODE_OPTIONS=--dns-result-order=ipv4first`. This prevents timeouts caused by the droplet having IPv6 enabled without a global IPv6 address.

### Known Scopes Issue
Existing tokens may lack the `api.responses.write` scope required by the OpenClaw Responses API. If "Missing scopes" errors occur, run `openclaw configure` interactively to re-authenticate with full permissions.

## Account Matrix

| Account | Email | Plan | Status | Primary Use |
| :--- | :--- | :--- | :--- | :--- |
| main | seragithub27@gmail.com | team | Active | codex-rotate, Hermes, OpenClaw |
| account3 | seragithub19@gmail.com | team | Active | codex-rotate, Hermes, OpenClaw |
| vascoyudha2 | vascoyudha2@gmail.com | team | Active | Hermes only |

## Troubleshooting

*   **Empty Hermes Responses:** Verify that the `run_agent.py` patch for SSE event handling is still applied.
*   **OpenClaw Telegram Failures:** Check the systemd service configuration for the IPv4-first DNS flags.
*   **OpenClaw Scope Errors:** Re-authenticate the relevant profiles using `openclaw configure` to obtain the `api.responses.write` scope.
*   **Token Expiration:** Run `codex-rotate refresh --all` locally. Remote tools require manual token updates if automated refresh fails.
*   **Unstable SSH:** For remote command execution, use robust flags: `ssh -o ConnectTimeout=15 -o ServerAliveInterval=3 droplet 'command'`.

## Technical Reference

*   **APIs Used:** Hermes utilizes the Chat Completions API (`/v1/chat/completions`). OpenClaw utilizes the Responses API (`/v1/responses`).
*   **OAuth Endpoint:** `POST https://auth.openai.com/oauth/token` using Client ID `app_EMoamEEZ73f0CkXaXp7hrann`.
*   **Model Compatibility:** ChatGPT-based accounts must use model `gpt-5.4`.
