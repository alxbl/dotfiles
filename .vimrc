" https://realpython.com/blog/python/vim-and-python-a-match-made-in-heaven/
set encoding=utf-8
set nocompatible
set t_Co=256
syntax on
set number
set relativenumber
filetype off

set foldmethod=indent
set foldlevel=99

" -------
" PLUGINS
" -------
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" Keep vundle updated.
Plugin 'gmarik/Vundle.vim'
Plugin 'vim-airline/vim-airline'

" Code editing
Plugin 'Valloric/YouCompleteMe'
Plugin 'tmhedberg/SimpylFold'
Plugin 'scrooloose/syntastic'
Plugin 'kien/ctrlp.vim'

" Python
Plugin 'vim-scripts/indentpython.vim'
Plugin 'nvie/vim-flake8'

" Color Themes
Plugin 'hzchirs/vim-material'
Plugin 'iKarith/tigrana'

call vundle#end()
filetype plugin indent on
" -----
" HOTKEYS
" -----
nnoremap <C-h> <C-W><C-h>
nnoremap <C-j> <C-W><C-j>
nnoremap <C-k> <C-W><C-k>
nnoremap <C-l> <C-W><C-l>
nnoremap <space> za

" Python
" au BufNewFile,BufRead *.py
    " \ set tabstop=4
    " \ set softtabstop=4
    " \ set shiftwidth=4
    " \ set textwidth=79
    " \ set expandtab
    " \ set autoindent
    " \ set fileformat=unix
" au BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/
let python_highlight_all=1

" HTML/JS/CSS/TS
au BufNewFile,BufRead *.ts, *.js, *.html, *.css
    \ set tabstop=2
    \ set softtabstop=2
    \ set shiftwidth=2

" Auto-completion
let g:ycm_server_python_interpreter='/usr/bin/python2'
let g:ycm_autoclose_preview_window_after_completion=1
map g<space> :YcmCompleter GoToDefinitionElseDeclaration<CR>

" Theme
colorscheme tigrana-256-dark
let g:airline_powerline_fonts = 1
