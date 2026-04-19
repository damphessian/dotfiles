set nocompatible

syntax on
filetype plugin indent on
scriptencoding utf-8
set fileencodings=utf-8
set encoding=utf-8

function! RunningAsRoot()
  return $EUID ==# '0' || exists('$SUDO_USER')
endfunction

" Suppress 'Pattern not found' messages
set shortmess+=c

" add xdg, fzf paths to rtp
set runtimepath+=$XDG_CONFIG_HOME/vim,$XDG_CONFIG_HOME/vim/after
set runtimepath+=$XDG_DATA_HOME/fzf
set runtimepath+=$VIM,$VIMRUNTIME

runtime xdg.vim

set viminfofile=~/.dotfiles/cache/vim/viminfo

"--------------------------------------------------------------
" Load Plugins
"--------------------------------------------------------------
call plug#begin('$XDG_DATA_HOME/vim/plugged')
source $XDG_CONFIG_HOME/vim/plugins.vim
call plug#end()

"--------------------------------------------------------------
" netrw
"--------------------------------------------------------------
let g:netrw_liststyle = 4   " 4 lightweight, 3 tree
let g:netrw_preview   = 1   " open previews in vertical split (p)
let g:netrw_winsize   = 70  " give previewed windows 70% of screen width
let g:netrw_banner    = 0


"-------------------------------------------------------------
" Restore position
"-------------------------------------------------------------
augroup vimrcEx
  autocmd!

  " When editing a file, always jump to the last known cursor position.
  " Don't do it for commit messages, when the position is invalid, or when
  " inside an event handler (happens when dropping a file on gvim).
  autocmd BufReadPost *
        \ if &ft != 'gitcommit' && line("'\"") > 0 && line("'\"") <= line("$") |
        \   exe "normal g`\"" |
        \ endif

  " automatically re-balance the visible splits as tmux panes are created,
  " destroyed, or resized or window resized
  autocmd VimResized * :wincmd =
augroup END


"-------------------------------------------------------------
" Colors
"-------------------------------------------------------------
" Base vim settings
set t_Co=256  " 256 color terminal

