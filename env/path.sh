[[ -z "${DOTFILES_DIR}" ]]    && echo "WARNING: DOTFILES_DIR is not set in ${0}"
[[ -z "${XDG_DATA_HOME}" ]]   && echo "WARNING: XDG_DATA_HOME is not set in ${0}"
[[ -z "${HOMEBREW_PREFIX}" ]] && echo "WARNING: HOMEBREW_PREFIX is not set in ${0}"

PATH="${XDG_LOCALS_DIR}/bin"
PATH+=":${DOTFILES_DIR}/bin"
PATH+=":${XDG_SECURE_DIR}/bin"
PATH+=":${DOTFILES_DIR}/scripts/git"

PATH+=":${XDG_DATA_HOME}/mise/shims"
PATH+=":${XDG_DATA_HOME}/fzf/bin"
PATH+=":${XDG_DATA_HOME}/doomemacs/bin"
PATH+=":${XDG_DATA_HOME}/npm/bin"

PATH+=":${HOMEBREW_PREFIX}/opt/bison/bin"
PATH+=":${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin"
PATH+=":${HOMEBREW_PREFIX}/opt/curl/bin"
PATH+=":${HOMEBREW_PREFIX}/opt/findutils/libexec/gnubin"
PATH+=":${HOMEBREW_PREFIX}/opt/gettext/bin"
PATH+=":${HOMEBREW_PREFIX}/opt/gnu-bin/libexec/gnubin"
PATH+=":${HOMEBREW_PREFIX}/opt/gnu-indent/libexec/gnubin"
PATH+=":${HOMEBREW_PREFIX}/opt/gnu-sed/libexec/gnubin"
PATH+=":${HOMEBREW_PREFIX}/opt/gnu-tar/libexec/gnubin"
PATH+=":${HOMEBREW_PREFIX}/opt/gnu-which/libexec/gnubin"
PATH+=":${HOMEBREW_PREFIX}/opt/gnutls/libexec/gnubin"
PATH+=":${HOMEBREW_PREFIX}/opt/grep/libexec/gnubin"
PATH+=":${HOMEBREW_PREFIX}/opt/make/libexec/gnubin"
PATH+=":${HOMEBREW_PREFIX}/opt/rg/bin"
PATH+=":${HOMEBREW_PREFIX}/opt/trash/bin"
PATH+=":${HOMEBREW_PREFIX}/share/git-core/contrib/diff-highlight"

# -------------------
PATH+=":${HOMEBREW_PREFIX}/bin"
PATH+=":${HOMEBREW_PREFIX}/sbin"

PATH+=":${HOME}/.local/bin"
PATH+=":${LMSTUDIO_HOME}/bin"
PATH+=":/usr/local/sbin"
PATH+=":/usr/local/bin"
PATH+=":/usr/sbin"
PATH+=":/usr/bin"
PATH+=":/sbin"
PATH+=":/bin"
PATH+=":/usr/local/texlive/current/bin/universal-darwin"

# PATH+=":/usr/local/texlive/current/bin/x86_64-linux"
# PATH+=":/usr/local/cuda/bin"
# PATH+=":/snap/bin"

export PATH

if [[ -d "${HOMEBREW_PREFIX}/opt" ]]; then
  for mandir in ${HOMEBREW_PREFIX}/opt/*/libexec/gnuman; do
    export MANPATH="$mandir:$MANPATH"
  done
fi

# TEMP: Let's see what breaks
# PATH+=":./node_modules/.bin"
# PATH+=":${HOMEBREW_PREFIX}/opt/${OPENSSL:-openssl@1.1}/bin"
# PATH+=":${HOMEBREW_PREFIX}/opt/libpq/bin"
# PATH+=":${HOME}/.docker/bin"
#
# Prefer BSD uname, becuase it reports m1 arch as 'arm'
# GNU uname reports it as 'arm64', which breaks some build scripts
# if [[ -d "${HOMEBREW_PREFIX}/bin" ]]; then
#   ln -sf /usr/bin/uname "${HOMEBREW_PREFIX}/bin/uname"
# fi

# eval "$(brew shellenv)"
