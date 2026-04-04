#!/usr/bin/env bats

load test_helper

# ---------------------------------------------------------------------------
# Helper: create a fake codex binary so load_config → resolve_codex_bin passes
# ---------------------------------------------------------------------------

_install_fake_codex() {
  mkdir -p "$HOME/bin"
  printf '#!/usr/bin/env bash\necho "fake codex"\n' > "$HOME/bin/codex"
  chmod +x "$HOME/bin/codex"
  export PATH="$HOME/bin:$PATH"
}

# ---------------------------------------------------------------------------
# Help command
# ---------------------------------------------------------------------------

@test "help command exits 0" {
  run codex-rotate help
  assert_success
}

@test "help output contains Usage" {
  run codex-rotate help
  assert_success
  assert_output_contains "Usage:"
}

@test "help output contains Commands section" {
  run codex-rotate help
  assert_success
  assert_output_contains "Commands:"
}

@test "help output lists core commands" {
  run codex-rotate help
  assert_success
  assert_output_contains "init"
  assert_output_contains "add"
  assert_output_contains "list"
  assert_output_contains "switch"
  assert_output_contains "run"
}

@test "help output contains Notes section" {
  run codex-rotate help
  assert_success
  assert_output_contains "Notes:"
}

@test "no args shows help" {
  run codex-rotate
  assert_success
  assert_output_contains "Usage:"
}

# ---------------------------------------------------------------------------
# Init command
# ---------------------------------------------------------------------------

@test "init creates accounts directory" {
  run codex-rotate init
  assert_success
  [[ -d "$HOME/.codex-accounts" ]]
}

@test "init creates credentials dir" {
  run codex-rotate init
  assert_success
  [[ -d "$HOME/.codex-accounts/credentials" ]]
}

@test "init creates config.sh" {
  run codex-rotate init
  assert_success
  assert_file_exists "$HOME/.codex-accounts/config.sh"
}

@test "init creates state.json" {
  run codex-rotate init
  assert_success
  assert_file_exists "$HOME/.codex-accounts/state.json"
}

@test "init creates order file" {
  run codex-rotate init
  assert_success
  assert_file_exists "$HOME/.codex-accounts/order"
}

@test "init creates active file" {
  run codex-rotate init
  assert_success
  assert_file_exists "$HOME/.codex-accounts/active"
}

@test "init is idempotent" {
  run codex-rotate init
  assert_success
  run codex-rotate init
  assert_success
}

@test "init state.json has valid JSON" {
  run codex-rotate init
  assert_success
  run jq '.' "$HOME/.codex-accounts/state.json"
  assert_success
}

# ---------------------------------------------------------------------------
# List on empty state
# ---------------------------------------------------------------------------

@test "list on fresh init shows header" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  run codex-rotate list
  assert_success
  assert_output_contains "ALIAS"
}

@test "list on fresh init shows none marker" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  run codex-rotate list
  assert_success
  assert_output_contains "(none)"
}

# ---------------------------------------------------------------------------
# Status command
# ---------------------------------------------------------------------------

@test "status on fresh init shows dashboard" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  run codex-rotate status
  assert_success
  assert_output_contains "Codex Account Rotation Manager"
}

# ---------------------------------------------------------------------------
# Import command
# ---------------------------------------------------------------------------

@test "import with valid auth.json succeeds" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  # Create a mock auth.json matching the expected format (has auth_mode + tokens)
  printf '{"auth_mode":"login","tokens":{"account_id":"acc123","id_token":"tok"}}\n' > "$HOME/mock-auth.json"
  run codex-rotate import testaccount "$HOME/mock-auth.json"
  assert_success
  assert_file_exists "$HOME/.codex-accounts/credentials/testaccount.json"
}

@test "import with nonexistent file fails" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  run codex-rotate import testaccount /nonexistent/file
  assert_failure
}

@test "import without alias shows error" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  run codex-rotate import
  assert_failure
}

@test "import with invalid alias fails" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  printf '{"auth_mode":"login","tokens":{}}\n' > "$HOME/mock-auth.json"
  run codex-rotate import "bad/alias" "$HOME/mock-auth.json"
  assert_failure
}

