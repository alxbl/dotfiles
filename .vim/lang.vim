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
    au BufNewFile,BufRead *.ts,*.js,*.html,*.css,*.ejs
                \ set tabstop=2 |
                \ set softtabstop=2 |
                \ set shiftwidth=2

    au BufNewFile,BufRead *.ejs set filetype=html
augroup END
" Python

" Clang
