" For rename to work properly.
set hidden
" Always show the error gutter to prevent seizures.
set signcolumn=yes
let g:lsp_signs_enabled = 1

" TODO: Is there a way to figure out python2/3?
if executable('pyls')
    " pip install python-language-server
    au User lsp_setup call lsp#register_server({
        \ 'name': 'pyls',
        \ 'cmd': {server_info->['pyls']},
        \ 'whitelist': ['python'],
        \ })
endif


if executable('typescript-language-server')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'typescript-language-server',
        \ 'cmd': {server_info->[&shell, &shellcmdflag, 'typescript-language-server --stdio']},
        \ 'root_uri':{server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'tsconfig.json'))},
        \ 'whitelist': ['typescript'],
        \ })
endif

if executable('rls')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'rls',
        \ 'cmd': {server_info->['rustup', 'run', 'nightly', 'rls']},
        \ 'whitelist': ['rust'],
        \ })
endif

" KEY BINDGS
nnoremap <leader>. :LspCodeAction<CR>
nnoremap <F12> :LspDefinition<CR>
nnoremap <leader>gd :LspDefinition<CR>
nnoremap <m-F> :LspDocumentFormat<CR>
vnoremap <m-F> :LspDocumentRangeFormat<CR>
nnoremap <F1> :LspHover<CR>
nnoremap <F8> :LspPreviousError<CR>
nnoremap <F9> :LspNextError<CR>
nnoremap <leader>gi :LspImplementation<CR>
nnoremap <C-F12>   :LspReferences<CR>
nnoremap <F2>      :LspRename<CR>
nnoremap <leader>r :LspRename<CR>

" :LspDocumentDiagnostics
" :LspDocumentSymbol
" :LspTypeDefinition
" :LspWorkspaceSymbol

" DEBUG
" let g:lsp_log_verbose = 1
" let g:lsp_log_file = expand('~/vim-lsp.log')
" let g:asyncomplete_log_file = expand('~/asyncomplete.log')
