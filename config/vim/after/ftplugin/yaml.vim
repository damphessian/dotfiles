setlocal expandtab
setlocal shiftwidth=2
setlocal softtabstop=2
setlocal tabstop=2
setlocal foldmethod=indent
setlocal commentstring=#\ %s

let b:ale_linters = ['yamllint']
let b:ale_fixers = ['prettier', 'remove_trailing_lines', 'trim_whitespace']