@test "import with invalid JSON content fails" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  printf '{"token":"test123"}\n' > "$HOME/mock-auth.json"
  run codex-rotate import testaccount "$HOME/mock-auth.json"
  assert_failure
}

# ---------------------------------------------------------------------------
# Error handling
# ---------------------------------------------------------------------------

@test "unknown command shows error and exits non-zero" {
  run codex-rotate nonexistent_cmd
  assert_failure
  assert_output_contains "Unknown command"
}

@test "list before init fails gracefully" {
  _install_fake_codex
  run codex-rotate list
  assert_failure
  assert_output_contains "Not initialized"
}

@test "add without alias fails" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  run codex-rotate add
  assert_failure
}

@test "status before init fails gracefully" {
  _install_fake_codex
  run codex-rotate status
  assert_failure
  assert_output_contains "Not initialized"
}

@test "switch without alias fails" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  run codex-rotate switch
  assert_failure
}

@test "switch to nonexistent alias fails" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  run codex-rotate switch nosuchalias
  assert_failure
  assert_output_contains "does not exist"
}

# ---------------------------------------------------------------------------
# Additional coverage: rotation core behaviors
# ---------------------------------------------------------------------------

_write_mock_auth() {
  local path="$1"
  local account_id="$2"
  printf '{"auth_mode":"login","tokens":{"account_id":"%s","id_token":"tok-%s"}}\n' "$account_id" "$account_id" > "$path"
}

_import_account() {
  local alias="$1"
  local account_id="$2"
  local auth_path="$HOME/${alias}-auth.json"
  _write_mock_auth "$auth_path" "$account_id"
  run codex-rotate import "$alias" "$auth_path"
  assert_success
}

@test "switch creates auth symlink to selected account credentials" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  _import_account account1 acc1
  _import_account account2 acc2

  run codex-rotate switch account1
  assert_success

  [[ -L "$HOME/.codex/auth.json" ]]
  [[ "$(readlink "$HOME/.codex/auth.json")" == "$HOME/.codex-accounts/credentials/account1.json" ]]
}

@test "switching accounts updates auth symlink target" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  _import_account alpha acca
  _import_account beta accb

  run codex-rotate switch alpha
  assert_success
  [[ "$(readlink "$HOME/.codex/auth.json")" == "$HOME/.codex-accounts/credentials/alpha.json" ]]

  run codex-rotate switch beta
  assert_success
  [[ "$(readlink "$HOME/.codex/auth.json")" == "$HOME/.codex-accounts/credentials/beta.json" ]]
}

@test "switch --force bypasses cooldown" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  _import_account one acc1

  run codex-rotate cooldown one --hours 2
  assert_success
  run codex-rotate switch one
  assert_failure
  assert_output_contains "on cooldown"

  run codex-rotate switch one --force
  assert_success
  [[ "$(<"$HOME/.codex-accounts/active")" == "one" ]]
}

@test "run exec rotates on 429 rate-limit signal" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  _import_account rl1 acc1
  _import_account rl2 acc2
  run codex-rotate switch rl1
  assert_success

  # shellcheck disable=SC2016
  printf '#!/usr/bin/env bash\nmarker="$HOME/fake-codex-first-hit"\nif [[ ! -f "$marker" ]]; then\n  : > "$marker"\n  echo "429 Too Many Requests" >&2\n  exit 1\nfi\necho "ok after rotate"\n' > "$HOME/bin/codex"
  chmod +x "$HOME/bin/codex"

  run codex-rotate run exec "test"
  assert_success
  assert_output_contains "ok after rotate"
  [[ "$(<"$HOME/.codex-accounts/active")" == "rl2" ]]
}

@test "run exec rotates on usageLimitExceeded signal" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  _import_account ul1 acc1
  _import_account ul2 acc2
  run codex-rotate switch ul1
  assert_success

  # shellcheck disable=SC2016
  printf '#!/usr/bin/env bash\nmarker="$HOME/fake-codex-first-hit"\nif [[ ! -f "$marker" ]]; then\n  : > "$marker"\n  echo "usageLimitExceeded" >&2\n  exit 1\nfi\necho "recovered"\n' > "$HOME/bin/codex"
  chmod +x "$HOME/bin/codex"

  run codex-rotate run exec "test"
  assert_success
  assert_output_contains "recovered"
  [[ "$(<"$HOME/.codex-accounts/active")" == "ul2" ]]
}

