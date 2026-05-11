setlocal expandtab
setlocal shiftwidth=2
setlocal softtabstop=2
setlocal tabstop=2
setlocal conceallevel=0
setlocal foldmethod=indent

let b:ale_linters = ['jq']
let b:ale_fixers = ['jq', 'prettier', 'remove_trailing_lines', 'trim_whitespace']

let g:jsonpath_register = '*'

nnoremap <buffer> <silent> <leader>d :call jsonpath#echo()<CR>
nnoremap <buffer> <silent> <leader>j :call jsonpath#goto()<CR>
