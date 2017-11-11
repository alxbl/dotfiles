" Space as leader key
nmap <space> <Nop>
let mapleader = "\<space>"

" ; is also good for ex-mode
nnoremap ; :

" No-frill pane switching
nnoremap <C-h> <C-W><C-h>
nnoremap <C-j> <C-W><C-j>
nnoremap <C-k> <C-W><C-k>
nnoremap <C-l> <C-W><C-l>
" No frill buffer switching
nnoremap gp :bp<CR>
nnoremap gn :bn<CR>

" Space + Space to toggle folding.
nnoremap <Leader><space> za

" Ctrl-s is the only sin
nnoremap <C-s> <ESC>:w<CR>

" Quickly reload vim config.
nnoremap <leader>R :so ~/.vimrc<CR>
