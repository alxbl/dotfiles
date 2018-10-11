" vim:foldmethod=marker:sw=2
"       .__
" ___  _|__| ____________  ____
" \  \/ |  |/     \_  __ _/ ___\
"  \   /|  |  Y Y  |  | \\  \___
"   \_/ |__|__|_|  |__|   \___  >
"                \/           \/
"
"  / Neo wasn't expecting this /
"

"
" Reminder: `gf` is your friend.
"

" Share some vanilla settings with vim
so ~/.vim/global.vim

" Plugin manifest
so ~/.config/nvim/plugins.vim

so ~/.vim/keys.vim

" Language Server Targets
so ~/.config/nvim/lsp.vim

" Language Specific Settings
so ~/.vim/lang.vim

" Set theme last to ensure everything gets styled.
so ~/.vim/theme.vim

