#!/usr/bin/env bash
set -euo pipefail

# codex-rotate installer
# Supports both local (git clone) and remote (curl | bash) installation.

REPO_URL="https://raw.githubusercontent.com/vaskoyudha/CodexCLI-Rotate/main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${HOME}/.local/bin"
TARGET_SCRIPT="${INSTALL_DIR}/codex-rotate"

# Determine source: local clone or remote download
if [[ -f "${SCRIPT_DIR}/bin/codex-rotate" ]]; then
  SOURCE_MODE="local"
  SOURCE_SCRIPT="${SCRIPT_DIR}/bin/codex-rotate"
elif [[ -f "${SCRIPT_DIR}/codex-rotate" ]]; then
  # Backward compat: old layout with codex-rotate in root
  SOURCE_MODE="local"
  SOURCE_SCRIPT="${SCRIPT_DIR}/codex-rotate"
else
  SOURCE_MODE="remote"
  SOURCE_SCRIPT=""
fi

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

log_info() {
  printf "%b[INFO]%b %s\n" "${BLUE}" "${RESET}" "$*"
}

log_warn() {
  printf "%b[WARN]%b %s\n" "${YELLOW}" "${RESET}" "$*"
}

log_error() {
  printf "%b[ERROR]%b %s\n" "${RED}" "${RESET}" "$*" >&2
}

log_success() {
  printf "%b[OK]%b %s\n" "${GREEN}" "${RESET}" "$*"
}

die() {
  log_error "$*"
  exit 1
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

check_bash_version() {
  local major
  major="${BASH_VERSINFO[0]:-0}"
  if (( major < 4 )); then
    die "Bash >= 4 is required. Current: ${BASH_VERSION}"
  fi
  log_success "Bash version OK: ${BASH_VERSION}"
}

install_jq_if_missing() {
  if have_cmd jq; then
    log_success "jq already installed: $(jq --version)"
    return 0
  fi

  log_warn "jq is missing. Attempting installation..."

  local installer=""
  if have_cmd brew; then
    installer="brew"
  elif have_cmd apt-get; then
    installer="apt-get"
  elif have_cmd dnf; then
    installer="dnf"
  else
    die "Could not find brew, apt-get, or dnf to install jq. Install jq manually and re-run."
  fi

  local prefix=()
  if [[ "${installer}" != "brew" ]] && (( EUID != 0 )); then
    if have_cmd sudo; then
      prefix=(sudo)
    else
      die "Need root privileges to install jq (sudo not found). Install jq manually."
    fi
  fi

  if [[ "${installer}" == "brew" ]]; then
    brew install jq
  elif [[ "${installer}" == "apt-get" ]]; then
    "${prefix[@]}" apt-get update
    "${prefix[@]}" apt-get install -y jq
  else
    "${prefix[@]}" dnf install -y jq
  fi

  have_cmd jq || die "jq installation failed"
  log_success "Installed jq: $(jq --version)"
}

check_flock() {
  if have_cmd flock; then
    log_success "flock available"
    return 0
  fi
  if [[ "$(uname -s)" == "Darwin" ]]; then
    die "flock not found. On macOS, install via: brew install util-linux"
  fi
  die "flock not found (expected from util-linux). Install util-linux and re-run."
}

install_script() {
  mkdir -p "${INSTALL_DIR}"

  if [[ "${SOURCE_MODE}" == "local" ]]; then
    [[ -f "${SOURCE_SCRIPT}" ]] || die "Source script not found: ${SOURCE_SCRIPT}"
    cp -f "${SOURCE_SCRIPT}" "${TARGET_SCRIPT}"
  else
    log_info "Downloading codex-rotate from ${REPO_URL}/bin/codex-rotate ..."
    if have_cmd curl; then
      curl -fsSL "${REPO_URL}/bin/codex-rotate" -o "${TARGET_SCRIPT}" \
        || die "Download failed (curl)"
    elif have_cmd wget; then
      wget -qO "${TARGET_SCRIPT}" "${REPO_URL}/bin/codex-rotate" \
        || die "Download failed (wget)"
    else
      die "Neither curl nor wget found. Install one and re-run."
    fi
  fi

  chmod +x "${TARGET_SCRIPT}"
  log_success "Installed codex-rotate to ${TARGET_SCRIPT}"
}

run_init() {
  "${TARGET_SCRIPT}" init
  log_success "Initialization complete"
}

offer_import_default() {
  local auth_path="${HOME}/.codex/auth.json"

  if [[ ! -f "${auth_path}" ]]; then
    log_info "No ${auth_path} found; skipping default import prompt."
    return 0
  fi

  if [[ -L "${auth_path}" ]]; then
    log_info "${auth_path} is already a symlink; skipping default import prompt."
    return 0
  fi

  # Skip interactive prompt in non-interactive mode (CI, curl|bash without tty)
  if [[ -n "${CODEX_ROTATE_NONINTERACTIVE:-}" ]] || [[ ! -t 0 ]]; then
    log_info "Non-interactive mode: skipping default account import."
    return 0
  fi

  local answer
  printf "Found existing ~/.codex/auth.json (not a symlink). Import it as alias 'default'? [y/N]: "
  read -r answer || true

  case "${answer}" in
    y|Y|yes|YES)
      "${TARGET_SCRIPT}" import default "${auth_path}"
      "${TARGET_SCRIPT}" switch default --force
      log_success "Imported and switched to 'default' account"
      ;;
    *)
      log_info "Skipped default account import"
      ;;
  esac
}

path_hint() {
  case ":${PATH}:" in
    *":${HOME}/.local/bin:"*)
      log_success "${HOME}/.local/bin is already in PATH"
      return 0
      ;;
  esac

  log_warn "${HOME}/.local/bin is not in PATH"

  # Detect current shell and suggest the correct profile file
  local shell_name profile_file
  shell_name="$(basename "${SHELL:-bash}")"

  case "${shell_name}" in
    zsh)
      if [[ -f "${HOME}/.zshrc" ]]; then
        profile_file=".zshrc"
      else
        profile_file=".zprofile"
      fi
      ;;
    fish)
      profile_file=".config/fish/config.fish"
      ;;
    *)
      # bash and anything else
      if [[ -f "${HOME}/.bashrc" ]]; then
        profile_file=".bashrc"
      elif [[ -f "${HOME}/.bash_profile" ]]; then
        profile_file=".bash_profile"
      else
        profile_file=".profile"
      fi
      ;;
  esac

  printf "\nAdd this to ~/%s:\n" "${profile_file}"
  if [[ "${shell_name}" == "fish" ]]; then
    printf "  fish_add_path %s/.local/bin\n\n" "\$HOME"
  else
    printf "  export PATH=\"\$HOME/.local/bin:\$PATH\"\n\n"
  fi

  printf "Then reload your shell:\n"
  printf "  source ~/%s\n\n" "${profile_file}"
}

print_summary() {
  printf "\n"
  log_success "codex-rotate installation complete"
  printf "\nTry these commands:\n"
  printf "  codex-rotate help\n"
  printf "  codex-rotate list\n"
  printf "  codex-rotate add personal\n"
  printf "  codex-rotate switch personal\n"
  printf "  codex-rotate run exec \"hello\"\n"
}

main() {
  check_bash_version
  install_jq_if_missing
  check_flock
  install_script
  run_init
  offer_import_default
  path_hint
  print_summary
}

main "$@"
