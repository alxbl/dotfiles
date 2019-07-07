" vim:foldmethod=marker:foldlevel=0
so ~/.config/nvim/plug.vim
call plug#begin('~/.config/nvim/plugged')
" Navigation {{{
Plug 'junegunn/fzf'                   " Fuzzy File Finding
Plug 'junegunn/fzf.vim'               " FZF common commands
Plug 'mileszs/ack.vim'                " For ag support
Plug 'scrooloose/nerdtree'            " Better than netrw
Plug 'christoomey/vim-tmux-navigator' " Seamless tmux+vim pane switching

let g:ackprg = 'ag --vimgrep --smart-case'
cnoreabbrev ag Ack
cnoreabbrev aG Ack
cnoreabbrev Ag Ack
cnoreabbrev AG Ack

let g:fzf_layout = { 'down': '~20%' }
" }}}
" Editing {{{
Plug 'editorconfig/editorconfig-vim'  " Respect .editorconfig when present
Plug 'tpope/vim-surround'             " Wrap in parenthesis
Plug 'tpope/vim-commentary'           " Toggle Comment Support
Plug 'tpope/vim-unimpaired'           " Additional navigation bindings
Plug 'Shougo/neosnippet'              " Snippet framework
Plug 'honza/vim-snippets'             " Snippet collection

let g:neosnippet#enable_snipmate_compatibility = 1
let g:neosnippet#snippets_directory = "~/.config/nvim/plugged/vim-snippets/snippets/"
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)
xmap <C-k>     <Plug>(neosnippet_expand_target)
" }}}
" Language support {{{
" https://github.com/autozimu/LanguageClient-neovim/blob/master/doc/LanguageClient.txt
" Completion
Plug 'ncm2/ncm2'                     " Neovim Completion Manager
Plug 'roxma/nvim-yarp'
" + Some sources
Plug 'ncm2/ncm2-bufword'
Plug 'ncm2/ncm2-tmux'
Plug 'ncm2/ncm2-path'

autocmd BufEnter * call ncm2#enable_for_buffer()
set completeopt=noinsert,menuone,noselect

Plug 'jparise/vim-graphql'           " GraphQL
Plug 'leafgarland/typescript-vim'    " TypeScript .ts files
Plug 'wavded/vim-stylus'             " Stylus .styl files
Plug 'tmhedberg/SimpylFold'          " Python Smart Folding
Plug 'rust-lang/rust.vim'            " The Rust programming language
Plug 'pangloss/vim-javascript'       " Enhanced Javascript support
Plug 'matcatc/vim-asciidoc-folding'  " AsciiDoc folds (TODO: Remove once it lands)

" LSP Client (while waiting for https://github.com/neovim/neovim/pull/6856)
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'Shougo/echodoc.vim'
" }}}
" Pretty colors {{{
Plug 'chriskempson/base16-vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'dracula/vim'
" }}}
" Documentation {{{
Plug 'tpope/vim-fugitive'
Plug 'jceb/vim-orgmode'
Plug 'vimwiki/vimwiki'

let g:vimwiki_list = [{'path': '~/Documents/Wiki', 'path_html': '~/Documents/Wiki/html'}]
let g:vimwiki_folding = 'syntax'
let g:vimwiki_table_auto_fmt = 1
" }}}
call plug#end()

