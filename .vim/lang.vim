" Python Specific
augroup Python
    au!
    au BufNewFile,BufRead *.py
                \ set tabstop=4 |
                \ set softtabstop=4 |
                \ set shiftwidth=4 |
                \ set textwidth=79 |
                \ set expandtab |
                \ set autoindent |
                \ set fileformat=unix
augroup END

let python_highlight_all=1

" HTML/JS/CSS/TS
augroup Web
    au!
    au BufNewFile,BufRead *.ts,*.js,*.html,*.css
                \ set tabstop=2 |
                \ set softtabstop=2 |
                \ set shiftwidth=2
augroup END

" Set to 1 to troubleshoot vim-lsp
let g:lsp_log_verbose = 0
let g:lsp_log_file = expand('~/.vim/lsp.log')

" TypeScript
if executable('typescript-language-server')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'typescript-language-server',
        \ 'cmd': {server_info->[&shell, &shellcmdflag, 'typescript-language-server --stdio']},
        \ 'root_uri':{server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'tsconfig.json'))},
        \ 'whitelist': ['typescript'],
        \ })
endif

" Python

" Clang
