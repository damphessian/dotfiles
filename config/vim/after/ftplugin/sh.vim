setlocal expandtab
setlocal shiftwidth=2
setlocal softtabstop=2
setlocal tabstop=2
setlocal foldmethod=indent
setlocal commentstring=#\ %s

let b:ale_linters = ['shellcheck']
let b:ale_fixers = ['shfmt', 'remove_trailing_lines', 'trim_whitespace']
let b:ale_sh_shfmt_options = '-i 2 -ci'