" Allow italic text in vim
set t_ZH=[3m
set t_ZR=[23m

if has('termguicolors')
  set termguicolors
endif

function! SetBackgroundFromSystem() abort
  if !has('macunix')
    return
  endif

  let l:mode = system("defaults read -g AppleInterfaceStyle 2>/dev/null")
  let l:is_dark_system = (v:shell_error == 0 && l:mode =~? 'Dark')
  let l:is_visor = exists('$ITERM_PROFILE') && $ITERM_PROFILE ==# 'Visor' || exists('$GHOSTTY_QUICK_TERMINAL')

  if l:is_dark_system || l:is_visor
    set background=dark
  else
    set background=light
  endif
endfunction

call SetBackgroundFromSystem()
colorscheme spacemacs

" Color scheme settings
if has('gui_running')
  set vb                    " no audible bell
  set guioptions-=T         " no toolbar
  set guioptions+=c         " use console dialogs
  set transparency=1        " enable transparency
  set lines=50 columns=80   " size of window
  set guifont=JuliaMono:h16
  colorscheme spacemacs
endif

"--------------------------------------------------------------
" Line numbering
"--------------------------------------------------------------
set numberwidth=1
set relativenumber
set number

"--------------------------------------------------------------
" Folding
"--------------------------------------------------------------
" Enable folding based on indentation (faster than syntax)
set foldmethod=syntax

" Initial fold only 1 level deep
set foldlevelstart=1

" Custom folding function
if has('folding')
  set foldtext=MyFoldText()

  function! MyFoldText()
    if v:version < 701
      return foldtext()
    endif

    " clear fold from fillchars to set it up the way we want later
    let &l:fillchars = substitute(&l:fillchars,',\?fold:.','','gi')
    let l:numwidth = (v:version < 701 ? 8 : &numberwidth)

    if b:foldpat == 1
      let l:align = winwidth(0)-&foldcolumn-(&nu ? Max(strlen(line('$'))+1, l:numwidth) : 0)
      let l:foldtext = ' '.v:folddashes
      let l:linetext = substitute(getline(v:foldstart),'\s\+$','','')
      let l:linetext .= ' ---'.(v:foldend-v:foldstart-1).' lines--- '
      let l:linetext .= substitute(getline(v:foldend),'^\s\+','','')
      let l:linetext = strpart(l:linetext,0,l:align-strlen(l:foldtext))
      let l:align -= strlen(l:linetext)
      setlocal fillchars+=fold:-
      return printf('%s%*s', l:linetext, l:align, l:foldtext)
    endif

    if &fdm == 'diff'
      let l:foldtext = ' '.(v:foldend-v:foldstart).' lines the same -------'.v:folddashes.'|'
    elseif !exists('b:foldpat') || b:foldpat==0
      let l:foldtext = ' '.(v:foldend-v:foldstart).' lines '.v:folddashes.'|'
    endif

    let l:endofline = (&textwidth>0 ? &textwidth : 80)
    let l:linetext = strpart(getline(v:foldstart),0,l:endofline-strlen(l:foldtext))
    let l:align = l:endofline-strlen(l:linetext)
    return printf('%s%*s', l:linetext, l:align, l:foldtext)
  endfunction
endif


"--------------------------------------------------------------
" Navigation / Window Management
"--------------------------------------------------------------
" Open new split panes to right and bottom
set splitbelow
set splitright

" --- window resizing ---
nnoremap <Left>  <C-w><
nnoremap <Right> <C-w>>
nnoremap <Down>  <C-w>+
nnoremap <Up>    <C-w>-

" --- buffer navigation ---
" C-e: Scroll window up by 5 lines
nnoremap <C-e> 5<C-e>

" C-y: Scroll window down by 5 lines
nnoremap <C-y> 5<C-y>

" --- tab navigation ---
" S-h: previous tab
nnoremap <S-h> gT

" S-l: next tab
nnoremap <S-l> gt


"--------------------------------------------------------------
" General Settings
"--------------------------------------------------------------
let g:mapleader = ' ' " use space as leader key

set history=50    " 50 items in command history
set ruler         " show the cursor position all the time
set showcmd       " display incomplete commands
set laststatus=2  " Always display the status line
set autowrite     " Automatically :write before running commands
set lazyredraw    " Redraw for typed actions, not when executing macros
set ttyfast       " This is a fast terminal
set noshowmode    " don't show the current mode in the message bar
set autowrite     " Automatically :write before running commands

" Backup policy
set backup        " keep backup files
set backupskip=/tmp/*,/private/tmp/*
set writebackup

" Backspace behavior
set backspace=indent,start,eol

" Searching
set incsearch     " do incremental searching
set hlsearch      " highlight search matches by default
set ignorecase    " case insensitive pattern matching
set smartcase     " overrides ignorecase if pattern contains upcased chars
let @/ = ''       " clear the search register
:nohlsearch       " clear any previously highlighted search matches

" Use Rg for grepping
" set grepprg=ag\ --numbers\ --column\ --nocolor\ --noheading\ --nogroup\ --nobreak\ --case
set grepprg=rg\ --column\ --no-heading
set grepformat=%f:%l:%c:%m

" Indentation with soft tabs, 2 spaces
set expandtab      " use soft tabs
set shiftwidth=2   " spaces per tab (when shifting)
set softtabstop=2  " 2-space soft tabs
set shiftround     " always indent by multiple of shiftwidth

" Call out extra whitespace
set list listchars=tab:»·,trail:·,nbsp:·

" Command mode autocompletion settings
set wildmode=list:longest,list:full

" Make message bar taller to avoid 'press enter' prompt
set cmdheight=2

" Use all abbreviations in shortmessage
set shortmess+=a

" don't give the intro message when starting Vim
set shortmess+=I

" Window size shifts on focus, current screen stays larger
set winwidth=84
set winheight=5
set winminheight=5
set winheight=999

" preview window height
set previewheight=15

" Make it obvious where 80 characters is
set colorcolumn=+0

" keep context lines you would like to see above and below the cursor
set scrolloff=10

" Always use vertical diffs
set diffopt+=vertical

" set esckeys  " will break any sequences using escape in insert mode
set timeoutlen=500 ttimeoutlen=10

" Preserve words when breaking lines
set linebreak

"--------------------------------------------------------------
" Convenience Bindings
"--------------------------------------------------------------
" <CR>: turn off highlighting by pressing enter
nnoremap <silent><CR> :noh<CR><CR>

" \: (backward slash) to grep-with-ag-to-quickfix shortcut
command! -nargs=+ -complete=file -bar Rg silent! grep! <args>|cwindow|redraw!
nnoremap <leader>sp :Rg ''<LEFT>

" K: Grep for the word under the cursor or visual selection,
"    open results in quickfix pane
nnoremap <silent><S-k> yiw:grep! "<C-R>0"<CR>:cw<CR>
vnoremap <silent><S-k> y:grep! "<C-R>0"<CR>:cw<CR>
nnoremap <leader>* yiw:grep! "<C-R>0"<CR>:cw<CR>

" -------------- Leader key mappings (ctrl) -----------------
" C-]: Open ctag in a vertical split
map <silent><leader><C-]> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>

" ]: Open ctag in a horizontal split
map <silent><leader>] :sp <CR>:exec("tag ".expand("<cword>"))<CR>

" tl: toggle line wrapping
function! ToggleLineWrap()
  if &wrap
    setlocal nowrap
  else
    setlocal wrap
  endif
endfunction

nnoremap <silent><leader>tw :call ToggleLineWrap()<cr>


"--------------------------------------------------------------
" Leader key mappings
"--------------------------------------------------------------
" -: zoom the current vim pane
nnoremap <leader>- :wincmd _<CR>:wincmd \|<CR>

" =: re-balance vim pane sizes
nnoremap <leader>= :wincmd =<CR>

" ff: Invoke fzf
nnoremap <silent><leader>ff :FZF<CR>
nnoremap <silent><leader>pf :FZF<CR>

" fs: save buffer
nnoremap <silent><leader>fs :StripWhitespace<CR>:w<CR>

" g: Git
nnoremap <leader>g :Git<SPACE>

" R: From visual mode, leader+R populates command line for search and replace
vnoremap <leader>R y:%s/<C-R>"//g<LEFT><LEFT>

" R: From normal mode, redraws
nnoremap <leader>R :redraw!<CR>

" wv: open vertical split
nnoremap <leader>wv <C-w>v

" ws: open split
nnoremap <leader>ws <C-w>s

" wh: navigate pane left
nnoremap <leader>wh <C-w>h

" wj: navigate pane down
nnoremap <leader>wj <C-w>j

" wk: navigate pane up
nnoremap <leader>wk <C-w>k

" wl: navigate pane right
nnoremap <leader>wl <C-w>l

" wd: close window
nnoremap <leader>wd :quit<CR>
nnoremap <leader>wD :quit!<CR>
nnoremap <C-c><C-c> :x<CR>
nnoremap <C-c><C-k> :q!<CR>

" bd: kill buffer
nnoremap <leader>bd :bdelete<CR>
nnoremap <leader>bD :bdelete!<CR>

" c: copy visual selection to system clipboard
vnoremap <leader>c "+y

" x: cut visual selection to system clipboard
vnoremap <leader>x "+d

" v: paste from system clipboard
nnoremap <leader>v :set paste<CR>i<ESC>"+p:set nopaste<CR>
vnoremap <leader>v d:set paste<CR>i<ESC>"+p:set nopaste<CR>


"--------------------------------------------------------------
" Buffer-select utility commands
"--------------------------------------------------------------
function! s:buflist()
  redir => ls
  silent ls
  redir END
  return split(ls, '\n')
endfunction

function! s:bufopen(e)
  execute 'buffer' matchstr(a:e, '^[ 0-9]*')
endfunction

" fuzzy-select from buffer list
nnoremap <silent> <leader>bb :call fzf#run({
      \   'source':  reverse(<sid>buflist()),
      \   'sink':    function('<sid>bufopen'),
      \   'options': '+m',
      \   'down':    len(<sid>buflist()) + 2
      \ })<CR>


"--------------------------------------------------------------
" Plugins
"--------------------------------------------------------------
" JSON
autocmd FileType json setlocal foldmethod=indent

" JSON fold
let g:jsonpath_register = '*'

" Mappings only in JSON buffers
augroup JsonNav
  autocmd!
  " Echo/visualize path to cursor
  autocmd FileType json noremap <buffer> <silent> <leader>d :call jsonpath#echo()<CR>
  " Go to a path you type (e.g., my.object[0].value)
  autocmd FileType json noremap <buffer> <silent> <leader>g :call jsonpath#goto()<CR>
augroup END

" Rainbow parentheses
augroup rainbow_parentheses
  autocmd!

  autocmd VimEnter * RainbowParenthesesToggle
  autocmd Syntax * RainbowParenthesesLoadRound
  autocmd Syntax * RainbowParenthesesLoadSquare
  autocmd Syntax * RainbowParenthesesLoadBraces
augroup END

" AutoPairs: disable closed-pair jumping instead of inserting
let g:AutoPairsFlyMode = 0
let g:AutoPairsShortcutBackInsert = '<C-b>'

function! IsEmptyPair(str)
  for pair in split(&matchpairs, ',') + [ "''", '""', '``' ]
    if a:str == join(split(pair, ':'),'')
      return 1
    endif
  endfor

  return 0
endfunc

function! SkipDelim(char)
  let cur = strpart(getline('.'), col('.')-2, 3)

  if cur[0] == "\\"
    return a:char
  elseif cur[1] == a:char
    return "\<Right>"
  elseif cur[1] == ' ' && cur[2] == a:char
    return "\<Right>\<Right>"
  elseif IsEmptyPair(cur[0] . a:char)
    return a:char . "\<Left>"
  else
    return a:char
  endif
endfunc

inoremap <expr> ) SkipDelim(')')
inoremap <expr> ] SkipDelim(']')
inoremap <expr> } SkipDelim('}')
inoremap <expr> ' SkipDelim("'")
inoremap <expr> " SkipDelim('"')
inoremap <expr> ` SkipDelim('`')

" Use bars for indents
let g:indentLine_char = '│'

" Disable indent guides by default
let g:indentLine_enabled = 0

let g:used_javascript_libs = 'jquery,underscore,react,flux,requirejs'

let g:lightline = {
\   'colorscheme': 'solarized',
\   'active': {
\     'left': [
\       [ 'mode', 'paste' ],
\       [ 'fugitive', 'filename' ]
\     ],
\     'right': [
\       [ 'syntastic', 'lineinfo' ],
\       [ 'percent' ],
\       [ 'fileformat', 'fileencoding', 'filetype' ]
\     ]
\   },
\   'component_function': {
\     'mode':         'LLMode',
\     'fugitive':     'LLFugitive',
\     'filename':     'LLFilename',
\     'readonly':     'LLReadonly',
\     'modified':     'LLModified',
\     'fileformat':   'LLFileFormat',
\     'fileencoding': 'LLFileEncoding',
\     'filetype':     'LLFileType'
\   },
\   'component_expand': {
\     'syntastic': 'SyntasticStatuslineFlag'
\   },
\   'component_type': {
\     'syntastic': 'error'
\   },
\   'subseparator': {
\     'left': '|', 'right': '|'
\   }
\ }

function! LLMode()
  let fname = expand('%:t')
  return  fname == '__Gundo__'  ? 'Gundo'  :
        \ fname == '__Gundo_Preview__' ? 'Gundo Preview' :
        \ winwidth(0) < 60 ? '' :
        \ lightline#mode() == 'NORMAL'  ? 'N'  :
        \ lightline#mode() == 'INSERT'  ? 'I'  :
        \ lightline#mode() == 'VISUAL'  ? 'V'  :
        \ lightline#mode() == 'V-LINE'  ? 'VL' :
        \ lightline#mode() == 'V-BLOCK' ? 'VB' :
        \ lightline#mode() == 'REPLACE' ? 'R'  : lightline#mode()
endfunction

function! LLModified()
  return &modified ? '+' : ''
endfunction

function! LLReadonly()
  return &readonly ? '' : ''
endfunction

function! LLFugitive()
  if !exists('*FugitiveHead')
    return ''
  endif

  let head = FugitiveHead()
  return strlen(head) ? ' ' .head : ''
endfunction

function! LLFilename()
  let fname = expand('%:t')
  return  fname == '__Tagbar__' ? g:lightline.fname :
        \ fname == '__Scratch__' ? 'Scratch' :
        \ fname =~ '__Gundo\|NERD_tree' ? '' :
        \ &ft == 'vimfiler' ? vimfiler#get_status_string() :
        \ &ft == 'unite'    ? unite#get_status_string() :
        \ &ft == 'vimshell' ? vimshell#get_status_string() :
        \ ('' != LLReadonly() ? LLReadonly() . ' ' : '') .
        \ ('' != fname ? fname : '[No Name]') .
        \ ('' != LLModified() ? ' ' . LLModified() : '')
endfunction

function! LLFileEncoding()
  return winwidth(0) > 70 ? (strlen(&fenc) ? &fenc : &enc) : ''
endfunction

function! LLFileFormat()
  return winwidth(0) > 70 ? &fileformat : ''
endfunction

function! LLFileType()
  return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype : 'file') : ''
endfunction

let g:better_whitespace_filetypes_blacklist=['qf']

" HugeFile: disable options for large files (>= 1MB)
let g:hugefile_trigger_size = 1

" EasyAlign: Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)

" EasyAlign: Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

" VimFugitive: Show git status
nnoremap <silent> <leader>gs :Gstatus<CR>:50wincmd_<CR>

" FZF: Customize fzf colors to match your color scheme
" - fzf#wrap translates this to a set of `--color` options
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


" ---------------- Overrides  --------------------------
if filereadable(expand('$DOTFILES_DIR/local/config/vim/vimrc'))
  source $DOTFILES_DIR/local/config/vim/vimrc
endif
