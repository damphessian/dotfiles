" ---------------- Plugin Manifest ----------------
" Keep this list small enough for a fresh remote machine and useful enough for
" daily editing. Vim runtime packages cover comment, editorconfig, matchit,
" netrw, and osc52 when the installed Vim is modern enough.

" Search / fuzzy selection
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Editing ergonomics
Plug 'airblade/vim-gitgutter'
Plug 'christoomey/vim-sort-motion'
Plug 'dense-analysis/ale'
Plug 'itchyny/lightline.vim'
Plug 'jreybert/vimagit'
Plug 'junegunn/vim-easy-align'
Plug 'mhinz/vim-hugefile'
Plug 'pbrisbin/vim-mkdir'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-git'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-rsi'
Plug 'tpope/vim-sleuth'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-vinegar'

" Text objects
Plug 'kana/vim-textobj-user'
Plug 'kana/vim-textobj-entire'
Plug 'kana/vim-textobj-indent'
Plug 'kana/vim-textobj-line'

" Data navigation
Plug 'mogelbrod/vim-jsonpath', { 'for': 'json' }
