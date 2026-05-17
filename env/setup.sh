#!/usr/bin/env bash

# Homebrew setup
# -----------------------------
case "$(uname -ps)" in
  Linux*)
    MACHINE="linux"
    HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
    ;;
  Darwin\ arm*)
    MACHINE="apple"
    HOMEBREW_PREFIX="/opt/homebrew"
    ;;
  Darwin*)
    MACHINE="intel-mac"
    HOMEBREW_PREFIX="/usr/local"
    ;;
esac

num_cores() {
  local cores=""

  if [[ "${MACHINE}" == "linux" ]]; then
    cores="$(nproc 2>/dev/null)"
  elif command -v /usr/sbin/sysctl >/dev/null; then
    cores="$(/usr/sbin/sysctl -n hw.ncpu 2>/dev/null)"
  fi

  if [[ ! "${cores}" =~ ^[0-9]+$ ]] || [[ "${cores}" -lt 1 ]]; then
    cores=2
  fi

  echo "${cores}"
}

MACHINE_CORES="$(($(num_cores) - 1))"

if [[ "${MACHINE_CORES}" -lt 1 ]]; then
  MACHINE_CORES=1
fi

export MACHINE
export MACHINE_CORES
export HOMEBREW_PREFIX

if [ -z "${DOTFILES_DIR}" ]; then
  echo "ERROR: DOTFILES_DIR not set in $0"
  exit 1
fi

# XDG setup
# -----------------------------
source "${DOTFILES_DIR}/env/xdg.core.sh"
source "${DOTFILES_DIR}/env/xdg.apps.sh"

# Environment setup
# -----------------------------

if [[ "${MACHINE}" == "apple" ]] || [[ "${MACHINE}" == "intel-mac" ]]; then
  source "${DOTFILES_DIR}/env/build.sh"
  source "${DOTFILES_DIR}/env/cellar.sh"
elif [[ "${MACHINE}" == "linux" ]]; then
  export LDFLAGS="-L/home/linuxbrew/.linuxbrew/lib"
  export CPPFLAGS="-I/home/linuxbrew/.linuxbrew/include"
  export LD_LIBRARY_PATH="/home/linuxbrew/.linuxbrew/lib"
  export PKG_CONFIG_PATH="/home/linuxbrew/.linuxbrew/lib/pkgconfig"
fi

source "${DOTFILES_DIR}/env/bundler.sh"
source "${DOTFILES_DIR}/env/versions.sh"

# Homebrew
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

# GPG
GPG_TTY=$(tty)
export GPG_TTY

# FZF
if [[ -z "${XDG_DATA_HOME}" ]]; then
  echo "WARNING: XDG_DATA_HOME is not set in ${0}"
fi
export FZF_DIR="${XDG_DATA_HOME}/fzf"
export FZF_DEFAULT_OPTS="
  --no-multi
  --exact
  --tiebreak=index
  --color='bg:-1,bg+:-1,fg+:-1,gutter:0,preview-bg:-1,border:#1d1e20'
  --bind='ctrl-f:preview-down'
  --bind='ctrl-b:preview-up'
"
export FZF_DEFAULT_COMMAND="fd --hidden --type f --exclude .git --exclude node_modules"
export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"

# Erlang
export ERL_AFLAGS="-kernel shell_history enabled"
export KERL_BUILD_DOCS=no
export KERL_CONFIGURE_OPTIONS="--disable-debug --without-javac --disable-hipe"

# Emacs
if [[ -n "${INSIDE_EMACS}" ]]; then
  export EDITOR=emacs
  export COVERAGE=false
  unset PRINT_COVERAGE
fi
export ORG_HOME="${HOME}/Org"

# Rails
export RAILS_TEMPLATE="${XDG_CONFIG_HOME}/rails/template.rb"

# PATH setup
# -----------------------------
source "${DOTFILES_DIR}/env/path.sh"
