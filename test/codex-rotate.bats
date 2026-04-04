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