@test "run exec rotates on generic rate limit text" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  _import_account rt1 acc1
  _import_account rt2 acc2
  run codex-rotate switch rt1
  assert_success

  # shellcheck disable=SC2016
  printf '#!/usr/bin/env bash\nmarker="$HOME/fake-codex-first-hit"\nif [[ ! -f "$marker" ]]; then\n  : > "$marker"\n  echo "rate limit exceeded" >&2\n  exit 1\nfi\necho "retry success"\n' > "$HOME/bin/codex"
  chmod +x "$HOME/bin/codex"

  run codex-rotate run exec "test"
  assert_success
  assert_output_contains "retry success"
  [[ "$(<"$HOME/.codex-accounts/active")" == "rt2" ]]
}

@test "run exec does not rotate on non-rate-limit failure" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  _import_account nr1 acc1
  _import_account nr2 acc2
  run codex-rotate switch nr1
  assert_success

  # shellcheck disable=SC2016
  printf '#!/usr/bin/env bash\necho "fatal: unrelated error" >&2\nexit 1\n' > "$HOME/bin/codex"
  chmod +x "$HOME/bin/codex"

  run codex-rotate run exec "test"
  assert_failure
  assert_output_contains "unrelated error"
  [[ "$(<"$HOME/.codex-accounts/active")" == "nr1" ]]
}

@test "cooldown marks account as cooldown in list" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  _import_account cool1 acc1

  run codex-rotate cooldown cool1
  assert_success
  run codex-rotate list
  assert_success
  assert_output_contains "cool1"
  assert_output_contains "COOLDOWN"
}

@test "uncooldown clears cooldown and account becomes available" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  _import_account cool2 acc2

  run codex-rotate cooldown cool2 --hours 2
  assert_success
  run codex-rotate uncooldown cool2
  assert_success
  run codex-rotate list
  assert_success
  assert_output_contains "cool2"
  assert_output_contains "AVAILABLE"
}

@test "cooldown --hours writes expected duration in state" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  _import_account timed acc3

  run codex-rotate cooldown timed --hours 2
  assert_success

  run jq -r '.accounts.timed.cooldown_until' "$HOME/.codex-accounts/state.json"
  assert_success
  cooldown_until="$output"
  now_ts="$(date +%s)"
  remaining=$((cooldown_until - now_ts))
  (( remaining >= 7100 ))
  (( remaining <= 7200 ))
}

@test "switch to cooled-down account fails without force" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  _import_account blocked acc4

  run codex-rotate cooldown blocked --hours 1
  assert_success
  run codex-rotate switch blocked
  assert_failure
  assert_output_contains "on cooldown"
}

@test "import three accounts then switch shows first as active" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  _import_account a1 acc1
  _import_account a2 acc2
  _import_account a3 acc3

  run codex-rotate switch a1
  assert_success
  run codex-rotate list
  assert_success
  assert_output_contains "a1"
  assert_output_contains "ACTIVE"
}

@test "get_next_available picks only non-cooled account" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  _import_account g1 acc1
  _import_account g2 acc2
  _import_account g3 acc3
  run codex-rotate switch g1
  assert_success
  run codex-rotate cooldown g1 --hours 2
  assert_success
  run codex-rotate cooldown g2 --hours 2
  assert_success

  # shellcheck disable=SC2016
  printf '#!/usr/bin/env bash\necho "successful exec"\n' > "$HOME/bin/codex"
  chmod +x "$HOME/bin/codex"

  run codex-rotate run exec "test"
  assert_success
  assert_output_contains "successful exec"
  [[ "$(<"$HOME/.codex-accounts/active")" == "g3" ]]
}

@test "all accounts exhausted causes run failure" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  _import_account ex1 acc1
  _import_account ex2 acc2
  run codex-rotate switch ex1
  assert_success
  run codex-rotate cooldown ex1 --hours 2
  assert_success
  run codex-rotate cooldown ex2 --hours 2
  assert_success

  run codex-rotate run exec "test"
  assert_failure
  assert_output_contains "All accounts are on cooldown or unavailable"
}

