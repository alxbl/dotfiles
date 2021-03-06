" vim:foldmethod=marker:
" Python Specific {{{
augroup Python
    au!
    au BufNewFile,BufRead *.py
                \ set tabstop=4 |
                \ set softtabstop=4 |
                \ set shiftwidth=4 |
                \ set expandtab |
                \ set autoindent |
                \ set fileformat=unix
augroup END
let python_highlight_all=1
" }}}
" Ruby {{{
augroup Ruby
    au!
    au BufNewFile,BufRead *.rb
                \ set tabstop=2 |
                \ set softtabstop=2 |
                \ set shiftwidth=2 |
                \ set expandtab |
                \ set autoindent |
                \ set fileformat=unix
augroup END
" }}}
" HTML/JS/CSS/TS {{{
augroup Web
    au!
    au BufNewFile,BufRead *.ts,*.js,*.html,*.css,*.ejs,*.htm
                \ set tabstop=2 |
                \ set softtabstop=2 |
                \ set shiftwidth=2 |
                \ set foldmethod=syntax

    au BufNewFile,BufRead *.ejs set filetype=html
augroup END
" }}}
" C/C++ {{{
augroup C
    au!
    au BufNewFile,BufRead *.cpp,*.h
        \ set filetype=cpp.doxygen
augroup END
" }}}
" vimWiki {{{
augroup VimWiki
    au!
    au BufNewFile,BufRead *.wiki
        \ set textwidth=80 |
        \ set foldlevel=0

augroup END
" }}}
" YAML {{{
augroup Yaml
    au!
    au BufNewFile,BufRead *.yaml,*.yml
                \ set tabstop=2 |
                \ set softtabstop=2 |
                \ set shiftwidth=2
augroup END
" }}}
" Lua {{{
augroup Lua
    au!
    au BufNewFile,BufRead *.lua
                \ set foldmethod=indent
augroup END
" }}}
" Markdown {{{
augroup C
    au!
    au BufNewFile,BufRead *.md
        \ set tw=80
augroup END
" }}}
