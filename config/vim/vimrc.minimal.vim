set nocompatible
filetype plugin indent on
scriptencoding utf-8
set fileencodings=utf-8
set encoding=utf-8

set scrolloff=3         " keep 3 lines when scrolling
set autoindent          " set auto-indenting on for programming

set showcmd             " display incomplete commands
set nobackup            " do not keep a backup file
set number              " show line numbers
set ruler               " show the current row and column

set hlsearch            " highlight searches
set incsearch           " do incremental searching
set showmatch           " jump to matches when entering regexp
set ignorecase          " ignore case when searching
set smartcase           " no ignorecase if Uppercase char present

set visualbell t_vb=    " turn off error beep/flash
set novisualbell        " turn off visual bell

setlocal noswapfile       " don't keep a swapfile
setlocal bufhidden=unload " unload buffers once they're not visible
setlocal undolevels=1     " only one undo allowed

set backspace=indent,eol,start  " make that backspace key work the way it should
set runtimepath=$VIMRUNTIME     " turn off user scripts, https://github.com/igrigorik/vimgolf/issues/129

source $XDG_CONFIG_HOME/vim/xdg.vim

" " disable event bindings used by augroups for syntax highlighting, etc.
" set eventignore+=FileType
" set eventignore+=VimEnter
" set eventignore+=Syntax

" tl: toggle line wrapping
function! ToggleLineWrap()
  if &wrap
    setlocal nowrap
  else
    setlocal wrap
  endif
endfunction

nnoremap <silent><leader>tw :call ToggleLineWrap()<cr>
