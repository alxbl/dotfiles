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
nnoremap <leader><tab> :normal gg=G<CR><C-o><C-o>

nnoremap <F2> :LspRename<CR>
" }}}


" Advanced Macros {{{

" <N>gco: Go to Nth character of the file.
function! s:GoToCharacter( count )
    let l:save_view = winsaveview()
    " We need to include the newline position in the searches, too. The
    " newline is a character, too, and should be counted.
    let l:save_virtualedit = &virtualedit
    try
        let [l:fixPointMotion, l:searchExpr, l:searchFlags] = ['gg0', '\%#\_.\{' . (a:count + 1) . '}', 'ceW']
        silent! execute 'normal!' l:fixPointMotion

        if search(l:searchExpr, l:searchFlags) == 0
            " We couldn't reach the final destination.
            execute "normal! \<C-\>\<C-n>\<Esc>" | " Beep.
            call winrestview(l:save_view)
            return 0
        else
            return 1
        endif
    finally
        let &virtualedit = l:save_virtualedit
    endtry
endfunction
" We start at the beginning, on character number 1.
nnoremap <silent> gco :<C-u>if ! <SID>GoToCharacter(v:count1 - 1)<Bar>echoerr 'No such position'<Bar>endif<Bar><CR>
" }}}
