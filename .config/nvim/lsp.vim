" For rename to work properly.
set hidden
" Always show the error gutter to prevent seizures.
set signcolumn=yes

" Register language servers here
" \ 'javascript': [ 'javascript-typescript-stdio' ],
let g:LanguageClient_serverCommands = {
            \ 'typescript': [ 'typescript-language-server', '--stdio' ],
            \ 'python': [ 'pyls' ]
            \ }

let g:LanguageClient_autoStart = 1
" Language Server specific bindings
nnoremap <leader>d :call LanguageClient_textDocument_definition()<CR>
nnoremap <F1> :call LanguageClient_textDocument_hover()<CR>
nnoremap <F2> :call LanguageClient_textDocument_rename()<CR>
nnoremap <F12> :call LanguageClient_textDocument_definition()<CR>
nnoremap <S-F12> :call LanguageClient_textDocument_references()<CR>
nnoremap <F3> :call LanguageClient_textDocument_codeAction()<CR>

nnoremap <leader>gr :call LanguageClient_textDocument_references()<CR>
nnoremap <leader>gs :call LanguageClient_textDocument_documentSymbols()<CR>
