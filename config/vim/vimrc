set nocompatible
scriptencoding utf-8

" ---------------- Bootstrap / XDG ----------------
syntax on
filetype plugin indent on
set encoding=utf-8
set fileencodings=utf-8

set runtimepath+=$XDG_CONFIG_HOME/vim,$XDG_CONFIG_HOME/vim/after
set runtimepath+=$XDG_DATA_HOME/fzf
set runtimepath+=$VIM,$VIMRUNTIME

runtime xdg.vim

function! s:EnsureDir(path) abort
  if !isdirectory(expand(a:path))
    call mkdir(expand(a:path), 'p')
  endif
endfunction

call s:EnsureDir('$XDG_CACHE_HOME/vim')
call s:EnsureDir('$XDG_CACHE_HOME/vim/backup')
call s:EnsureDir('$XDG_CACHE_HOME/vim/swap')
call s:EnsureDir('$XDG_CACHE_HOME/vim/undo')
call s:EnsureDir('$XDG_DATA_HOME/vim/plugged')

if has('persistent_undo')
  set undofile
endif

" Use useful packages that ship with modern Vim when available.
silent! packadd matchit
silent! packadd comment
silent! packadd editorconfig
silent! packadd osc52

" Vim's bundled EditorConfig package handles real files well, but its BufNew
" hook can misfire on scratch buffers opened by commands such as :PlugStatus.
silent! autocmd! editorconfig BufNew

if exists('+clipmethod')
  let g:osc52_disable_paste = v:true
  if index(split(&clipmethod, ','), 'osc52') < 0
    set clipmethod+=osc52
  endif
endif

" ---------------- Plugins ----------------
if filereadable(expand('$XDG_CONFIG_HOME/vim/autoload/plug.vim'))
  call plug#begin(expand('$XDG_DATA_HOME/vim/plugged'))
  source $XDG_CONFIG_HOME/vim/plugins.vim
  call plug#end()
else
  echohl WarningMsg
  echom 'vim-plug is missing: expected $XDG_CONFIG_HOME/vim/autoload/plug.vim'
  echohl None
endif

" ---------------- Core Editing ----------------
let mapleader = ' '
let maplocalleader = ','

set backspace=indent,eol,start
set hidden
set history=200
set autowrite
set confirm
set lazyredraw
set ttyfast
set updatetime=300
set timeoutlen=500
set ttimeoutlen=10
set shortmess+=aIc
set showcmd
set noshowmode
set ruler
set laststatus=2
set cmdheight=1
set previewheight=15

set splitbelow
set splitright
set winwidth=84
set winheight=5
set winminheight=5
set winheight=999

set scrolloff=8
set sidescrolloff=8
set linebreak
set diffopt+=vertical
set colorcolumn=+0

set expandtab
set shiftwidth=2
set softtabstop=2
set tabstop=2
set shiftround
set autoindent
set smartindent

