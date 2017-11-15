set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" Keep vundle updated.
Plugin 'gmarik/Vundle.vim'
Plugin 'vim-airline/vim-airline'

" Code editing
Plugin 'tpope/vim-fugitive'
Plugin 'tmhedberg/SimpylFold'
Plugin 'editorconfig/editorconfig-vim'
Plugin 'scrooloose/syntastic'
Plugin 'ctrlpvim/ctrlp.vim'

" Language Server Support
Plugin 'prabirshrestha/async.vim'
Plugin 'prabirshrestha/asynccomplete.vim'
Plugin 'prabirshrestha/asynccomplete-lsp.vim'
Plugin 'prabirshrestha/vim-lsp'

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