@test "import switch verify end-to-end active file and symlink target" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  _import_account endtoend acc9

  run codex-rotate switch endtoend
  assert_success
  [[ "$(<"$HOME/.codex-accounts/active")" == "endtoend" ]]
  [[ -L "$HOME/.codex/auth.json" ]]
  [[ "$(readlink "$HOME/.codex/auth.json")" == "$HOME/.codex-accounts/credentials/endtoend.json" ]]
}

@test "import multiple accounts list shows each alias and status markers" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  _import_account m1 acc1
  _import_account m2 acc2
  _import_account m3 acc3
  run codex-rotate switch m2
  assert_success

  run codex-rotate list
  assert_success
  assert_output_contains "m1"
  assert_output_contains "m2"
  assert_output_contains "m3"
  assert_output_contains "ACTIVE"
  assert_output_contains "AVAILABLE"
}

@test "classify_cooldown heuristics apply daily cooldown duration" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  _import_account day1 acc1
  _import_account day2 acc2
  run codex-rotate switch day1
  assert_success

  # shellcheck disable=SC2016
  printf '#!/usr/bin/env bash\nmarker="$HOME/fake-codex-first-hit"\nif [[ ! -f "$marker" ]]; then\n  : > "$marker"\n  echo "daily limit exceeded, try tomorrow" >&2\n  exit 1\nfi\necho "done"\n' > "$HOME/bin/codex"
  chmod +x "$HOME/bin/codex"

  run codex-rotate run exec "test"
  assert_success
  assert_output_contains "done"

  run jq -r '.accounts.day1.cooldown_until' "$HOME/.codex-accounts/state.json"
  assert_success
  daily_until="$output"
  now_ts="$(date +%s)"
  remaining=$((daily_until - now_ts))
  (( remaining >= 85000 ))
  (( remaining <= 86400 ))
}

@test "classify_cooldown heuristics apply weekly cooldown duration" {
  _install_fake_codex
  run codex-rotate init
  assert_success
  _import_account week1 acc1
  _import_account week2 acc2
  run codex-rotate switch week1
  assert_success

  # shellcheck disable=SC2016
  printf '#!/usr/bin/env bash\nmarker="$HOME/fake-codex-first-hit"\nif [[ ! -f "$marker" ]]; then\n  : > "$marker"\n  echo "weekly rate limit reached" >&2\n  exit 1\nfi\necho "done"\n' > "$HOME/bin/codex"
  chmod +x "$HOME/bin/codex"

  run codex-rotate run exec "test"
  assert_success
  assert_output_contains "done"

  run jq -r '.accounts.week1.cooldown_until' "$HOME/.codex-accounts/state.json"
  assert_success
  weekly_until="$output"
  now_ts="$(date +%s)"
  remaining=$((weekly_until - now_ts))
  (( remaining >= 600000 ))
  (( remaining <= 604800 ))
}

# ===========================================================================
# v1.1.0 Feature Tests — JWT extraction, email, quota, refresh, enhanced list
# ===========================================================================

# ---------------------------------------------------------------------------
# Helper: create fake credentials with JWT tokens for testing
# ---------------------------------------------------------------------------

# A minimal JWT with email=test@example.com and chatgpt_plan_type=plus
# Header: {"alg":"none","typ":"JWT"}
# Payload: {"email":"test@example.com","https://api.openai.com/auth":{"chatgpt_plan_type":"plus","chatgpt_account_id":"acct_test123"}}
_FAKE_JWT_HEADER="eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0"
_FAKE_JWT_PAYLOAD="eyJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJodHRwczovL2FwaS5vcGVuYWkuY29tL2F1dGgiOnsiY2hhdGdwdF9wbGFuX3R5cGUiOiJwbHVzIiwiY2hhdGdwdF9hY2NvdW50X2lkIjoiYWNjdF90ZXN0MTIzIn19"
_FAKE_ID_TOKEN="${_FAKE_JWT_HEADER}.${_FAKE_JWT_PAYLOAD}.fakesig"

