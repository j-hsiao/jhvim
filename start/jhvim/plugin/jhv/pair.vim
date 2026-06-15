" complete single quotes
" backslash does NOT escape in bash, vim, sh
call jhv#pair#Add("'", "'", 'fbW', 'bash,vim,sh=W')
call jhv#pair#Add('"', '"', 'fbW')
call jhv#pair#Add('(', ')', 'fr')
call jhv#pair#Add('[', ']', 'f')
call jhv#pair#Add('{', '}', 'f')

inoremap <expr> <Plug>jhv_pair_remove_left; jhv#pair#RemoveLeft()
inoremap <expr> <Plug>jhv_pair_prep_remove; jhv#pair#PrepRemove()

ExtendMap before=1 keep=1 imap <BS> <Plug>jhv_pair_prep_remove;
ExtendMap imap <BS> <Plug>jhv_pair_remove_left;

ExtendMap before=1 keep=1 imap <C-W> <Plug>jhv_pair_prep_remove;
ExtendMap imap <C-W> <Plug>jhv_pair_remove_left;

ExtendMap before=1 keep=1 imap <C-U> <Plug>jhv_pair_prep_remove;
ExtendMap imap <C-U> <Plug>jhv_pair_remove_left;
