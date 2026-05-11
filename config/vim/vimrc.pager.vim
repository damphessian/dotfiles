source $XDG_CONFIG_HOME/vim/vimrc.minimal.vim

set runtimepath+=$XDG_CONFIG_HOME/vim,$XDG_CONFIG_HOME/vim/after
set runtimepath+=$XDG_DATA_HOME/fzf
set runtimepath+=$VIM,$VIMRUNTIME

"--------------------------------------------------------------
" Colors
"--------------------------------------------------------------
" Base vim settings
set t_Co=256  " 256 color terminal

" Allow italic text in vim
set t_ZH=[3m
set t_ZR=[23m

if has('termguicolors')
  set termguicolors
endif

set background=dark
execute 'colorscheme spacemacs'

"comments in italics
hi Comment cterm=italic
" transparent background
hi Normal guibg=NONE ctermbg=NONE


"--------------------------------------------------------------
" Line numbering
"--------------------------------------------------------------
set numberwidth=1
set relativenumber
set number


"--------------------------------------------------------------
" Searching
"--------------------------------------------------------------
set incsearch     " do incremental searching
set hlsearch      " highlight search matches by default
set ignorecase    " case insensitive pattern matching
set smartcase     " overrides ignorecase if pattern contains upcased chars
let @/ = ''       " clear the search register
:nohlsearch       " clear any previously highlighted search matches

"--------------------------------------------------------------
" Pager settings
"--------------------------------------------------------------
set nowrap

" Rebind 'q' in normal mode to quit fast (like ZQ / less)
nnoremap q :q!  " intentional CR literal

" Rebind 'y' to copy to system clipboard
nnoremap y "+y
vnoremap y "+y
