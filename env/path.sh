[[ -z "${DOTFILES_DIR}" ]]    && echo "WARNING: DOTFILES_DIR is not set in ${0}"
[[ -z "${XDG_DATA_HOME}" ]]   && echo "WARNING: XDG_DATA_HOME is not set in ${0}"
[[ -z "${HOMEBREW_PREFIX}" ]] && echo "WARNING: HOMEBREW_PREFIX is not set in ${0}"

if [ -n "$ZSH_VERSION" ]; then
  setopt NULL_GLOB
fi

PATH="${XDG_LOCALS_DIR}/bin"
PATH+=":${DOTFILES_DIR}/bin"
PATH+=":${XDG_SECURE_DIR}/bin"
PATH+=":${DOTFILES_DIR}/scripts/git"

PATH+=":${XDG_DATA_HOME}/mise/shims"
PATH+=":${XDG_DATA_HOME}/fzf/bin"
PATH+=":${XDG_DATA_HOME}/doomemacs/bin"
PATH+=":${PNPM_HOME}"
PATH+=":${XDG_DATA_HOME}/npm/bin"

PATH+=":${HOMEBREW_PREFIX}/opt/bison/bin"
PATH+=":${HOMEBREW_PREFIX}/opt/curl/bin"
PATH+=":${HOMEBREW_PREFIX}/opt/gettext/bin"
PATH+=":${HOMEBREW_PREFIX}/opt/rg/bin"
PATH+=":${HOMEBREW_PREFIX}/opt/trash/bin"
PATH+=":${HOMEBREW_PREFIX}/share/git-core/contrib/diff-highlight"

for gnubin in "${HOMEBREW_PREFIX}"/opt/*/libexec/gnubin; do
  [ -d "$gnubin" ] || continue
  PATH+=":${gnubin}"
done

PATH+=":${HOMEBREW_PREFIX}/bin"
PATH+=":${HOMEBREW_PREFIX}/sbin"

PATH+=":${HOME}/.local/bin"
PATH+=":/usr/local/sbin"
PATH+=":/usr/local/bin"
PATH+=":/usr/sbin"
PATH+=":/usr/bin"
PATH+=":/sbin"
PATH+=":/bin"
PATH+=":/Library/TeX/texbin"

export PATH

for gnuman in "${HOMEBREW_PREFIX}"/opt/*/libexec/gnuman; do
  [ -d "$gnuman" ] || continue
  MANPATH+=":${gnuman}"
done

if [ -n "$ZSH_VERSION" ]; then
  unsetopt NULL_GLOB
fi
