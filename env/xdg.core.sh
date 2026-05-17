#!/usr/bin/env bash

# - copied to /etc/zshenv or /etc/zsh/zshenv in bootstrap
# - also set in LaunchAgent for mac GUI access (see set-xdg-env-vars.sh)

export DOTFILES_DIR="${HOME}/.dotfiles"
export SHELL_CONFIG_DIR="${DOTFILES_DIR}/shell"
export XDG_CACHE_HOME="${DOTFILES_DIR}/cache"        # ephemeral data files
export XDG_CONFIG_DIRS="/etc/xdg"                    # base directories to search for configuration files in addition to the $XDG_CONFIG_HOME base directory.
export XDG_CONFIG_HOME="${DOTFILES_DIR}/config"      # user config home
export XDG_DATA_HOME="${DOTFILES_DIR}/share"         # data files (submodules)
export XDG_LOCALS_DIR="${DOTFILES_DIR}/locals"       # un-synced, un-tracked dotfiles (not spec)
export XDG_RUNTIME_DIR="${DOTFILES_DIR}/sockets"     # ephemeral runtime files (sockets, named pipes, etc)
export XDG_SECURE_DIR="${DOTFILES_DIR}/secure"       # synced, tracked sensitive dotfiles (not spec)
export XDG_STATE_HOME="${DOTFILES_DIR}/state"        # state files (logs, history, recently used files, current app state, etc)
export ZDOTDIR="${XDG_CONFIG_HOME}/zsh"

# Other GUI-related xdg env vars
export CUPS_CACHEDIR="${XDG_CACHE_HOME}/cups"
export CUPS_DATADIR="${XDG_DATA_HOME}/cups"

XDG_DATA_DIRS="/usr/local/share:/usr/share/"

if [[ "${MACHINE}" == "linux" ]]; then
  XDG_DATA_DIRS+=":/var/lib/flatpak/exports/share"
  XDG_DATA_DIRS+=":${XDG_DATA_HOME}/flatpak/exports/share"
fi

export XDG_DATA_DIRS
