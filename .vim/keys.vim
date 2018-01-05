" vim:foldmethod=marker

" Space as leader key
nmap <space> <Nop>
let mapleader = "\<space>"

nnoremap ; :Buffers<CR>
nnoremap <C-p> :FZF<CR>
nnoremap <C-b> :NERDTreeToggle<CR>
nnoremap <leader>f :Ack!<Space>

" Tab completion while typing
inoremap <tab> <C-n>
inoremap <S-tab> <C-p>

" No-frill pane switching
" Be tmux aware.
nnoremap <M-h> :TmuxNavigateLeft<CR>
nnoremap <M-j> :TmuxNavigateDown<CR>
nnoremap <M-k> :TmuxNavigateUp<CR>
nnoremap <M-l> :TmuxNavigateRight<CR>

" Quick aliases for surround.vim
nmap <leader>8 ysiW
nmap <leader>( ysiw

" Buffer Management
nnoremap <leader>o :bp<CR>
nnoremap <leader>i :bn<CR>
nnoremap <C-Tab> :bn<CR>
nnoremap <C-S-Tab> :bp<CR>
nnoremap <leader>q :bd<CR>
nnoremap <leader>Q :bufdo bd<CR>

" Code foldin
nnoremap <leader><space> za

" Ctrl-s is the only sin
nnoremap <C-s> <ESC>:w<CR>

" Quickly reload vim config.
nnoremap <leader>er :so $MYVIMRC<CR>
nnoremap <leader>ev :vs $MYVIMRC<CR>

" Language Semantics
nnoremap <leader><tab> :normal gg=G<CR>
nnoremap <leader>d :LspDefinition<CR>
nnoremap <F2> :LspRename<CR>
nnoremap <F12> :LspDefinition<CR>
nnoremap <leader>r :LspReferences<CR>
nnoremap <leader>p :LspDocumentSymbol<CR>
