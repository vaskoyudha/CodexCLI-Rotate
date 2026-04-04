#!/usr/bin/env bash

setup() {
  export HOME="$BATS_TEST_TMPDIR/fakehome"
  mkdir -p "$HOME/.codex"
  export CODEX_ROTATE_NONINTERACTIVE=1
  export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
}

teardown() {
  rm -rf "$BATS_TEST_TMPDIR/fakehome"
}

# shellcheck disable=SC2154
assert_success() {
  if [[ "$status" -ne 0 ]]; then
    echo "expected success (status 0), got status $status"
    echo "output: $output"
    return 1
  fi
}

assert_failure() {
  if [[ "$status" -eq 0 ]]; then
    echo "expected failure (non-zero status), got status 0"
    echo "output: $output"
    return 1
  fi
}

assert_output_contains() {
  if [[ "$output" != *"$1"* ]]; then
    echo "expected output to contain: $1"
    echo "actual output: $output"
    return 1
  fi
}

assert_file_exists() {
  if [[ ! -f "$1" ]]; then
    echo "expected file to exist: $1"
    return 1
  fi
}
