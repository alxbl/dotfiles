""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vim-wide global configurations / defaults.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set encoding=utf-8 " Use UTF-8 encoding
set nocompatible   " vi? Nah!
set modeline       " Listen to the mode-line if present
syntax on          " Enable syntax-highlight
filetype off       " Don't try to determine filetype based on content

set wildignore+=**/node_modules/*,node_modules/**
"
" Copy to x clipboard
set clipboard=unnamed

" Show relative line numbers
set number
set relativenumber

" Show trailing whitespace and tabs
exec "set listchars=nbsp:_,trail:\uB7,tab:\uBB\uBB"
set list

" Default tab width is 4
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4

" Enable code folding
set foldmethod=indent
set foldlevel=99


" Show the current active command
set showcmd
