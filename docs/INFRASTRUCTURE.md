# Multi-Tool Infrastructure Guide

codex-rotate credentials can be shared with other AI coding tools that use OpenAI authentication. This guide covers how to set up a multi-tool infrastructure using codex-rotate as your central account manager.

## Architecture Overview

```
Local Machine                          Remote Server (optional)
+-------------------+                  +-------------------+
| codex-rotate      |  copy tokens     | Hermes Agent      |
| (account manager) | ---------------> | (Chat Completions)|
|                   |                  +-------------------+
| ~/.codex-accounts |  copy tokens     +-------------------+
| ~/.codex/auth.json| ---------------> | OpenClaw          |
+-------------------+                  | (Responses API)   |
                                       +-------------------+
```

## Tool 1: codex-rotate (Local)

The central account manager. All other tools receive credentials from here.

- **Installation:** `npm install -g codex-rotate`
- **Config directory:** `~/.codex-accounts/`
- **Credentials:** `~/.codex-accounts/credentials/<alias>.json`
- **Auth symlink:** `~/.codex/auth.json` (managed by codex-rotate)
- **Background daemon:** `codex-rotate daemon start`

### Key Commands

| Command | Purpose |
|---------|---------|
| `codex-rotate add <alias>` | Add a new account via browser login |
| `codex-rotate list` | Show all accounts with status |
| `codex-rotate quota` | Check usage against rate limits |
| `codex-rotate email` | Display account emails and plans |
| `codex-rotate refresh --all` | Refresh all access tokens |
| `codex-rotate daemon start` | Start background auto-rotation |

## Tool 2: Hermes Agent (Remote)

A Python-based AI agent that uses the **Chat Completions API** (`/v1/chat/completions`).

### Setup

1. Install Hermes on your remote server
2. Copy codex-rotate credentials to Hermes auth pool:
   ```bash
   # On local machine, get the token
   cat ~/.codex-accounts/credentials/<alias>.json

   # On remote server, add to Hermes auth
   # Edit ~/.hermes/auth.json to include the credentials
   ```
3. Configure rotation in `~/.hermes/config.yaml` (round-robin + failover)

### Commands

- `hermes status` — Check agent health
- `hermes gateway run --replace` — Restart gateway

### Known Issue: Empty Streaming Output

The Codex API's `response.completed` SSE event may return `"output": []` even when streaming deltas contain text. If Hermes returns empty responses, patch the agent script to collect items from `response.output_item.done` events during streaming instead of relying on `stream.get_final_response()`.

## Tool 3: OpenClaw (Remote)

A Telegram-based AI coding assistant that uses the **Responses API** (`/v1/responses`).

### Setup

1. Install OpenClaw: `npm install -g openclaw`
2. Configure via: `openclaw configure`
3. Manage as a systemd service: `systemctl --user restart openclaw-gateway.service`

### Important: Token Scope Requirements

OpenClaw uses the Responses API, which requires the `api.responses.write` scope. Tokens created by codex-rotate or Codex CLI may only have Chat Completions scopes. If you see "Missing scopes" errors:

1. Run `openclaw configure` on the server
2. Re-authenticate each account through the device code flow
3. This grants the correct scopes for the Responses API

codex-rotate tokens (Chat Completions scopes) work with Hermes but **not** with OpenClaw without re-authentication.

### Known Issue: IPv6 Timeout on VPS

If OpenClaw's Telegram connection times out on a VPS with IPv6 enabled but no global IPv6 address, force IPv4-first DNS resolution:

```bash
# In the systemd service file, add to ExecStart:
--dns-result-order=ipv4first

# And add environment variable:
Environment=NODE_OPTIONS=--dns-result-order=ipv4first
```

## API Compatibility Matrix

| Tool | API Endpoint | Required Scopes | codex-rotate tokens work? |
|------|-------------|----------------|--------------------------|
| Codex CLI | Chat Completions | standard | Yes (native) |
| Hermes | `/v1/chat/completions` | standard | Yes |
| OpenClaw | `/v1/responses` | `api.responses.write` | No (re-auth needed) |

## Shared Account Pool

All three tools can use the same OpenAI accounts. Use codex-rotate as the source of truth:

```bash
# View all accounts
codex-rotate email

# Check usage across accounts
codex-rotate quota

# Refresh tokens (local only — remote tools need manual update)
codex-rotate refresh --all
```

## Technical Reference

- **OAuth refresh endpoint:** `POST https://auth.openai.com/oauth/token` with `grant_type=refresh_token`
- **Model compatibility:** ChatGPT-based accounts use model `gpt-5.4`
- **Token refresh:** Tokens can be refreshed using stored `refresh_token` values

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Hermes returns empty responses | Check that the streaming output collection patch is applied |
| OpenClaw Telegram timeout | Add IPv4-first DNS flags to systemd service |
| OpenClaw "Missing scopes" error | Re-authenticate via `openclaw configure` |
| Token expired | Run `codex-rotate refresh --all` locally |
| Unstable SSH to remote | Use `ssh -o ConnectTimeout=15 -o ServerAliveInterval=3` |
