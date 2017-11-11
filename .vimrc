" / vimrc. / "

"""""""""""""""""""""""""""""""
" Core Settings
"""""""""""""""""""""""""""""""
so ~/.vim/global.vim
so ~/.vim/plugins.vim
so ~/.vim/keys.vim
so ~/.vim/theme.vim

set wildignore+=**/node_modules/*

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

" Auto-completion
let g:ycm_server_python_interpreter='/usr/bin/python2'
let g:ycm_autoclose_preview_window_after_completion=1
map g<space> :YcmCompleter GoToDefinitionElseDeclaration<CR>

