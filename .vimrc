" / vimrc. / "
filetype off

set encoding=utf-8
set nocompatible
set t_Co=256
set modeline
set wildignore+=*/node_modules/*

syntax on
set number
set relativenumber

" Default tab width.
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4

" Display pesky trailing spaces and tabs.
exec "set listchars=nbsp:_,trail:\uB7,tab:\uBB\uBB"
set list

" Folding
set foldmethod=indent
set foldlevel=99

" -------
" PLUGINS (Move to plugins.vim)
" -------
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" Keep vundle updated.
Plugin 'gmarik/Vundle.vim'
Plugin 'vim-airline/vim-airline'

" Code editing
Plugin 'Valloric/YouCompleteMe'
Plugin 'tmhedberg/SimpylFold'
Plugin 'editorconfig/editorconfig-vim'
Plugin 'scrooloose/syntastic'
Plugin 'kien/ctrlp.vim'

" Python
Plugin 'vim-scripts/indentpython.vim'
Plugin 'nvie/vim-flake8'

" TypeScript
Plugin 'leafgarland/typescript-vim'

" Color Themes
Plugin 'chriskempson/base16-vim'
Plugin 'hzchirs/vim-material'
Plugin 'iKarith/tigrana'

call vundle#end()
filetype plugin indent on

" -----
" HOTKEYS
" -----
nnoremap ; :
nnoremap <C-h> <C-W><C-h>
nnoremap <C-j> <C-W><C-j>
nnoremap <C-k> <C-W><C-k>
nnoremap <C-l> <C-W><C-l>
nnoremap <space> za

augroup Python
    au!
    " au BufNewFile,BufRead *.py
    " \ set tabstop=4
    " \ set softtabstop=4
    " \ set shiftwidth=4
    " \ set textwidth=79
    " \ set expandtab
    " \ set autoindent
    " \ set fileformat=unix
    " au BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/
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

" Theme
colorscheme tigrana-256-dark
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
