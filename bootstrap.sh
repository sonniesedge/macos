#!/usr/bin/env bash
#
# Bootstrap a fresh macOS machine to the point where the playbook can run.
# Installs the Xcode command line tools, Homebrew, Ansible, then hands over.
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || die "This script only supports macOS."

if [[ "$(uname -m)" == "arm64" ]]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/usr/local"
fi

# --- Xcode command line tools ----------------------------------------------
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing the Xcode command line tools."
  xcode-select --install
  echo "Complete the installer, then run this script again."
  exit 0
fi

# --- Homebrew ---------------------------------------------------------------
if [[ ! -x "${BREW_PREFIX}/bin/brew" ]]; then
  log "Installing Homebrew."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$("${BREW_PREFIX}/bin/brew" shellenv)"

# --- Ansible ----------------------------------------------------------------
if ! command -v ansible-playbook >/dev/null 2>&1; then
  log "Installing Ansible."
  brew install ansible
fi

# --- Collections ------------------------------------------------------------
log "Installing Ansible collections."
ansible-galaxy collection install -r "${REPO_DIR}/requirements.yaml"

# --- Run --------------------------------------------------------------------
log "Running the playbook."
cd "${REPO_DIR}"
ansible-playbook playbook.yaml "$@"

log "Done."
