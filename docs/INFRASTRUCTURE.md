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

## Hermes Credential Pool Rotation — Bug & Fix

### The Problem

Hermes supports multi-account credential rotation via a `credential_pool` in `~/.hermes/auth.json`. When a 429 rate limit is hit, the agent is supposed to rotate to the next credential and retry. However, with multiple accounts, the rotation would fail silently — the agent would report "Max retries (3) exhausted" and give up.

### Root Cause

The retry loop in `run_agent.py` had `max_retries = 3` hardcoded. The rotation flow per credential costs **2 retry iterations**:

1. **First 429**: Sets `has_retried_429 = True`, increments `retry_count`
2. **Second 429**: Calls `mark_exhausted_and_rotate()`, swaps credential, does NOT increment `retry_count`

So each credential burns 1 retry slot. With `max_retries=3`, only 3 credentials could be attempted before the agent gave up.

**Compounding factor — shared team plan limits**: OpenAI team accounts share rate limits across all members. If `user-a@team-1` is rate-limited, `user-b@team-1` is also rate-limited. The rotation would cycle through same-team accounts, wasting retry slots on credentials that are guaranteed to fail.

Example with 7 accounts across 3 teams:
```
[0] device_code          → team-1 (exhausted)
[1] seragithub27         → team-1 (exhausted — same team)
[2] seragithub19         → team-1 (exhausted — same team)
[3] seravasco1           → team-2 (exhausted — different team, but also hit limit)
[4] seravasco66          → team-2 (exhausted — same team)
[5] seravasco2           → team-2 (exhausted — same team)
[6] vascoyudha1          → team-3 (FRESH — but max_retries=3 gives up before reaching here)
```

### The Fix

In `run_agent.py`, scale `max_retries` by the credential pool size:

```python
# Before the retry loop (around line 7370)
retry_count = 0
max_retries = 3
_pool = self._credential_pool
if _pool is not None:
    _n_pool = len(_pool.entries())
    if _n_pool > 1:
        max_retries = max(max_retries, _n_pool * 2)
```

With 7 pool entries → `max_retries = 14`, enough to cycle through all accounts including same-team duplicates.

### Applying the Patch

1. Find the retry loop in `run_agent.py` (search for `max_retries = 3` near the streaming API call)
2. Add the pool-size scaling code immediately after `max_retries = 3`
3. Restart Hermes: `systemctl --user restart hermes-gateway.service`

### Credential Pool Format (`~/.hermes/auth.json`)

```json
{
  "credential_pool": {
    "openai-codex": [
      {
        "label": "account-alias",
        "access_token": "eyJ...",
        "refresh_token": "v1.MR...",
        "expires_at": 1775600000,
        "status": "fresh",
        "request_count": 0
      }
    ]
  }
}
```

Each entry can have `status`: `fresh`, `exhausted`, or `null`. The pool automatically marks entries as `exhausted` on 429 and rotates to the next `fresh` entry.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Hermes returns empty responses | Check that the streaming output collection patch is applied |
| OpenClaw Telegram timeout | Add IPv4-first DNS flags to systemd service |
| OpenClaw "Missing scopes" error | Re-authenticate via `openclaw configure` |
| Token expired | Run `codex-rotate refresh --all` locally |
| Unstable SSH to remote | Use `ssh -o ConnectTimeout=15 -o ServerAliveInterval=3` |