set backup
set writebackup
set backupskip=/tmp/*,/private/tmp/*
set directory=$XDG_CACHE_HOME/vim/swap//
set backupdir=$XDG_CACHE_HOME/vim/backup//
set undodir=$XDG_CACHE_HOME/vim/undo//

set foldmethod=indent
set foldlevelstart=99
set foldenable

set list
set listchars=tab:>-,trail:.,extends:>,precedes:<,nbsp:+

set wildmenu
set wildmode=list:longest,list:full
set wildignorecase
set wildignore+=*.o,*.obj,*.pyc,*.class,*.swp
set wildignore+=*/.git/*,*/node_modules/*,*/.venv/*,*/venv/*,*/__pycache__/*

set completeopt=menuone,noselect,preview
set pumheight=12

" ---------------- Search / Quickfix ----------------
set incsearch
set hlsearch
set ignorecase
set smartcase
set grepprg=rg\ --vimgrep\ --smart-case
set grepformat=%f:%l:%c:%m
let @/ = ''
silent! nohlsearch

command! -nargs=+ -complete=file -bar Grep silent! grep! <args> | cwindow | redraw!
command! Todo Grep TODO FIXME XXX HACK NOTE

" ---------------- UI ----------------
set t_Co=256
if has('termguicolors')
  set termguicolors
endif

set background=dark
silent! colorscheme spacemacs

set number
set relativenumber
set numberwidth=1
set signcolumn=yes

if has('gui_running')
  set visualbell
  set guioptions-=T
  set guioptions+=c
  set transparency=1
  set lines=50 columns=80
  set guifont=JuliaMono:h16
endif

" ---------------- Autocommands ----------------
augroup vimrc_core
  autocmd!
  autocmd BufReadPost *
        \ if &filetype !=# 'gitcommit' && line("'\"") > 0 && line("'\"") <= line('$') |
        \   execute 'normal! g`"' |
        \ endif
  autocmd VimResized * wincmd =
  autocmd FileType qf setlocal nobuflisted nowrap
  autocmd FileType help,qf,man nnoremap <buffer> q :quit<CR>
augroup END

" ---------------- Mappings ----------------
nnoremap <silent> <CR> :nohlsearch<CR><CR>
nnoremap <Left>  <C-w><
nnoremap <Right> <C-w>>
nnoremap <Down>  <C-w>+
nnoremap <Up>    <C-w>-
nnoremap <C-e> 5<C-e>
nnoremap <C-y> 5<C-y>
nnoremap <S-h> gT
nnoremap <S-l> gt

nnoremap <leader>- :wincmd _<CR>:wincmd \|<CR>
nnoremap <leader>= :wincmd =<CR>
nnoremap <leader>tw :setlocal wrap! wrap?<CR>

nnoremap <leader>wv <C-w>v
nnoremap <leader>ws <C-w>s
nnoremap <leader>wh <C-w>h
nnoremap <leader>wj <C-w>j
nnoremap <leader>wk <C-w>k
nnoremap <leader>wl <C-w>l
nnoremap <leader>wd :quit<CR>
nnoremap <leader>wD :quit!<CR>

nnoremap <leader>bd :bdelete<CR>
nnoremap <leader>bD :bdelete!<CR>
nnoremap <C-c><C-c> :x<CR>
nnoremap <C-c><C-k> :q!<CR>

nnoremap <leader>sp :Grep ''<Left>
nnoremap <silent> <S-k> yiw:grep! <C-r>0<CR>:cwindow<CR>
vnoremap <silent> <S-k> y:grep! <C-r>0<CR>:cwindow<CR>
nnoremap <leader>* yiw:grep! <C-r>0<CR>:cwindow<CR>
vnoremap <leader>R y:%s/<C-r>"//g<Left><Left>
nnoremap <leader>R :redraw!<CR>

function! s:WriteWithOptionalFix() abort
  if exists(':ALEFix') == 2
    silent! ALEFix
  endif
  write
endfunction

nnoremap <silent> <leader>fs :call <SID>WriteWithOptionalFix()<CR>
nnoremap <silent> <leader>qq :cclose<CR>
nnoremap <silent> <leader>qo :copen<CR>
nnoremap <silent> <leader>qn :cnext<CR>
nnoremap <silent> <leader>qp :cprevious<CR>
nnoremap <silent> [q :cprevious<CR>
nnoremap <silent> ]q :cnext<CR>

vnoremap <C-c>y "+y
vnoremap <C-c>d "+d
nnoremap <C-c>p :set paste<CR>i<Esc>"+p:set nopaste<CR>

nnoremap <leader><C-]> :vsplit<CR>:execute 'tag ' . expand('<cword>')<CR>
nnoremap <leader>] :split<CR>:execute 'tag ' . expand('<cword>')<CR>

" ---------------- fzf ----------------
function! s:FzfFiles() abort
  if exists(':Files') == 2
    Files
  else
    call feedkeys(':find ', 'n')
  endif
endfunction

function! s:FzfBuffers() abort
  if exists(':Buffers') == 2
    Buffers
  else
    buffers
    call feedkeys(':buffer ', 'n')
  endif
endfunction

function! s:FzfGrep() abort
  if exists(':Rg') == 2
    Rg
  else
    call feedkeys(':Grep ', 'n')
  endif
endfunction

function! s:FzfHistory() abort
  if exists(':History') == 2
    History
  else
    history
  endif
endfunction

nnoremap <silent> <leader>ff :call <SID>FzfFiles()<CR>
nnoremap <silent> <leader>pf :call <SID>FzfFiles()<CR>
nnoremap <silent> <leader>bb :call <SID>FzfBuffers()<CR>
nnoremap <silent> <leader>fg :call <SID>FzfGrep()<CR>
nnoremap <silent> <leader>fh :call <SID>FzfHistory()<CR>

let g:fzf_layout = { 'down': '40%' }
let g:fzf_colors =
      \ { 'fg':      ['fg', 'Normal'],
      \   'bg':      ['bg', 'Normal'],
      \   'hl':      ['fg', 'Comment'],
      \   'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
      \   'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
      \   'hl+':     ['fg', 'Statement'],
      \   'info':    ['fg', 'PreProc'],
      \   'border':  ['fg', 'Ignore'],
      \   'prompt':  ['fg', 'Conditional'],
      \   'pointer': ['fg', 'Exception'],
      \   'marker':  ['fg', 'Keyword'],
      \   'spinner': ['fg', 'Label'],
      \   'header':  ['fg', 'Comment'] }

" ---------------- netrw ----------------
let g:netrw_liststyle = 4
let g:netrw_preview = 1
let g:netrw_winsize = 70
let g:netrw_banner = 0
let g:netrw_altv = 1

" ---------------- ALE ----------------
let g:ale_disable_lsp = 1
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 1
let g:ale_lint_on_save = 1
let g:ale_lint_delay = 500
let g:ale_virtualtext_cursor = 1
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_sign_error = '>>'
let g:ale_sign_warning = '--'
let g:ale_linters_explicit = 1
let g:ale_linters = {
      \ 'html': ['tidy'],
      \ 'javascript': ['eslint'],
      \ 'json': ['jq'],
      \ 'python': ['ruff'],
      \ 'sh': ['shellcheck'],
      \ 'toml': ['taplo'],
      \ 'yaml': ['yamllint'],
      \ }
let g:ale_fixers = {
      \ '*': ['remove_trailing_lines', 'trim_whitespace'],
      \ 'html': ['prettier'],
      \ 'javascript': ['prettier', 'eslint'],
      \ 'json': ['jq', 'prettier'],
      \ 'python': ['ruff_format', 'ruff'],
      \ 'sh': ['shfmt'],
      \ 'toml': ['taplo'],
      \ 'yaml': ['prettier'],
      \ }

nnoremap <silent> <leader>aa :ALEToggle<CR>
nnoremap <silent> <leader>ad :ALEDetail<CR>
nnoremap <silent> <leader>af :ALEFix<CR>
nnoremap <silent> <leader>an :ALENext<CR>
nnoremap <silent> <leader>ap :ALEPrevious<CR>
nnoremap <silent> [a :ALEPrevious<CR>
nnoremap <silent> ]a :ALENext<CR>

" ---------------- Git ----------------
nnoremap <leader>g :Git<Space>
nnoremap <silent> <leader>gm :Magit<CR>
nnoremap <silent> <leader>gM :MagitOnly<CR>
nnoremap <silent> <leader>gs :Git<CR>
nnoremap <silent> <leader>gb :Git blame<CR>
nnoremap <silent> <leader>gd :Gdiffsplit<CR>

nmap <leader>hp <Plug>(GitGutterPreviewHunk)
nmap <leader>hs <Plug>(GitGutterStageHunk)
nmap <leader>hu <Plug>(GitGutterUndoHunk)
nmap ]h <Plug>(GitGutterNextHunk)
nmap [h <Plug>(GitGutterPrevHunk)

let g:magit_show_magit_display = 'v'
let g:magit_default_show_all_files = 1
let g:magit_default_fold_level = 1
let g:magit_show_help = 1
let g:magit_refresh_gitgutter = 1

" ---------------- Plugin Config ----------------
let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']
let g:hugefile_trigger_size = 1

xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

if exists('*repeat#set')
  silent! call repeat#set("\<Plug>(repeat)")
endif

function! LLMode() abort
  return winwidth(0) < 60 ? '' : lightline#mode()[0]
endfunction

function! LLReadonly() abort
  return &readonly ? 'RO' : ''
endfunction

function! LLModified() abort
  return &modified ? '+' : ''
endfunction

function! LLFugitive() abort
  if exists('*FugitiveHead')
    let l:head = FugitiveHead()
    return empty(l:head) ? '' : 'git:' . l:head
  endif
  return ''
endfunction

function! LLFilename() abort
  let l:name = expand('%:t')
  return (empty(l:name) ? '[No Name]' : l:name)
        \ . (empty(LLReadonly()) ? '' : ' ' . LLReadonly())
        \ . (empty(LLModified()) ? '' : ' ' . LLModified())
endfunction

function! LLALE() abort
  return exists('*ale#statusline#Status') ? ale#statusline#Status() : ''
endfunction

let g:lightline = {
      \ 'colorscheme': 'apprentice',
      \ 'active': {
      \   'left': [
      \     [ 'mode', 'paste' ],
      \     [ 'fugitive', 'readonly', 'filename', 'modified' ],
      \   ],
      \   'right': [
      \     [ 'ale' ],
      \     [ 'lineinfo' ],
      \     [ 'filetype' ],
      \   ],
      \ },
      \ 'inactive': {
      \   'left': [['filename']],
      \   'right': [],
      \ },
      \ 'component_function': {
      \   'mode': 'LLMode',
      \   'fugitive': 'LLFugitive',
      \   'filename': 'LLFilename',
      \   'ale': 'LLALE',
      \ },
      \ 'subseparator': { 'left': '｜', 'right': '｜' },
      \ }

" ---------------- Local Overrides ----------------
if filereadable(expand('$DOTFILES_DIR/local/config/vim/vimrc'))
  source $DOTFILES_DIR/local/config/vim/vimrc
endif
