# Vim Config

Vanilla Vim configuration with Vim-plug, focused editing plugins, fuzzy search,
Git helpers, and optional lint/fix tooling. The config is designed to work on a
fresh remote machine with a small dependency set, while becoming richer when
local tools are installed.

## Requirements

- Vim 9.1 or newer is recommended.
- Required CLI tools: `git`, `curl`, `ripgrep`, `fzf`.
- Recommended local tools:
  - Shell: `shellcheck`, `shfmt`
  - Python: `ruff`
  - Web/YAML/JSON: `node`, `eslint`, `prettier`, `jq`, `yamllint`
  - TOML: `taplo`
  - Navigation: `universal-ctags`

## Fresh Setup

On a remote Linux VM, run the setup script from this directory:

```sh
bin/setup
```

For optional language linters and formatters, use:

```sh
bin/setup --with-language-tools
```

The script supports Debian/Ubuntu via `apt-get` and Red Hat/Amazon/Fedora style
hosts via `yum` or `dnf`. It installs required CLI dependencies, creates the
XDG Vim directories, links this checkout to `$XDG_CONFIG_HOME/vim`, installs
Vim-plug if needed, and runs `PlugInstall`.

Manual setup is:

```sh
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}" \
  "${XDG_DATA_HOME:-$HOME/.local/share}" \
  "${XDG_CACHE_HOME:-$HOME/.cache}"/vim/{backup,swap,undo}

ln -s "$HOME/.dotfiles/config/vim" "${XDG_CONFIG_HOME:-$HOME/.config}/vim"
export VIMINIT="source ${XDG_CONFIG_HOME:-$HOME/.config}/vim/vimrc"

vim +PlugInstall +qall
```

If this repo's `autoload/plug.vim` symlink is missing, install Vim-plug with:

```sh
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/vim/autoload"
curl -fLo "${XDG_CONFIG_HOME:-$HOME/.config}/vim/autoload/plug.vim" \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

## Useful Commands

- `<leader>ff`: fuzzy-find files
- `<leader>bb`: fuzzy-find buffers
- `<leader>fg`: ripgrep with fzf
- `<leader>sp`: run ripgrep into quickfix
- `[q` / `]q`: quickfix previous/next
- `<leader>af`: run ALE fixers
- `[a` / `]a`: ALE diagnostic previous/next
- `gc`: toggle comments with Vim's runtime comment package
- `<leader>gs`: Git status
- `<leader>gm`: Magit-style staging and commit buffer
- `<leader>hp` / `<leader>hs` / `<leader>hu`: preview, stage, or undo the current GitGutter hunk

## Notes

Language tools are optional. ALE is configured explicitly, so missing tools
should not block editing; install the relevant tool when you want diagnostics
or formatting for that language.
