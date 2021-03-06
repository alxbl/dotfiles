""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vim-wide global configurations / defaults.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set encoding=utf-8 " Use UTF-8 encoding
set nocompatible   " vi? Nah!
set nowrap         " Don't wrap lines
set modeline       " Listen to the mode-line if present
set noshowmode     " airline-bar shows it already
set showcmd        " Show the pending command at the bottom right
syntax on          " Enable syntax-highlight
filetype off       " Don't try to determine filetype based on content

set wildignore+=**/node_modules/*,node_modules/**,**/CMakeFiles/**,**/build/**

" Copy to x clipboard
set clipboard+=unnamedplus

" Show relative line numbers
set number
set relativenumber

" Show trailing whitespace and tabs
exec "set listchars=nbsp:_,trail:\uB7,tab:\uBB\uBB"
set list

" Remove trailing whitespace
autocmd BufWritePre * %s/\s\+$//e

" Default tab width is 4
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4

" Enable code folding
set foldmethod=syntax
set foldlevel=99
set foldcolumn=0

