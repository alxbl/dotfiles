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

" Buffer Management
nnoremap <leader>o :bp<CR>
nnoremap <leader>i :bn<CR>
nnoremap <C-Tab> :bn<CR>
nnoremap <C-S-Tab> :bp<CR>
nnoremap <leader>q :bd<CR>

" Code folding
nnoremap <leader><space> za

" Ctrl-s is the only sin
nnoremap <C-s> <ESC>:w<CR>

" Quickly reload vim config.
nnoremap <leader>er :so $MYVIMRC<CR>
nnoremap <leader>ev :sp $MYVIMRC<CR>

" Language Semantics

" Functions that combine LSP with Ctrl-P for fuzzy matching on completions.

nnoremap <leader><tab> :normal gg=G<CR>
nnoremap <leader>d :LspDefinition<CR>
nnoremap <F2> :LspRename<CR>
nnoremap <F12> :LspDefinition<CR>
nnoremap <leader>r :LspReferences<CR>
nnoremap <leader>p :LspDocumentSymbol<CR>
nnoremap <C-p> :CtrlP<CR>