_setup_account_with_jwt() {
  local alias="${1:-testacct}"
  _install_fake_codex
  run codex-rotate init
  assert_success
  mkdir -p "$HOME/.codex-accounts/credentials"
  cat > "$HOME/.codex-accounts/credentials/${alias}.json" <<ENDJSON
{
  "auth_mode": "browser_login",
  "tokens": {
    "id_token": "${_FAKE_ID_TOKEN}",
    "access_token": "fake_access_token",
    "refresh_token": "fake_refresh_token",
    "account_id": "acct_test123"
  }
}
ENDJSON
  chmod 600 "$HOME/.codex-accounts/credentials/${alias}.json"
  echo "${alias}" >> "$HOME/.codex-accounts/order"
  echo "${alias}" > "$HOME/.codex-accounts/active"
  # Initialize state entry
  local state_file="$HOME/.codex-accounts/state.json"
  local tmp
  tmp=$(mktemp)
  jq --arg a "${alias}" '.accounts[$a] = {"total_uses":0,"last_used":"","cooldown_until":0,"rate_limit_hits":0,"last_rate_limit":""}' "${state_file}" > "${tmp}" && mv "${tmp}" "${state_file}"
}

# ---------------------------------------------------------------------------
# Email command tests
# ---------------------------------------------------------------------------

@test "email command shows email from JWT" {
  _setup_account_with_jwt "myacct"
  run codex-rotate email myacct
  assert_success
  assert_output_contains "test@example.com"
}

@test "email command shows plan type from JWT" {
  _setup_account_with_jwt "myacct"
  run codex-rotate email myacct
  assert_success
  assert_output_contains "plus"
}

@test "email command without alias shows all accounts" {
  _setup_account_with_jwt "acct1"
  _setup_account_with_jwt "acct2"
  run codex-rotate email
  assert_success
  assert_output_contains "acct1"
  assert_output_contains "acct2"
}

@test "email command fails for non-existent alias" {
  _install_fake_codex
  run codex-rotate init
  run codex-rotate email nonexistent
  assert_failure
}

# ---------------------------------------------------------------------------
# Quota command tests
# ---------------------------------------------------------------------------

@test "quota command runs without error for configured account" {
  _setup_account_with_jwt "myacct"
  # Will fail to reach API but should not crash
  run codex-rotate quota myacct
  assert_success
  assert_output_contains "myacct"
  assert_output_contains "test@example.com"
}

@test "quota command shows warning when API unreachable" {
  _setup_account_with_jwt "myacct"
  run codex-rotate quota myacct
  assert_success
  assert_output_contains "Could not fetch usage data"
}

@test "quota command fails for non-existent alias" {
  _install_fake_codex
  run codex-rotate init
  run codex-rotate quota nonexistent
  assert_failure
}

@test "quota without alias runs for all accounts" {
  _setup_account_with_jwt "a1"
  _setup_account_with_jwt "a2"
  run codex-rotate quota
  assert_success
  assert_output_contains "a1"
  assert_output_contains "a2"
}

# ---------------------------------------------------------------------------
# Refresh command tests
# ---------------------------------------------------------------------------

@test "refresh command runs without crash" {
  _setup_account_with_jwt "myacct"
  # Will fail to reach API but should not crash — exits non-zero on failure
  run codex-rotate refresh myacct
  assert_failure
  assert_output_contains "myacct"
}

@test "refresh command fails for non-existent alias" {
  _install_fake_codex
  run codex-rotate init
  run codex-rotate refresh nonexistent
  assert_failure
}

# ---------------------------------------------------------------------------
# Enhanced list tests (email column)
# ---------------------------------------------------------------------------

@test "list shows email column header" {
  _setup_account_with_jwt "myacct"
  run codex-rotate list
  assert_success
  assert_output_contains "EMAIL"
}

@test "list shows account email" {
  _setup_account_with_jwt "myacct"
  run codex-rotate list
  assert_success
  assert_output_contains "test@example.com"
}

@test "list shows plan type" {
  _setup_account_with_jwt "myacct"
  run codex-rotate list
  assert_success
  assert_output_contains "plus"
}

# ---------------------------------------------------------------------------
# Help text includes new commands
# ---------------------------------------------------------------------------

@test "help lists quota command" {
  run codex-rotate help
  assert_success
  assert_output_contains "quota"
}

@test "help lists email command" {
  run codex-rotate help
  assert_success
  assert_output_contains "email"
}

@test "help lists refresh command" {
  run codex-rotate help
  assert_success
  assert_output_contains "refresh"
}

# ---------------------------------------------------------------------------
# Mocked API success tests
# ---------------------------------------------------------------------------

