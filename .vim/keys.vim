" vim:foldmethod=marker

" Basic Mappings {{{
nmap <space> <Nop>
let mapleader = "\<space>"

" Quick Access to vimrc.
nnoremap <leader>er :so $MYVIMRC<CR>
nnoremap <leader>ev :vs $MYVIMRC<CR>
" }}}

" Navigation {{{
nnoremap ; :Buffers<CR>
nnoremap <C-p> :FZF<CR>
nnoremap <C-b> :NERDTreeToggle<CR>
nnoremap <leader>f :Ack!<Space>

" Language Server Protocol
nnoremap <leader>d :LspDefinition<CR>
nnoremap <F12> :LspDefinition<CR>
nnoremap <leader>r :LspReferences<CR>
nnoremap <leader>p :LspDocumentSymbol<CR>

" No-frill pane switching (tmux aware)
nnoremap <M-h> :TmuxNavigateLeft<CR>
nnoremap <M-j> :TmuxNavigateDown<CR>
nnoremap <M-k> :TmuxNavigateUp<CR>
nnoremap <M-l> :TmuxNavigateRight<CR>

" Buffer Management
nnoremap <leader>q :bd<CR>
nnoremap <leader>Q :bufdo bd<CR>
" }}}

" Code Editing {{{
" Tab completion while typing
inoremap <tab> <C-n>
inoremap <S-tab> <C-p>

" Quick aliases for surround.vim
nmap <leader>8 ysiW
nmap <leader>( ysiw

" Ctrl-s is the only sin
nnoremap <C-s> <ESC>:w<CR>
inoremap <C-s> <ESC>:w<CR>a

" Format File
nnoremap <leader><tab> :normal gg=G<CR>

nnoremap <F2> :LspRename<CR>
" }}}
