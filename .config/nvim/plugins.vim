so ~/.config/nvim/plug.vim
call plug#begin('~/.config/nvim/plugged')

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'tpope/vim-fugitive'
Plug 'tmhedberg/SimpylFold'
Plug 'editorconfig/editorconfig-vim'
Plug 'scrooloose/syntastic'
Plug 'junegunn/fzf'
let g:fzf_layout = { 'down': '~20%' }

" Language support.
" https://github.com/autozimu/LanguageClient-neovim/blob/master/doc/LanguageClient.txt
Plug 'autozimu/LanguageClient-neovim', { 'do': ':UpdateRemotePlugins' }
Plug 'roxma/nvim-completion-manager'
Plug 'Shougo/echodoc.vim'
Plug 'leafgarland/typescript-vim'

" Pretty colors.
Plug 'chriskempson/base16-vim'
Plug 'iKarith/tigrana'

call plug#end()