# Helper: create a mock curl that returns a canned usage API response
_mock_curl_usage_success() {
  cat > "$HOME/bin/curl" <<'MOCKCURL'
#!/usr/bin/env bash
# Return a canned usage API response with 200 status
cat <<'RESPONSE'
{"plan_type":"plus","rate_limit":{"primary_window":{"used_percent":42,"limit_window_seconds":18000,"reset_at":9999999999},"secondary_window":{"used_percent":15,"limit_window_seconds":604800,"reset_at":9999999999}},"credits":{"has_credits":true,"unlimited":true,"balance":null}}
200
RESPONSE
MOCKCURL
  chmod +x "$HOME/bin/curl"
}

# Helper: create a mock curl that returns a canned token refresh response
_mock_curl_refresh_success() {
  cat > "$HOME/bin/curl" <<'MOCKCURL'
#!/usr/bin/env bash
# Return a canned refresh token response with 200 status
cat <<'RESPONSE'
{"id_token":"eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJlbWFpbCI6InJlZnJlc2hlZEBleGFtcGxlLmNvbSIsImh0dHBzOi8vYXBpLm9wZW5haS5jb20vYXV0aCI6eyJjaGF0Z3B0X3BsYW5fdHlwZSI6InBsdXMiLCJjaGF0Z3B0X2FjY291bnRfaWQiOiJhY2N0X3Rlc3QxMjMifX0.fakesig","access_token":"new_access_token","refresh_token":"new_refresh_token"}
200
RESPONSE
MOCKCURL
  chmod +x "$HOME/bin/curl"
}

@test "quota command with mocked API shows usage bars" {
  _setup_account_with_jwt "mockacct"
  _mock_curl_usage_success
  run codex-rotate quota mockacct
  assert_success
  assert_output_contains "mockacct"
  assert_output_contains "test@example.com"
  assert_output_contains "42%"
  assert_output_contains "15%"
  assert_output_contains "Unlimited"
}

@test "quota command with mocked API shows plan from API" {
  _setup_account_with_jwt "mockacct"
  _mock_curl_usage_success
  run codex-rotate quota mockacct
  assert_success
  assert_output_contains "Plan (API): plus"
}

@test "refresh command with mocked API succeeds" {
  _setup_account_with_jwt "mockacct"
  _mock_curl_refresh_success
  run codex-rotate refresh mockacct
  assert_success
  assert_output_contains "mockacct"
}

@test "refresh command with mocked API updates credential file" {
  _setup_account_with_jwt "mockacct"
  _mock_curl_refresh_success
  run codex-rotate refresh mockacct
  assert_success
  # Verify the credential file was updated with new tokens
  run jq -r '.tokens.access_token' "$HOME/.codex-accounts/credentials/mockacct.json"
  assert_success
  [[ "$output" == "new_access_token" ]]
}

@test "refresh failure returns non-zero exit code" {
  _setup_account_with_jwt "failacct"
  # Default curl will fail (no mock or real API)
  run codex-rotate refresh failacct
  assert_failure
  assert_output_contains "failacct"
}

# ---------------------------------------------------------------------------
# Quota-aware rotation tests
# ---------------------------------------------------------------------------

@test "help describes list with email and plan columns" {
  run codex-rotate help
  assert_success
  assert_output_contains "email"
  assert_output_contains "plan"
}

@test "quota command handles epoch reset_at values" {
  _setup_account_with_jwt "epochacct"
  # Mock curl to return epoch-based reset_at
  cat > "$HOME/bin/curl" <<'MOCKCURL'
#!/usr/bin/env bash
cat <<'RESPONSE'
{"plan_type":"plus","rate_limit":{"primary_window":{"used_percent":30,"limit_window_seconds":18000,"reset_at":9999999999},"secondary_window":{"used_percent":10,"limit_window_seconds":604800,"reset_at":9999999999}},"credits":{"has_credits":true,"unlimited":true,"balance":null}}
200
RESPONSE
MOCKCURL
  chmod +x "$HOME/bin/curl"
  run codex-rotate quota epochacct
  assert_success
  assert_output_contains "30%"
  assert_output_contains "resets in"
}

@test "help output reports version 1.1.2" {
  run codex-rotate help
  assert_success
  assert_output_contains "1.1.2"
}
