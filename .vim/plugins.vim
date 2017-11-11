set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" Keep vundle updated.
Plugin 'gmarik/Vundle.vim'
Plugin 'vim-airline/vim-airline'

" Code editing
Plugin 'Valloric/YouCompleteMe'
Plugin 'tpope/vim-fugitive'
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
