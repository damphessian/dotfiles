setlocal expandtab
setlocal shiftwidth=4
setlocal softtabstop=4
setlocal tabstop=4
setlocal textwidth=88
setlocal colorcolumn=+1
setlocal foldmethod=indent
setlocal commentstring=#\ %s

let b:ale_linters = ['ruff']
let b:ale_fixers = ['ruff_format', 'ruff', 'remove_trailing_lines', 'trim_whitespace']
